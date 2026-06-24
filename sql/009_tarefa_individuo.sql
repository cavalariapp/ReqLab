-- =====================================================================
-- ReqLab — liga a tarefa de coleta a um indivíduo (animal)
-- Assim a coleta é marcada "feita" quando AQUELE indivíduo tem dados no tempo.
-- Idempotente. Rodar no SQL editor do Supabase.
-- =====================================================================

alter table reqlab_tarefas
  add column if not exists animal_id uuid references reqlab_animais(id) on delete cascade;

create index if not exists idx_reqlab_tarefas_animal on reqlab_tarefas(animal_id);
