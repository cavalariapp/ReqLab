-- =====================================================================
-- ReqLab — reaplica as permissões (RLS) da tabela de tarefas
-- Use se "criar tarefa" não estiver funcionando. Idempotente.
-- Rodar no SQL editor do Supabase.
-- =====================================================================

alter table reqlab_tarefas enable row level security;

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

-- recarrega o cache da API
notify pgrst, 'reload schema';

-- confere as políticas (devem aparecer 4 linhas)
select policyname, cmd from pg_policies where tablename = 'reqlab_tarefas' order by policyname;
