-- Execute com psql como postgres em um Supabase local descartável.
-- Todas as mudanças são revertidas. Requer a migração Crowly aplicada.
begin;
insert into auth.users(id,email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','crowly-rls-a@example.invalid'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','crowly-rls-b@example.invalid');

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}';
select public.seed_my_demo();
do $$ begin
  if (select count(*) from public.events) <> 4 then raise exception 'Seed incompleto'; end if;
  if (select count(*) from public.reports) <> 2 then raise exception 'Snapshot não foi gerado'; end if;
end $$;

select set_config('crowly.foreign_event',(select id::text from public.events limit 1),true);
select set_config('crowly.foreign_device',(select id::text from public.devices limit 1),true);
-- B não pode ler nem atualizar A e não pode se vincular ao evento de A.
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","role":"authenticated"}';
do $$
declare altered integer;
begin
  if exists(select 1 from public.events) then raise exception 'Vazamento entre contas'; end if;
  if exists(select 1 from public.devices) then raise exception 'Vazamento de dispositivos'; end if;
  if exists(select 1 from public.reports) then raise exception 'Vazamento de relatórios'; end if;
  begin
    insert into public.areas(event_id,name,capacity,position)
    values(current_setting('crowly.foreign_event')::uuid,'Área invasora',10,999);
    raise exception 'Vínculo cruzado permitido';
  exception when foreign_key_violation then null;
  end;
  update public.events set title='INVASÃO';
  get diagnostics altered = row_count;
  if altered <> 0 then raise exception 'Atualização cruzada permitida'; end if;
  begin
    insert into public.events(owner_id,title,location,starts_at,ends_at,capacity)
    values('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Teste','Local',now(),now()+interval '1 hour',10);
    raise exception 'Spoof de proprietário permitido';
  exception when insufficient_privilege then null;
  end;
end $$;
select public.seed_my_demo();
do $$ begin
  if (select count(*) from public.events) <> 4 then raise exception 'Conta B não recebeu seus próprios exemplos'; end if;
end $$;

-- Repetir o seed não duplica dados.
select public.seed_my_demo();
do $$ begin
  if (select count(*) from public.events) <> 4 then raise exception 'Seed não idempotente'; end if;
end $$;
-- Cliente não pode falsificar conclusão de comando ou inserir relatório.
do $$
declare eid uuid; did uuid;
begin
  select event_id,id into eid,did from public.devices limit 1;
  insert into public.commands(event_id,device_id,kind) values(eid,did,'restart');
  begin
    insert into public.commands(event_id,device_id,kind)
    values(eid,current_setting('crowly.foreign_device')::uuid,'restart');
    raise exception 'Comando cruzado permitido';
  exception when foreign_key_violation then null;
  end;
  begin
    update public.commands set status='completed';
    raise exception 'Cliente conseguiu completar comando';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.reports(event_id,total_entries,total_exits,peak_occupancy,average_occupancy)
    select id,0,0,0,0 from public.events where status='scheduled' limit 1;
    raise exception 'Cliente conseguiu fabricar relatório';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
rollback;
