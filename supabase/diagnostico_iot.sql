-- Somente leitura. Execute no SQL Editor para conferir o evento e a conta.
select e.id as event_id,e.title,e.status,u.email as conta_do_app,
       e.people,e.entries,e.exits,
       (select count(*) from public.samples s where s.event_id=e.id) as leituras_recebidas,
       (select max(s.recorded_at) from public.samples s where s.event_id=e.id) as ultima_leitura,
       (select count(*) from public.devices d where d.event_id=e.id) as dispositivos,
       (select count(*) from public.alerts a where a.event_id=e.id) as alertas
from public.events e
left join auth.users u on u.id=e.owner_id
order by e.created_at desc;
