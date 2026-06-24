-- =====================================================================
-- ReqLab — inscrições de notificação push (1 por aparelho)
-- Idempotente. Rodar no SQL editor do Supabase.
-- =====================================================================

create table if not exists reqlab_push_subs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  endpoint     text not null unique,
  subscription jsonb not null,
  created_at   timestamptz not null default now()
);
alter table reqlab_push_subs enable row level security;
create index if not exists idx_reqlab_push_user on reqlab_push_subs(user_id);

-- cada usuário gerencia as suas inscrições; o envio usa service_role (ignora RLS)
drop policy if exists reqlab_push_sel on reqlab_push_subs;
create policy reqlab_push_sel on reqlab_push_subs for select to authenticated using (user_id = auth.uid());
drop policy if exists reqlab_push_ins on reqlab_push_subs;
create policy reqlab_push_ins on reqlab_push_subs for insert to authenticated with check (user_id = auth.uid());
drop policy if exists reqlab_push_upd on reqlab_push_subs;
create policy reqlab_push_upd on reqlab_push_subs for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists reqlab_push_del on reqlab_push_subs;
create policy reqlab_push_del on reqlab_push_subs for delete to authenticated using (user_id = auth.uid());

grant select, insert, update, delete on reqlab_push_subs to authenticated;
