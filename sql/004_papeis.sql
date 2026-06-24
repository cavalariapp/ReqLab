-- =====================================================================
-- ReqLab — papéis (orientador / orientado) e acesso multiusuário
--  • orientado: edita só os SEUS experimentos; LÊ todos (página Pesquisas)
--  • orientador: edita TODOS os experimentos
-- Idempotente. Rodar no SQL editor do Supabase.
-- =====================================================================

create table if not exists reqlab_perfis (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nome       text,
  papel      text not null default 'orientado',   -- 'orientador' | 'orientado'
  created_at timestamptz not null default now()
);
alter table reqlab_perfis enable row level security;

-- quem é orientador?
create or replace function reqlab_eh_orientador()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_perfis where user_id = auth.uid() and papel = 'orientador');
$$;

-- leitura: qualquer usuário logado vê todos os experimentos
create or replace function reqlab_pode_ver(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_pesquisas x where x.id = p and (x.is_demo or auth.uid() is not null));
$$;

-- edição: o dono OU o orientador
create or replace function reqlab_pode_editar(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_pesquisas x where x.id = p and (x.owner = auth.uid() or reqlab_eh_orientador()));
$$;

-- perfis: todo logado pode ler (para mostrar nomes/donos); escrita só via service_role (Edge Function)
drop policy if exists reqlab_perfis_sel on reqlab_perfis;
create policy reqlab_perfis_sel on reqlab_perfis for select to authenticated using (true);

-- pesquisas: select para qualquer logado; update/delete do dono ou do orientador
drop policy if exists reqlab_pesq_sel on reqlab_pesquisas;
create policy reqlab_pesq_sel on reqlab_pesquisas for select to anon, authenticated
  using (is_demo or auth.uid() is not null);
drop policy if exists reqlab_pesq_upd on reqlab_pesquisas;
create policy reqlab_pesq_upd on reqlab_pesquisas for update to authenticated
  using (owner = auth.uid() or reqlab_eh_orientador()) with check (owner = auth.uid() or reqlab_eh_orientador());
drop policy if exists reqlab_pesq_del on reqlab_pesquisas;
create policy reqlab_pesq_del on reqlab_pesquisas for delete to authenticated
  using (owner = auth.uid() or reqlab_eh_orientador());

grant select on reqlab_perfis to authenticated;
grant execute on function reqlab_eh_orientador() to anon, authenticated;

-- cria perfil para quem já existe; define a admin como orientadora
insert into reqlab_perfis (user_id, nome, papel)
  select id, coalesce(raw_user_meta_data->>'name', email),
         case when email = 'epona.perinatologia@gmail.com' then 'orientador' else 'orientado' end
  from auth.users
on conflict (user_id) do nothing;

update reqlab_perfis set papel = 'orientador'
  where user_id = (select id from auth.users where email = 'epona.perinatologia@gmail.com');
