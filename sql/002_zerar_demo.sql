-- =====================================================================
-- ReqLab — zerar dados de demonstração (começar do zero)
-- Apaga a pesquisa DEMO e tudo que depende dela (grupos, variáveis,
-- animais, coletas, valores) por cascata. Não mexe nos seus usuários.
-- Rodar no SQL editor do Supabase.
-- =====================================================================

delete from reqlab_pesquisas where is_demo = true;

-- Conferência (deve voltar 0):
select count(*) as pesquisas_demo_restantes
from reqlab_pesquisas where is_demo = true;
