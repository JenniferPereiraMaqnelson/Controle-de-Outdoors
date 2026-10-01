-- =====================================================================
-- Controle de Outdoors - Maqnelson
-- 02_dados_iniciais.sql  |  Executar uma única vez, após o 01_estrutura.sql
-- Origem: Controle - Outdoors.xlsx (abas "Ativos" e "Baixado")
-- =====================================================================

-- ---------------------------------------------------------------------
-- PRIMEIRO EDITOR: troque pelo seu e-mail Microsoft corporativo.
-- Sem esta linha ninguém consegue entrar na aplicação.
-- ---------------------------------------------------------------------
insert into public.usuarios (email, nome, perfil, criado_por)
values ('SEU.EMAIL@SUAEMPRESA.com.br', 'Seu nome', 'editor', 'carga inicial');

-- ---------------------------------------------------------------------
-- Outdoors
-- Critérios aplicados na migração:
--  * "Status" da planilha virou o status principal.
--  * "Status 2" e "Processo na PMU" viraram a Situação na PMU.
--  * "-" e "NA" viraram campo vazio; espaços extras foram removidos.
--  * A aba "Baixado" entrou com status "Encerrado" (fica fora dos alertas).
-- ---------------------------------------------------------------------
insert into public.outdoors
  (empresa, apelido, propaganda, endereco, cidade, latitude, longitude,
   data_inicio, vencimento, status, situacao_pmu, protocolo_pmu, numero_alvara,
   imagem_url, atualizado_por)
