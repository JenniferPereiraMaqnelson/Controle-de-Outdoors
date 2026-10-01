-- =====================================================================
-- Controle de Outdoors - Maqnelson
-- 05_atualizar_agendamento.sql
-- Use no lugar do 04 quando ele já tiver sido executado antes.
-- Pode ser rodado quantas vezes precisar, sem erro.
-- =====================================================================

-- 1. Atualiza a URL do webhook (TROQUE pelo endereço copiado do gatilho)
select vault.update_secret(
  (select id from vault.secrets where name = 'webhook_teams_outdoors'),
  'COLE-AQUI-A-URL-DO-WEBHOOK-DO-TEAMS'
);

-- 2. Coluna de acompanhamento do envio
alter table public.notificacoes_enviadas
  add column if not exists request_id bigint;

-- 3. Envio dos alertas (formato recipient + messageBody)
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

-- 4. Reprocessamento de envios recusados
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

-- 5. Agendamentos (com o mesmo nome, apenas atualizam os existentes)
select cron.schedule('alertas-outdoors',            '0 11 * * *',  $$select public.enviar_alertas_outdoors()$$);
select cron.schedule('alertas-outdoors-reprocesso', '30 11 * * *', $$select public.reprocessar_alertas_com_falha()$$);

-- 6. Conferência: deve mostrar o início da URL e os dois agendamentos
select left(decrypted_secret, 45) as inicio_da_url
from vault.decrypted_secrets where name = 'webhook_teams_outdoors';

select jobname, schedule, active from cron.job where jobname like 'alertas-outdoors%';
