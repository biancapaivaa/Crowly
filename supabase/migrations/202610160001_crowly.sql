-- Crowly: aplique em um projeto Supabase novo pelo SQL Editor ou CLI.
-- Modelo individual: cada usuário só acessa seus próprios eventos.
begin;

create table public.events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  location text not null check (char_length(btrim(location)) between 1 and 200),
  status text not null default 'scheduled' check (status in ('scheduled','live','ended','cancelled')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null check (capacity > 0),
  people integer not null default 0 check (people >= 0),
  entries integer not null default 0 check (entries >= 0),
  exits integer not null default 0 check (exits >= 0),
  image_url text check (image_url is null or image_url ~ '^https://'),
  created_at timestamptz not null default now(),
  unique (id, owner_id),
  check (ends_at > starts_at)
);
create table public.areas (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null,
  name text not null,
  capacity integer not null check (capacity > 0),
  people integer not null default 0 check (people >= 0),
  sensor_count integer not null default 0 check (sensor_count >= 0),
  position integer not null default 0 check (position >= 0),
  unique(id, owner_id, event_id),
  unique(event_id, position),
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade
);
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null,
  name text not null,
  kind text not null check (kind in ('counter','queue','button','environment')),
  status text not null default 'offline' check (status in ('online','offline','maintenance')),
  battery integer check (battery between 0 and 100),
  reading text,
  last_seen timestamptz,
  unique(id, owner_id, event_id),
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade
);
create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null,
  title text not null,
  description text not null default '',
  severity text not null check (severity in ('emergency','high','medium','low')),
  status text not null default 'open' check (status in ('open','reviewing','resolved')),
  created_at timestamptz not null default now(),
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade
);
create table public.samples (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null,
  recorded_at timestamptz not null default now(),
  entries integer not null default 0 check (entries >= 0),
  exits integer not null default 0 check (exits >= 0),
  occupancy numeric(6,2) not null check (occupancy between 0 and 100),
  temperature numeric(5,2),
  humidity numeric(5,2) check (humidity between 0 and 100),
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null unique,
  total_entries integer not null,
  total_exits integer not null,
  peak_occupancy numeric(6,2) not null,
  average_occupancy numeric(6,2) not null,
  temperature numeric(5,2),
  humidity numeric(5,2),
  created_at timestamptz not null default now(),
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade
);
create table public.commands (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  event_id uuid not null,
  device_id uuid,
  area_id uuid,
  kind text not null check (kind in ('restart','dispatch','issue')),
  note text check (char_length(note) <= 1000),
  status text not null default 'queued' check (status in ('queued','processing','completed','failed')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  foreign key (event_id, owner_id) references public.events(id, owner_id) on delete cascade,
  foreign key (device_id, owner_id, event_id) references public.devices(id, owner_id, event_id) on delete cascade,
  foreign key (area_id, owner_id, event_id) references public.areas(id, owner_id, event_id) on delete cascade,
  check ((kind in ('restart','issue') and device_id is not null) or (kind = 'dispatch' and area_id is not null))
);

create index events_owner_start_idx on public.events(owner_id, starts_at);
create index areas_owner_event_idx on public.areas(owner_id, event_id);
create index devices_owner_event_idx on public.devices(owner_id, event_id);
create index alerts_owner_event_idx on public.alerts(owner_id, event_id, created_at desc);
create index samples_owner_event_idx on public.samples(owner_id, event_id, recorded_at);
create index reports_owner_idx on public.reports(owner_id);
create index commands_owner_event_idx on public.commands(owner_id, event_id);
create index commands_queued_idx on public.commands(created_at) where status = 'queued';

-- RLS em todas as tabelas. IDs de evento e proprietário são validados juntos
-- por FKs compostas para impedir associações cruzadas entre contas.
do $$
declare t text;
begin
  foreach t in array array['events','areas','devices','alerts','samples','reports','commands'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy owner_read on public.%I for select to authenticated using (owner_id = (select auth.uid()))', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
    if t not in ('reports','commands') then
      execute format('grant insert, update, delete on public.%I to authenticated', t);
      execute format('create policy owner_insert on public.%I for insert to authenticated with check (owner_id = (select auth.uid()))', t);
      execute format('create policy owner_update on public.%I for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()))', t);
      execute format('create policy owner_delete on public.%I for delete to authenticated using (owner_id = (select auth.uid()))', t);
    end if;
  end loop;
end $$;
grant insert on public.commands to authenticated;
create policy owner_queue_command on public.commands for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'queued' and completed_at is null);
-- Usuários leem a fila; apenas o worker com service_role altera o resultado.

-- Snapshot automático ao encerrar; cliente não pode escrever relatórios.
create function public.snapshot_event_report() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.status = 'ended' and old.status <> 'ended' then
    insert into public.reports(owner_id,event_id,total_entries,total_exits,peak_occupancy,average_occupancy,temperature,humidity)
    select new.owner_id,new.id,new.entries,new.exits,
      coalesce(max(s.occupancy),0),coalesce(avg(s.occupancy),0),avg(s.temperature),avg(s.humidity)
    from public.samples s where s.event_id = new.id and s.owner_id = new.owner_id
    on conflict(event_id) do nothing;
  end if;
  return new;
end $$;
revoke all on function public.snapshot_event_report() from public, anon, authenticated;
create trigger snapshot_on_event_close after update of status on public.events
  for each row execute function public.snapshot_event_report();

-- Security invoker: RLS continua valendo no RPC.
create function public.set_event_status(target_event uuid,new_status text) returns void
language plpgsql security invoker set search_path = public, pg_temp as $$
declare previous text;
begin
  select status into previous from public.events where id=target_event and owner_id=auth.uid() for update;
  if not found then raise exception 'Evento não encontrado'; end if;
  if not ((previous='scheduled' and new_status in ('live','cancelled')) or (previous='live' and new_status='ended')) then
    raise exception 'Transição de estado inválida: % -> %',previous,new_status;
  end if;
  update public.events set status=new_status where id=target_event and owner_id=auth.uid();
end $$;
revoke all on function public.set_event_status(uuid,text) from public, anon;
grant execute on function public.set_event_status(uuid,text) to authenticated;

-- Dados de exemplo opcionais, criados SOMENTE na conta de quem chama.
-- Datas válidas relativas ao dia de execução; não reproduz 31/11 do screenshot.
create function public.seed_my_demo() returns void
language plpgsql security invoker set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  eid uuid;
  k integer;
  j integer;
  base timestamptz := date_trunc('day', now()) + interval '18 hours';
  event_start timestamptz;
  names text[] := array['Palco Principal','Área VIP','Entrada','Alimentação','Bar','Banheiros','Saída'];
  caps integer[] := array[7300,2200,1300,2300,1500,1700,1700];
  heads integer[] := array[6643,1826,200,1794,1125,280,120];
  titles text[] := array['Superlotação - Palco Sunset','Fila acima do limite - Bar 2','Alerta de suporte - Área B','Temperatura elevada - VIP Lounge','Sensor offline - Entrada 3','Bateria fraca - Sensor 12'];
  descriptions text[] := array['92% Ocupação','45 pessoas','Equipe acionada','29°C','Sem sinal','Bateria 10%'];
  severities text[] := array['emergency','high','medium','high','medium','low'];
  states text[] := array['open','reviewing','resolved','open','reviewing','resolved'];
  entry_series integer[] := array[120,420,320,750,640,980,880];
  exit_series integer[] := array[80,200,380,500,620,750,920];
  occupancy_series integer[] := array[25,40,35,63,54,87,72];
begin
  if uid is null then raise exception 'Autenticação necessária'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));
  if exists(select 1 from public.events where owner_id=uid) then return; end if;
  for k in 1..4 loop
    event_start := base + case k when 2 then interval '7 days' when 3 then interval '-30 days' when 4 then interval '-45 days' else interval '0 days' end;
    insert into public.events(owner_id,title,location,status,starts_at,ends_at,capacity,people,entries,exits)
    values(uid,(array['Rock in Rio 2026','Lollapalooza 2026','The Town Club','Taubaté Expo Agro'])[k],
      'Parque Olímpico - Rio de Janeiro',case when k=2 then 'scheduled' else 'live' end,event_start,event_start+interval '8 hours',18000,
      case when k=1 then 12400 else 0 end,
      case k when 1 then 14230 when 3 then 98200 when 4 then 19400 else 0 end,
      case k when 1 then 1830 when 3 then 96800 when 4 then 19400 else 0 end)
      returning id into eid;
    for j in 1..7 loop
      insert into public.areas(owner_id,event_id,name,capacity,people,sensor_count,position)
      values(uid,eid,names[j],caps[j],heads[j],case when j=1 then 8 else 3 end,j-1);
      insert into public.samples(owner_id,event_id,recorded_at,entries,exits,occupancy,temperature,humidity)
      values(uid,eid,date_trunc('day',event_start)+make_interval(hours=>8+j*2),entry_series[j],exit_series[j],occupancy_series[j],28,65);
    end loop;
    insert into public.devices(owner_id,event_id,name,kind,status,battery,reading,last_seen) values
      (uid,eid,'Entrada Principal','counter','offline',45,'1.247',now()-interval '15 minutes'),
      (uid,eid,'Palco Sunset','counter','online',90,'180',now()),
      (uid,eid,'VIP Lounge','counter','online',90,'45',now()),
      (uid,eid,'Bar Central','counter','online',90,'64',now()),
      (uid,eid,'Bar 2','queue','online',90,'45',now()),
      (uid,eid,'Bilheteria','queue','online',90,'12',now()),
      (uid,eid,'Banheiro','queue','online',90,'8',now()),
      (uid,eid,'Área B','button','online',90,'Suporte',now()),
      (uid,eid,'Palco','button','online',90,'Emergência',now()),
      (uid,eid,'Área VIP','environment','online',90,'29°C',now()),
      (uid,eid,'Palco','environment','online',90,'26°C',now());
    for j in 1..6 loop
      insert into public.alerts(owner_id,event_id,title,description,severity,status,created_at)
      values(uid,eid,titles[j],descriptions[j],severities[j],states[j],now()-make_interval(mins=>(array[1,12,20,35,60,120])[j]));
    end loop;
    if k in (3,4) then update public.events set status='ended' where id=eid; end if;
  end loop;
end $$;
revoke all on function public.seed_my_demo() from public, anon;
grant execute on function public.seed_my_demo() to authenticated;

-- Habilita publicação de mudanças nas tabelas usadas pelo aplicativo.
do $$
declare t text;
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach t in array array['events','areas','devices','alerts','samples','reports','commands'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
        execute format('alter publication supabase_realtime add table public.%I',t);
      end if;
    end loop;
  end if;
end $$;
commit;
