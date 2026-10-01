-- =====================================================================
-- Controle de Outdoors - Maqnelson
-- 03_cartao_teams.sql  |  Executar uma vez no SQL Editor
-- Acrescenta à view "alertas_pendentes" a coluna "cartao", com o
-- cartão do Teams já pronto. Assim o Power Automate só repassa o cartão.
-- =====================================================================

create or replace view public.alertas_pendentes
with (security_invoker = on) as
with base as (
  select o.*,
         (o.vencimento - (now() at time zone 'America/Sao_Paulo')::date) as dias
  from public.outdoors o
  where o.status <> 'Encerrado' and o.vencimento is not null
),
faixa as (
  select b.*,
         case when dias between 11 and 15 then 15
              when dias between 6  and 10 then 10
              when dias between 0  and 5  then 5 end as marco
  from base b
)
select f.id as outdoor_id, f.apelido, f.endereco, f.numero_alvara,
       f.vencimento, f.dias, f.marco, u.email, u.nome,
       jsonb_build_object(
         'type', 'AdaptiveCard',
         '$schema', 'http://adaptivecards.io/schemas/adaptive-card.json',
         'version', '1.4',
         'body', jsonb_build_array(
           jsonb_build_object('type', 'TextBlock', 'weight', 'Bolder', 'size', 'Medium', 'wrap', true,
             'text', case when f.dias = 0 then '⚠️ Alvará de outdoor vence hoje'
                          when f.dias = 1 then '⚠️ Alvará de outdoor vence em 1 dia'
                          else '⚠️ Alvará de outdoor vence em ' || f.dias || ' dias' end),
           jsonb_build_object('type', 'TextBlock', 'text', f.apelido,
             'weight', 'Bolder', 'wrap', true, 'spacing', 'Medium'),
           jsonb_build_object('type', 'TextBlock', 'text', coalesce(f.endereco, ''),
             'wrap', true, 'spacing', 'None', 'isSubtle', true),
           jsonb_build_object('type', 'FactSet', 'facts', jsonb_build_array(
             jsonb_build_object('title', 'Alvará', 'value', coalesce(f.numero_alvara, 'não informado')),
             jsonb_build_object('title', 'Vencimento', 'value', to_char(f.vencimento, 'DD/MM/YYYY'))
           ))
         ),
         'actions', jsonb_build_array(
           jsonb_build_object('type', 'Action.OpenUrl', 'title', 'Abrir o Controle de Outdoors',
             'url', 'https://jenniferpereiramaqnelson.github.io/Controle-de-Outdoors/')
         )
       ) as cartao
from faixa f
cross join public.usuarios u
where f.marco is not null
  and u.perfil = 'editor' and u.ativo
  and not exists (
    select 1 from public.notificacoes_enviadas n
    where n.outdoor_id = f.id and n.usuario_email = u.email
      and n.marco = f.marco and n.vencimento = f.vencimento
  );

revoke all on public.alertas_pendentes from anon, authenticated;
