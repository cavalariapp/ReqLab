-- =====================================================================
-- ReqLab — suporte a criação de experimentos pelo app
-- Guarda os "tempos" planejados (T0, T30...) na própria pesquisa, para
-- sugerir a tabela e os campos de coleta antes de existir qualquer dado.
-- Idempotente. Rodar no SQL editor do Supabase.
-- =====================================================================

alter table reqlab_pesquisas add column if not exists tempos text;
