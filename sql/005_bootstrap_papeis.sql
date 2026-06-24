-- =====================================================================
-- ReqLab — papéis robustos (substitui/complementa o 004)
--  • cria a tabela de perfis e as regras de acesso (idempotente)
--  • o PRIMEIRO usuário do sistema vira ORIENTADOR automaticamente
--  • novos usuários ganham perfil automaticamente (orientado)
-- Pode rodar mesmo que o 004 já tenha sido rodado.
-- Rodar no SQL editor do Supabase.
-- =====================================================================

create table if not exists reqlab_perfis (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nome       text,
  papel      text not null default 'orientado',
  created_at timestamptz not null default now()
);
alter table reqlab_perfis enable row level security;

create or replace function reqlab_eh_orientador()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_perfis where user_id = auth.uid() and papel = 'orientador');
$$;

create or replace function reqlab_pode_ver(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_pesquisas x where x.id = p and (x.is_demo or auth.uid() is not null));
$$;

create or replace function reqlab_pode_editar(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from reqlab_pesquisas x where x.id = p and (x.owner = auth.uid() or reqlab_eh_orientador()));
$$;

drop policy if exists reqlab_perfis_sel on reqlab_perfis;
create policy reqlab_perfis_sel on reqlab_perfis for select to authenticated using (true);

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

-- novo usuário -> perfil automático; se ainda não existe nenhum orientador, este vira orientador
create or replace function reqlab_novo_perfil()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into reqlab_perfis (user_id, nome, papel)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', new.email),
          case when not exists (select 1 from reqlab_perfis where papel = 'orientador') then 'orientador' else 'orientado' end)
  on conflict (user_id) do nothing;
  return new;
end $$;
drop trigger if exists reqlab_on_auth_user on auth.users;
create trigger reqlab_on_auth_user after insert on auth.users
  for each row execute function reqlab_novo_perfil();

-- perfis para quem já existe
insert into reqlab_perfis (user_id, nome, papel)
  select id, coalesce(raw_user_meta_data->>'name', email), 'orientado'
  from auth.users
on conflict (user_id) do nothing;

-- se ninguém é orientador ainda, promove o PRIMEIRO usuário (quem montou o sistema)
update reqlab_perfis set papel = 'orientador'
  where user_id = (select id from auth.users order by created_at asc limit 1)
    and not exists (select 1 from reqlab_perfis where papel = 'orientador');

-- conferência: deve listar ao menos 1 orientador
select papel, count(*) from reqlab_perfis group by papel;
