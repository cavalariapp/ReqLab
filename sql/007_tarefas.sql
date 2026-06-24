-- =====================================================================
-- ReqLab — tarefas / cronograma
--  tipos: coleta | aula | entrega | congresso | outro
--  tarefas de 'coleta' geradas pelo planejador (auto=true) são marcadas
--  "feita" automaticamente quando há dados no tempo correspondente.
-- Idempotente. Rodar no SQL editor do Supabase (depois do 005).
-- =====================================================================

create table if not exists reqlab_tarefas (
  id          uuid primary key default gen_random_uuid(),
  pesquisa_id uuid references reqlab_pesquisas(id) on delete cascade,
  owner       uuid references auth.users(id) on delete cascade,   -- de quem é a tarefa
  criado_por  uuid references auth.users(id) on delete set null,
  tipo        text not null default 'coleta',
  titulo      text not null,
  data        date,
  tempo       text,                       -- para coletas: T0, T30...
  status      text not null default 'pendente',  -- pendente | feita
  auto        boolean not null default false,    -- gerada pelo planejador
  created_at  timestamptz not null default now()
);
alter table reqlab_tarefas enable row level security;
create index if not exists idx_reqlab_tarefas_owner on reqlab_tarefas(owner);
create index if not exists idx_reqlab_tarefas_pesq  on reqlab_tarefas(pesquisa_id);

drop policy if exists reqlab_tarefas_sel on reqlab_tarefas;
create policy reqlab_tarefas_sel on reqlab_tarefas for select to authenticated
  using (owner = auth.uid() or criado_por = auth.uid() or reqlab_eh_orientador());
drop policy if exists reqlab_tarefas_ins on reqlab_tarefas;
create policy reqlab_tarefas_ins on reqlab_tarefas for insert to authenticated
  with check (criado_por = auth.uid());
drop policy if exists reqlab_tarefas_upd on reqlab_tarefas;
create policy reqlab_tarefas_upd on reqlab_tarefas for update to authenticated
  using (owner = auth.uid() or criado_por = auth.uid() or reqlab_eh_orientador())
  with check (owner = auth.uid() or criado_por = auth.uid() or reqlab_eh_orientador());
drop policy if exists reqlab_tarefas_del on reqlab_tarefas;
create policy reqlab_tarefas_del on reqlab_tarefas for delete to authenticated
  using (owner = auth.uid() or criado_por = auth.uid() or reqlab_eh_orientador());

grant select, insert, update, delete on reqlab_tarefas to authenticated;
