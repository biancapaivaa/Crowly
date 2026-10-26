-- Crowly: perfis admin/funcionario, com operacao compartilhada por equipe.
-- Requer as migracoes anteriores. Execute uma vez, sem apagar tabelas/dados.
begin;
create table public.crowly_members (
  id uuid primary key references auth.users(id) on delete cascade,
  workspace_id uuid not null references auth.users(id) on delete cascade,
  role text not null check(role in ('admin','staff')),
  full_name text not null check(length(btrim(full_name)) between 1 and 100),
  email text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  check((role='admin' and workspace_id=id) or (role='staff' and workspace_id<>id))
);
create index crowly_members_workspace_idx on public.crowly_members(workspace_id);
alter table public.crowly_members enable row level security;
revoke all on public.crowly_members from public,anon,authenticated;
grant select on public.crowly_members to authenticated;
grant all on public.crowly_members to service_role;

create function public.crowly_workspace() returns uuid
language sql stable security definer set search_path='' as $$
  select m.workspace_id from public.crowly_members m
  join public.crowly_members a on a.id=m.workspace_id
  where m.id=auth.uid() and m.enabled and a.enabled and a.role='admin';
$$;
create function public.crowly_is_admin() returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.crowly_members where id=auth.uid() and role='admin' and enabled);
$$;
revoke all on function public.crowly_workspace(),public.crowly_is_admin() from public,anon;
grant execute on function public.crowly_workspace(),public.crowly_is_admin() to authenticated;
create policy members_read on public.crowly_members for select to authenticated
  using(id=auth.uid() or (workspace_id=public.crowly_workspace() and public.crowly_is_admin()));

-- Sem permissao de escrever no proprio perfil de autorizacao.
-- Dados pessoais continuam nos user_metadata; nunca sao usados como papel de acesso.
-- Cadastro Auth publico bloqueado tambem pelo banco, mesmo se o painel permitir signup.
-- app_metadata so pode ser definido por operacoes administrativas do Auth.
create function public.crowly_check_registration() returns trigger
language plpgsql security definer set search_path='' as $$
declare parent uuid;
begin
  begin parent:=(new.raw_app_meta_data->>'crowly_provisioned_by')::uuid;
  exception when others then raise exception 'Cadastro exclusivo do administrador'; end;
  if parent is null or not exists(select 1 from public.crowly_members
    where id=parent and workspace_id=parent and role='admin' and enabled) then
    raise exception 'Cadastro exclusivo do administrador';
  end if;
  if new.raw_app_meta_data->>'crowly_role' is distinct from 'staff' then
    raise exception 'O cadastro pelo aplicativo cria apenas funcionarios';
  end if;
  return new;
end $$;
create function public.crowly_register_member() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  insert into public.crowly_members(id,workspace_id,role,full_name,email)
  values(new.id,(new.raw_app_meta_data->>'crowly_provisioned_by')::uuid,'staff',
    left(coalesce(nullif(btrim(new.raw_user_meta_data->>'full_name'),''),'Funcionario'),100),new.email);
  return new;
end $$;
revoke all on function public.crowly_check_registration(),public.crowly_register_member() from public,anon,authenticated;
create trigger crowly_registration_guard before insert on auth.users
  for each row execute function public.crowly_check_registration();
create trigger crowly_registration_profile after insert on auth.users
  for each row execute function public.crowly_register_member();

-- Mantem nome e e-mail da equipe atualizados sem permitir editar papel/equipe.
create function public.crowly_sync_member_identity() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  update public.crowly_members set email=new.email,
    full_name=left(coalesce(nullif(btrim(new.raw_user_meta_data->>'full_name'),''),full_name),100)
    where id=new.id;
  return new;
end $$;
revoke all on function public.crowly_sync_member_identity() from public,anon,authenticated;
create trigger crowly_member_identity after update of raw_user_meta_data,email on auth.users
  for each row execute function public.crowly_sync_member_identity();

do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') and
    not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='crowly_members') then
    alter publication supabase_realtime add table public.crowly_members;
  end if;
end $$;

-- Reconstroi as politicas conhecidas e acrescenta limites RESTRICTIVE para
-- politicas permissivas antigas nao liberarem relatórios ou outra equipe.
do $$
declare t text;
begin
  foreach t in array array['events','areas','devices','alerts','samples','reports','commands'] loop
    execute format('alter table public.%I alter column owner_id set default public.crowly_workspace()',t);
    execute format('drop policy if exists owner_read on public.%I',t);
    execute format('drop policy if exists owner_insert on public.%I',t);
    execute format('drop policy if exists owner_update on public.%I',t);
    execute format('drop policy if exists owner_delete on public.%I',t);
    execute format('create policy crowly_workspace_limit on public.%I as restrictive for all to authenticated using(owner_id=public.crowly_workspace()) with check(owner_id=public.crowly_workspace())',t);
    execute format('create policy crowly_team_read on public.%I for select to authenticated using(owner_id=public.crowly_workspace())',t);
    if t not in ('reports','commands') then
      execute format('create policy crowly_team_insert on public.%I for insert to authenticated with check(owner_id=public.crowly_workspace())',t);
      execute format('create policy crowly_team_update on public.%I for update to authenticated using(owner_id=public.crowly_workspace()) with check(owner_id=public.crowly_workspace())',t);
      execute format('create policy crowly_team_delete on public.%I for delete to authenticated using(owner_id=public.crowly_workspace())',t);
    end if;
  end loop;
end $$;
revoke insert,update,delete,truncate,references,trigger on public.reports from authenticated;
revoke update,delete on public.commands from authenticated;
create policy crowly_reports_admin_only on public.reports as restrictive for select to authenticated using(public.crowly_is_admin());
create policy crowly_commands_insert_limit on public.commands as restrictive for insert to authenticated with check(status='queued' and completed_at is null);
drop policy if exists owner_queue_command on public.commands;
create policy crowly_team_command on public.commands for insert to authenticated
  with check(owner_id=public.crowly_workspace() and status='queued' and completed_at is null);

create or replace function public.set_event_status(target_event uuid,new_status text) returns void
language plpgsql security invoker set search_path=public,pg_temp as $$
declare previous text;
begin
  select status into previous from public.events where id=target_event and owner_id=public.crowly_workspace() for update;
  if not found then raise exception 'Evento nao encontrado'; end if;
  if not ((previous='scheduled' and new_status in ('live','cancelled')) or (previous='live' and new_status='ended')) then
    raise exception 'Transicao de estado invalida: % -> %',previous,new_status;
  end if;
  update public.events set status=new_status where id=target_event and owner_id=public.crowly_workspace();
end $$;

-- Atualiza apenas os dois RPCs existentes que ainda usavam owner_id=auth.uid().
-- O codigo de ingestao do ESP32 permanece intacto, inclusive as credenciais.
do $$
declare source text;
begin
  select pg_get_functiondef('public.seed_my_demo()'::regprocedure) into source;
  source:=replace(source,'uid uuid := auth.uid()','uid uuid := public.crowly_workspace()');
  execute source;
  select pg_get_functiondef('public.crowly_pair(uuid)'::regprocedure) into source;
  source:=replace(source,'e.owner_id is distinct from auth.uid()','e.owner_id is distinct from public.crowly_workspace()');
  execute source;
end $$;
notify pgrst,'reload schema';
commit;
