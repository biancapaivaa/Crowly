-- Execute DEPOIS da migracao de papeis. Use a conta JA EXISTENTE dona dos eventos.
-- Troque o e-mail abaixo. Nao use o e-mail de um funcionario.
-- Uma conta nova para o primeiro admin deve ser criada em Authentication > Users
-- ANTES de executar a migracao, pois ela bloqueia cadastros publicos.
do $$
declare target auth.users%rowtype;
begin
  select * into target from auth.users where lower(email)=lower('biancapaiva.senai@gmail.com');
  if not found then raise exception 'E-mail nao encontrado em Authentication > Users'; end if;
  if exists(select 1 from public.crowly_members where id=target.id and role<>'admin') then
    raise exception 'Esta conta ja e funcionario. Escolha a conta original do administrador.';
  end if;
  insert into public.crowly_members(id,workspace_id,role,full_name,email)
  values(target.id,target.id,'admin',
    left(coalesce(nullif(btrim(target.raw_user_meta_data->>'full_name'),''),'Administrador'),100),target.email)
  on conflict(id) do nothing;
end $$;
