-- =====================================================================
-- ReqLab — promover uma conta a ORIENTADOR pelo e-mail de login
-- Troque o e-mail abaixo pelo e-mail que VOCÊ usa para entrar no app.
-- Rodar no SQL editor do Supabase. (Pré-requisito: ter rodado o 005.)
-- =====================================================================

-- 1) garante que existe perfil para essa conta
insert into reqlab_perfis (user_id, nome, papel)
  select id, coalesce(raw_user_meta_data->>'name', email), 'orientado'
  from auth.users
  where email = 'TROQUE_PELO_SEU_EMAIL@exemplo.com'
on conflict (user_id) do nothing;

-- 2) promove a orientador
update reqlab_perfis set papel = 'orientador'
  where user_id = (select id from auth.users where email = 'TROQUE_PELO_SEU_EMAIL@exemplo.com');

-- 3) confere (papel deve aparecer como 'orientador')
select u.email, p.papel
from reqlab_perfis p join auth.users u on u.id = p.user_id
order by p.papel;
