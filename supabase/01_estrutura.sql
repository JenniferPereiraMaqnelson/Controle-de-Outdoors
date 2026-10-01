-- =====================================================================
-- Controle de Outdoors - Maqnelson
-- 01_estrutura.sql  |  Executar uma única vez no SQL Editor do Supabase
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Usuários e perfis de acesso
-- ---------------------------------------------------------------------
create table if not exists public.usuarios (
  id          uuid primary key default gen_random_uuid(),
  email       text not null unique,
  nome        text,
  perfil      text not null check (perfil in ('editor', 'visualizador')),
  ativo       boolean not null default true,
  criado_em   timestamptz not null default now(),
  criado_por  text
);

-- E-mail de quem está logado (vem do token do login Microsoft)
create or replace function public.email_atual()
returns text language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

-- Perfil de quem está logado; nulo = e-mail não liberado
create or replace function public.perfil_atual()
returns text language sql stable security definer set search_path = public as $$
  select perfil from public.usuarios
  where email = public.email_atual() and ativo
  limit 1;
$$;
revoke all on function public.perfil_atual() from public;
grant execute on function public.perfil_atual() to authenticated;

-- Normaliza e-mail e registra quem cadastrou
create or replace function public.tg_usuarios_normaliza()
returns trigger language plpgsql as $$
begin
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.criado_por := coalesce(nullif(public.email_atual(), ''), new.criado_por, 'sistema');
  end if;
  return new;
end $$;

drop trigger if exists usuarios_normaliza on public.usuarios;
create trigger usuarios_normaliza
  before insert or update on public.usuarios
  for each row execute function public.tg_usuarios_normaliza();

-- Impede que o sistema fique sem nenhum editor ativo
create or replace function public.tg_usuarios_um_editor()
returns trigger language plpgsql as $$
begin
  if not exists (select 1 from public.usuarios where perfil = 'editor' and ativo) then
    raise exception 'É preciso manter pelo menos um editor ativo.';
  end if;
  return null;
end $$;

drop trigger if exists usuarios_um_editor on public.usuarios;
create trigger usuarios_um_editor
  after update or delete on public.usuarios
  for each statement execute function public.tg_usuarios_um_editor();

-- ---------------------------------------------------------------------
-- 2. Outdoors
-- ---------------------------------------------------------------------
create table if not exists public.outdoors (
  id              uuid primary key default gen_random_uuid(),
  empresa         text not null,
  apelido         text not null,
  propaganda      text,
  endereco        text,
  cidade          text,
  latitude        double precision check (latitude between -90 and 90),
  longitude       double precision check (longitude between -180 and 180),
  data_inicio     date,
  vencimento      date,
  status          text not null check (status in
                    ('Ativo', 'Em andamento', 'Em licenciamento', 'Renovação', 'Em encerramento', 'Encerrado')),
  situacao_pmu    text check (situacao_pmu in
                    ('Protocolado', 'Tramitando', 'Indeferido', 'Baixado', 'Arquivado')),
  protocolo_pmu   text,
  numero_alvara   text,
  impedimentos    text,
  imagem_url      text,
  criado_em       timestamptz not null default now(),
  atualizado_em   timestamptz not null default now(),
  atualizado_por  text
);

create or replace function public.tg_carimbo()
returns trigger language plpgsql as $$
begin
  new.atualizado_em  := now();
  new.atualizado_por := coalesce(nullif(public.email_atual(), ''), new.atualizado_por, 'sistema');
  return new;
end $$;

drop trigger if exists outdoors_carimbo on public.outdoors;
create trigger outdoors_carimbo
  before insert or update on public.outdoors
  for each row execute function public.tg_carimbo();

-- ---------------------------------------------------------------------
-- 3. Histórico de andamentos (substitui a coluna "Observação")
-- ---------------------------------------------------------------------
create table if not exists public.andamentos (
  id          uuid primary key default gen_random_uuid(),
  outdoor_id  uuid not null references public.outdoors(id) on delete cascade,
  data        date not null default current_date,
  descricao   text not null,
  autor       text,
  criado_em   timestamptz not null default now()
);
create index if not exists andamentos_outdoor_idx on public.andamentos(outdoor_id);

create or replace function public.tg_andamento_autor()
returns trigger language plpgsql as $$
begin
  new.autor := coalesce(nullif(public.email_atual(), ''), new.autor, 'sistema');
  return new;
