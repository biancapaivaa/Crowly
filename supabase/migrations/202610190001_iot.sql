-- Executar DEPOIS de 202610160001_crowly.sql. Nao desativa RLS.
begin;
create table public.crowly_boards (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null unique references public.events(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  counter_id uuid not null references public.devices(id) on delete cascade,
  queue_id uuid not null references public.devices(id) on delete cascade,
  climate_id uuid not null references public.devices(id) on delete cascade,
  button_id uuid not null references public.devices(id) on delete cascade,
  area_id uuid not null references public.areas(id) on delete cascade,
  enabled boolean not null default true,
  current_boot uuid,
  last_seq bigint not null default -1,
  counters jsonb not null default '{}',
  alert_flags jsonb not null default '{}',
  last_seen timestamptz
);
create table public.crowly_retired_boots (
  board_id uuid not null references public.crowly_boards(id) on delete cascade,
  boot_id uuid not null,
  primary key(board_id,boot_id)
);
alter table public.crowly_boards enable row level security;
alter table public.crowly_retired_boots enable row level security;
revoke all on public.crowly_boards,public.crowly_retired_boots from public,anon,authenticated;
grant all on public.crowly_boards,public.crowly_retired_boots to service_role;

create function public.crowly_pair(target_event uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  e public.events%rowtype;
  b public.crowly_boards%rowtype;
  secret text;
  a uuid;
  c uuid;
  q uuid;
  t uuid;
  k uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(target_event::text,0));
  select * into e from public.events where id=target_event;
  if not found or e.owner_id is distinct from auth.uid() then
    raise exception 'Evento nao encontrado na sua conta' using errcode='42501';
  end if;
  if e.status not in ('scheduled','live') then raise exception 'Evento encerrado ou cancelado'; end if;
  secret := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  select * into b from public.crowly_boards where event_id=e.id;
  if found then
    update public.crowly_boards set token_hash=encode(sha256(convert_to(secret,'UTF8')),'hex'), enabled=true where id=b.id;
  else
    insert into public.areas(owner_id,event_id,name,capacity,position,sensor_count)
    values(e.owner_id,e.id,'Monitoramento ESP32',e.capacity,
      coalesce((select max(position)+1 from public.areas where event_id=e.id),0),4) returning id into a;
    insert into public.devices(owner_id,event_id,name,kind) values(e.owner_id,e.id,'ESP32 - Contagem','counter') returning id into c;
    insert into public.devices(owner_id,event_id,name,kind) values(e.owner_id,e.id,'ESP32 - Fila','queue') returning id into q;
    insert into public.devices(owner_id,event_id,name,kind) values(e.owner_id,e.id,'ESP32 - Clima','environment') returning id into t;
    insert into public.devices(owner_id,event_id,name,kind) values(e.owner_id,e.id,'ESP32 - Botoes','button') returning id into k;
    insert into public.crowly_boards(event_id,owner_id,token_hash,counter_id,queue_id,climate_id,button_id,area_id)
      values(e.id,e.owner_id,encode(sha256(convert_to(secret,'UTF8')),'hex'),c,q,t,k,a) returning * into b;
  end if;
  return jsonb_build_object('board_id',b.id,'event_id',e.id,'device_token',secret);
end $$;
revoke all on function public.crowly_pair(uuid) from public,anon,authenticated;
grant execute on function public.crowly_pair(uuid) to authenticated;

create function public.crowly_ingest(device_token text,payload jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  b public.crowly_boards%rowtype;
  e public.events%rowtype;
  boot uuid;
  seq bigint;
  vals jsonb;
  previous jsonb;
  flags jsonb;
  key text;
  n bigint;
  old_n bigint;
  in_delta integer;
  out_delta integer;
  total integer;
  temperature numeric;
  humidity numeric;
  distance numeric;
  occupancy numeric;
  queue_state text;
  title text;
  severity text;
begin
  if device_token is null or length(device_token)<>64 then raise exception 'Credencial do ESP32 invalida' using errcode='28000'; end if;
  select * into b from public.crowly_boards
    where token_hash=encode(sha256(convert_to(device_token,'UTF8')),'hex') and enabled for update;
  if not found then raise exception 'Credencial do ESP32 invalida ou revogada' using errcode='28000'; end if;
  select * into e from public.events where id=b.event_id for update;
  if e.status<>'live' then raise exception 'Inicie o monitoramento do evento no app'; end if;
  if jsonb_typeof(payload)<>'object' or pg_column_size(payload)>4096 then raise exception 'Payload invalido'; end if;
  boot := (payload->>'boot_id')::uuid;
  seq := (payload->>'seq')::bigint;
  if boot is null or seq is null or seq<0 then raise exception 'boot_id/seq invalidos'; end if;
  if exists(select 1 from public.crowly_retired_boots where board_id=b.id and boot_id=boot) then
    return jsonb_build_object('accepted',false,'reason','retired_boot');
  end if;
  if b.current_boot=boot and seq<=b.last_seq then
    return jsonb_build_object('accepted',false,'reason','duplicate');
  end if;
  if b.last_seen>clock_timestamp()-interval '5 seconds' then
    return jsonb_build_object('accepted',false,'reason','rate_limit');
  end if;
  vals:=payload->'counters';
  if vals is null or jsonb_typeof(vals)<>'object' then raise exception 'Contadores ausentes'; end if;
  previous:=case when b.current_boot=boot then b.counters else '{}'::jsonb end;
  foreach key in array array['entries','exits','emergency','crowding','team'] loop
    n:=(vals->>key)::bigint;
    old_n:=coalesce((previous->>key)::bigint,0);
    if n is null or n<old_n or n<0 or n>100000000 then raise exception 'Contador invalido: %',key; end if;
  end loop;
  temperature:=(payload->>'temperature')::numeric;
  humidity:=(payload->>'humidity')::numeric;
  distance:=(payload->>'distance_cm')::numeric;
  if temperature is not null and not (temperature between -40 and 80) then raise exception 'Temperatura invalida'; end if;
  if humidity is not null and not (humidity between 0 and 100) then raise exception 'Umidade invalida'; end if;
  if distance is not null and not (distance between 2 and 450) then raise exception 'Distancia invalida'; end if;
  in_delta:=(vals->>'entries')::integer-coalesce((previous->>'entries')::integer,0);
  out_delta:=(vals->>'exits')::integer-coalesce((previous->>'exits')::integer,0);
  total:=greatest(0,e.people+in_delta-out_delta);
  occupancy:=least(100.0,100.0*total/e.capacity);
  queue_state:=case when distance is null then 'Sem leitura' when distance>120 then 'Vazia' when distance>50 then 'Moderada' else 'Cheia' end;
  if b.current_boot is not null and b.current_boot<>boot then
    insert into public.crowly_retired_boots values(b.id,b.current_boot) on conflict do nothing;
  end if;
  update public.events set people=total,entries=entries+in_delta,exits=exits+out_delta where id=e.id;
  update public.areas set people=total where id=b.area_id;
  update public.devices set status='online',last_seen=now(),reading=case id
    when b.counter_id then total::text || ' pessoas'
    when b.queue_id then queue_state
    when b.climate_id then case when temperature is null then 'Sem leitura' else round(temperature,1)::text || ' °C | ' || coalesce(round(humidity,1)::text,'—') || '%' end
    else 'Conectado' end
    where id in (b.counter_id,b.queue_id,b.climate_id,b.button_id);
  insert into public.samples(owner_id,event_id,entries,exits,occupancy,temperature,humidity)
    values(b.owner_id,e.id,e.entries+in_delta,e.exits+out_delta,occupancy,temperature,humidity);
  flags:=jsonb_build_object('hot',coalesce(temperature>=30,false),'full',queue_state='Cheia','capacity',occupancy>=90);
  foreach key in array array['emergency','crowding','team','hot','full','capacity'] loop
    if (key in ('emergency','crowding','team') and (vals->>key)::bigint>coalesce((previous->>key)::bigint,0))
       or (key in ('hot','full','capacity') and coalesce((flags->>key)::boolean,false) and not coalesce((b.alert_flags->>key)::boolean,false)) then
      title:=case key when 'emergency' then 'Emergencia acionada no ESP32' when 'crowding' then 'Aglomeracao informada no ESP32'
        when 'team' then 'Equipe solicitada no ESP32' when 'hot' then 'Temperatura elevada' when 'full' then 'Fila cheia' else 'Ocupacao critica' end;
      severity:=case key when 'emergency' then 'emergency' when 'team' then 'low' else 'high' end;
      insert into public.alerts(owner_id,event_id,title,description,severity)
        values(b.owner_id,e.id,title,'Origem: ESP32. Ocupacao: '||round(occupancy,1)||'%. Fila: '||queue_state||'. Temperatura: '||coalesce(temperature::text,'sem leitura')||' C.',severity);
    end if;
  end loop;
  update public.crowly_boards set current_boot=boot,last_seq=seq,counters=vals,alert_flags=flags,last_seen=clock_timestamp() where id=b.id;
  return jsonb_build_object('accepted',true,'people',total,'queue',queue_state);
end $$;
revoke all on function public.crowly_ingest(text,jsonb) from public,anon,authenticated;
grant execute on function public.crowly_ingest(text,jsonb) to anon;
notify pgrst,'reload schema';
commit;