values
  ('Maqnelson Empreendimentos', 'Granja Marileusa (Área Estoque)', 'Outdoor 1 face - 9x3',
   'Av. Maria Silva Garcia, 257 - Granja Marileusa', 'Uberlândia', -18.8806327088755, -48.2437523188419,
   '2024-05-10', '2027-05-10', 'Ativo', null, null, '242/2024',
   'https://a.imagem.app/Br7MpY.png', 'carga inicial'),

  ('Maqnelson Empreendimentos', 'Rondon Carro de Boi (Área Estoque)', 'Outdoor 1 face - 9x3',
   'Av. Rondon Pacheco - Cazeca', 'Uberlândia', -18.9177971720151, -48.2660978819699,
   '2024-03-27', '2027-03-27', 'Ativo', null, null, '131/2024',
   'https://a.imagem.app/BrYG20.png', 'carga inicial'),

  ('Maqnelson Empreendimentos', 'ABC - Carioca', 'Outdoor 1 face - 9x3',
   'Rua Oscarina Cunha Chaves - Patrimônio', 'Uberlândia', -18.9402433999113, -48.2855739348838,
   '2025-09-19', '2030-09-19', 'Em andamento', 'Protocolado', '30619/2026', '681/2025',
   null, 'carga inicial'),

  ('Maqnelson Empreendimentos', 'Loteamento Harmonia', 'Outdoor 2 faces - 18x3',
   'Rua Rafael Marino Neto - Jardim Karaíba', 'Uberlândia', -18.9478915729837, -48.267692038155,
   '2023-11-27', '2026-11-27', 'Ativo', null, null, '809/2023',
   null, 'carga inicial'),

  ('Maqnelson Empreendimentos', 'Av. Seme Simão (Área Estoque)', 'Outdoor 2 faces - 18x3',
   'Av. Seme Simão - Jardim Karaíba', 'Uberlândia', -18.9511156442644, -48.2611803506768,
   null, null, 'Em andamento', 'Protocolado', '48053/2026', null,
   null, 'carga inicial'),

  ('Maqnelson Empreendimentos', 'Loteamento Guarani', 'Outdoor 1 face - 9x3',
   'Av. Taylor Silva - Guarani', 'Uberlândia', -18.8969482111828, -48.3298015920933,
   '2025-01-01', '2030-07-11', 'Ativo', null, null, '466/2025',
   null, 'carga inicial'),

  ('Negócios', 'Av. Paulo Roberto Cunha', 'Outdoor 1 face - 9x3',
   'Av. Paulo Roberto Cunha Santos, 1.535 - Roosevelt', 'Uberlândia', -18.9045132422042, -48.2895763471907,
   '2020-10-13', '2023-10-13', 'Em licenciamento', 'Tramitando', '15909/2024', null,
   null, 'carga inicial'),

  ('Maqnelson Empreendimentos', 'Cocred BTS', 'Outdoor 1 face - 9x3',
   'Av. Rondon Pacheco, 3.585 - Cazeca', 'Uberlândia', -18.916957725497902, -48.2652384115479,
   '2024-04-29', '2027-04-29', 'Em andamento', 'Indeferido', '30612/2026', null,
   null, 'carga inicial'),

  ('Negócios', 'Horto - Gleba 01A', 'Outdoor 1 face - 9x3',
   'Gleba 01A - Bairro: Jardim Karaíba', 'Uberlândia', -18.9533841238034, -48.2560537356219,
   null, null, 'Em andamento', null, '48105/2026', null,
   null, 'carga inicial'),

  ('Negócios', 'Horto - Gleba 02A', 'Outdoor 1 face - 9x3',
   'Gleba 02A - Bairro: Jardim Karaíba', 'Uberlândia', -18.9540561356721, -48.2551336957314,
   null, null, 'Em andamento', null, '48106/2026', null,
   null, 'carga inicial'),

  ('Negócios', 'Complexo Santa Mônica', 'Outdoor 2 faces - 18x3',
   'Av. Professora Juvenilia dos Santos, Qd. A - Seg. Pereira', 'Uberlândia', -18.923918492416, -48.2514441185709,
   '2023-11-14', '2026-11-14', 'Em encerramento', null, null, '781/2023',
   null, 'carga inicial'),

  ('Negócios', 'Silvio Rugani', 'Outdoor 2 faces - 18x3',
   'Avenida Silvio Rugani', 'Uberlândia', -18.9304232561583, -48.2943181402156,
   '2026-01-01', null, 'Em andamento', null, '48588/2026', null,
   null, 'carga inicial'),

  ('Negócios', 'João Naves', 'Outdoor 2 faces - 18x3',
   'Avenida João Naves', 'Uberlândia', -18.9135860110896, -48.2589976193348,
   null, null, 'Em andamento', null, '64644/2026', null,
   null, 'carga inicial'),

  -- Aba "Baixado"
  ('Negócios', 'Bahamas - Segismundo', 'Outdoor 1 face - 9x3',
   'Av. Segismundo Pereira, 2626 - Santa Mônica', 'Uberlândia', -18.9223124284875, -48.2345168562177,
   '2023-11-27', '2026-11-27', 'Encerrado', 'Baixado', '59674/2025', null,
   null, 'carga inicial'),

  ('Negócios', 'ABC - Anselmo', 'Outdoor 1 face - 9x3',
   'Av. Anselmo Alves dos Santos - Tibery', 'Uberlândia', -18.9094160801612, -48.246497174631,
   null, null, 'Encerrado', 'Arquivado', '34345/2025', null,
   null, 'carga inicial');

-- ---------------------------------------------------------------------
-- Andamentos (vindos da coluna "Observação")
-- Registros sem data na planilha entram com a data da migração.
-- ---------------------------------------------------------------------
insert into public.andamentos (outdoor_id, data, descricao, autor)
select o.id, a.data::date, a.descricao, 'carga inicial'
from (values
  ('ABC - Carioca',           current_date::text, 'Cancelamento de outdoor. (Registro migrado da planilha, sem data original.)'),
  ('Loteamento Guarani',      '2025-07-11',       'Licença emitida.'),
  ('Av. Paulo Roberto Cunha', '2025-08-26',       'Tramitando.'),
  ('Cocred BTS',              '2025-08-27',       'Foi dado entrada na PMU.'),
  ('Cocred BTS',              '2025-10-29',       'Indeferido.'),
  ('Bahamas - Segismundo',    '2025-08-27',       'Foi dado entrada na PMU.'),
  ('Bahamas - Segismundo',    '2025-10-28',       'Foi dado baixa.'),
  ('ABC - Anselmo',           current_date::text, 'A licença nunca foi aprovada; com a finalização da obra, o processo não foi retomado. (Registro migrado da planilha, sem data original.)')
) as a(apelido, data, descricao)
join public.outdoors o on o.apelido = a.apelido;