end $$;

drop trigger if exists andamentos_autor on public.andamentos;
create trigger andamentos_autor
  before insert on public.andamentos
  for each row execute function public.tg_andamento_autor();

-- ---------------------------------------------------------------------
-- 4. Registro de notificações enviadas (evita reenvio)
--    O vencimento faz parte da chave: ao renovar o alvará, o ciclo recomeça.
-- ---------------------------------------------------------------------
create table if not exists public.notificacoes_enviadas (
  id             bigint generated always as identity primary key,
  outdoor_id     uuid not null references public.outdoors(id) on delete cascade,
  usuario_email  text not null,
  marco          int  not null check (marco in (15, 10, 5)),
  vencimento     date not null,
  enviado_em     timestamptz not null default now(),
  unique (outdoor_id, usuario_email, marco, vencimento)
);

-- ---------------------------------------------------------------------
-- 5. Regras de acesso (Row Level Security)
--    Aplicadas no banco: valem mesmo fora da aplicação.
-- ---------------------------------------------------------------------
alter table public.usuarios              enable row level security;
alter table public.outdoors              enable row level security;
alter table public.andamentos            enable row level security;
alter table public.notificacoes_enviadas enable row level security;

drop policy if exists "ler outdoors" on public.outdoors;
drop policy if exists "editar outdoors" on public.outdoors;
create policy "ler outdoors" on public.outdoors
  for select to authenticated using (public.perfil_atual() is not null);
create policy "editar outdoors" on public.outdoors
  for all to authenticated
  using (public.perfil_atual() = 'editor') with check (public.perfil_atual() = 'editor');

drop policy if exists "ler andamentos" on public.andamentos;
drop policy if exists "editar andamentos" on public.andamentos;
create policy "ler andamentos" on public.andamentos
  for select to authenticated using (public.perfil_atual() is not null);
create policy "editar andamentos" on public.andamentos
  for all to authenticated
  using (public.perfil_atual() = 'editor') with check (public.perfil_atual() = 'editor');

drop policy if exists "ler usuarios" on public.usuarios;
drop policy if exists "gerenciar usuarios" on public.usuarios;
create policy "ler usuarios" on public.usuarios
  for select to authenticated using (public.perfil_atual() is not null);
create policy "gerenciar usuarios" on public.usuarios
  for all to authenticated
  using (public.perfil_atual() = 'editor') with check (public.perfil_atual() = 'editor');

drop policy if exists "ler notificacoes" on public.notificacoes_enviadas;
create policy "ler notificacoes" on public.notificacoes_enviadas
  for select to authenticated using (public.perfil_atual() is not null);
-- Gravação de notificações: somente o n8n (chave service_role, que ignora RLS)

-- ---------------------------------------------------------------------
-- 6. Alertas pendentes (lida pelo n8n todos os dias)
--    Faixas: 11-15 dias -> marco 15 | 6-10 -> marco 10 | 0-5 -> marco 5.
--    Em dia normal o alerta sai exatamente aos 15, 10 e 5 dias; se o n8n
--    ficar fora do ar num dia, o alerta daquela faixa sai no dia seguinte.
-- ---------------------------------------------------------------------
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
       f.vencimento, f.dias, f.marco, u.email, u.nome
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

-- ---------------------------------------------------------------------
-- 7. Imagens dos outdoors (Storage)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('outdoor-imagens', 'outdoor-imagens', true)
on conflict (id) do nothing;

drop policy if exists "editores enviam imagens" on storage.objects;
drop policy if exists "editores alteram imagens" on storage.objects;
drop policy if exists "editores removem imagens" on storage.objects;
create policy "editores enviam imagens" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'outdoor-imagens' and public.perfil_atual() = 'editor');
create policy "editores alteram imagens" on storage.objects
  for update to authenticated
  using (bucket_id = 'outdoor-imagens' and public.perfil_atual() = 'editor');
create policy "editores removem imagens" on storage.objects
  for delete to authenticated
  using (bucket_id = 'outdoor-imagens' and public.perfil_atual() = 'editor');

-- ---------------------------------------------------------------------
-- 8. Atualização em tempo real entre usuários
-- ---------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.outdoors;
exception when duplicate_object then null;
end $$;
