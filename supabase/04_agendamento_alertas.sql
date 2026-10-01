-- =====================================================================
-- Controle de Outdoors - Maqnelson
-- 04_agendamento_alertas.sql  |  Executar uma vez no SQL Editor
-- Pré-requisito: 03_cartao_teams.sql já executado.
-- O banco verifica os alertas todo dia às 8h (Brasília) e chama o
-- webhook do fluxo do Teams, que entrega o cartão a cada Editor.
-- =====================================================================

-- 1. Extensões de agendamento e de chamadas HTTP
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

-- 2. URL do webhook guardada no cofre de segredos (Vault)
--    TROQUE o texto abaixo pela URL copiada do fluxo do Teams.
select vault.create_secret(
  'COLE-AQUI-A-URL-DO-WEBHOOK-DO-TEAMS',
  'webhook_teams_outdoors',
  'URL do fluxo do Teams que entrega os alertas de alvará'
);

-- 3. Guarda o número da requisição para conferir se o Teams recebeu
alter table public.notificacoes_enviadas
  add column if not exists request_id bigint;

-- 4. Envio dos alertas
create or replace function public.enviar_alertas_outdoors()
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url  text;
  v_req  bigint;
  v_qtd  integer := 0;
  r      record;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'webhook_teams_outdoors'
  limit 1;

  if v_url is null or v_url like 'COLE-AQUI%' then
    raise exception 'URL do webhook do Teams não configurada no Vault (webhook_teams_outdoors).';
  end if;

  for r in select * from public.alertas_pendentes loop
    select net.http_post(
      url     := v_url,
      body    := jsonb_build_object('recipient', r.email, 'messageBody', r.cartao::text),
      headers := '{"Content-Type": "application/json"}'::jsonb
    ) into v_req;

    insert into public.notificacoes_enviadas (outdoor_id, usuario_email, marco, vencimento, request_id)
    values (r.outdoor_id, r.email, r.marco, r.vencimento, v_req)
    on conflict do nothing;

    v_qtd := v_qtd + 1;
  end loop;

  return v_qtd;
end $$;

-- 5. Reprocessamento: se o Teams recusou ou não respondeu,
--    apaga o registro para o alerta sair de novo na próxima execução.
create or replace function public.reprocessar_alertas_com_falha()
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_qtd integer;
begin
  delete from public.notificacoes_enviadas n
  using net._http_response resp
  where n.request_id = resp.id
    and n.enviado_em > now() - interval '1 day'
    and (resp.timed_out or resp.status_code is null or resp.status_code not between 200 and 299);
  get diagnostics v_qtd = row_count;
  return v_qtd;
end $$;

revoke all on function public.enviar_alertas_outdoors()       from public, anon, authenticated;
revoke all on function public.reprocessar_alertas_com_falha() from public, anon, authenticated;

-- 6. Agendamentos (horário em UTC: 11:00 UTC = 08:00 em Brasília)
select cron.schedule('alertas-outdoors',            '0 11 * * *',  $$select public.enviar_alertas_outdoors()$$);
select cron.schedule('alertas-outdoors-reprocesso', '30 11 * * *', $$select public.reprocessar_alertas_com_falha()$$);

-- =====================================================================
-- CONSULTAS ÚTEIS (rodar quando precisar, não fazem parte da instalação)
-- =====================================================================
-- Disparar o envio agora, para teste:
--   select public.enviar_alertas_outdoors();
--
-- Ver se o Teams recebeu (status 202 = recebido), nas últimas horas:
--   select n.enviado_em, n.usuario_email, o.apelido, n.marco, r.status_code, r.error_msg
--   from public.notificacoes_enviadas n
--   join public.outdoors o on o.id = n.outdoor_id
--   left join net._http_response r on r.id = n.request_id
--   order by n.enviado_em desc limit 20;
--
-- Histórico das execuções agendadas:
--   select jobname, start_time, status, return_message
--   from cron.job_run_details d join cron.job j using (jobid)
--   order by start_time desc limit 20;
--
-- Trocar a URL do webhook:
--   select vault.update_secret(
--     (select id from vault.secrets where name = 'webhook_teams_outdoors'),
--     'NOVA-URL');
