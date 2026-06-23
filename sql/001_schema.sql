-- =====================================================================
-- ReqLab — esquema base (fatia vertical: Dados + Análises com dados reais)
-- Tabelas: pesquisas, grupos, variáveis, animais, coletas, valores.
-- Inclui RLS, índices e seed de uma pesquisa DEMO pública.
-- Idempotente: pode rodar mais de uma vez sem duplicar.
-- Rodar no SQL editor do Supabase.
-- =====================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------- tabelas
create table if not exists reqlab_pesquisas (
  id            uuid primary key default gen_random_uuid(),
  owner         uuid references auth.users(id) on delete cascade,
  titulo        text not null,
  linha         text,
  nivel         text,
  objetivo      text,
  data_inicio   date,
  intervalo_dias int  default 2,
  n_coletas     int  default 5,
  is_demo       boolean not null default false,
  created_at    timestamptz not null default now()
);

create table if not exists reqlab_grupos (
  id          uuid primary key default gen_random_uuid(),
  pesquisa_id uuid not null references reqlab_pesquisas(id) on delete cascade,
  nome        text not null,
  cor         text default '#94a3b8',
  ordem       int  default 0
);

create table if not exists reqlab_variaveis (
  id          uuid primary key default gen_random_uuid(),
  pesquisa_id uuid not null references reqlab_pesquisas(id) on delete cascade,
  chave       text,                        -- slug estável: diam_folicular, progesterona, ovulacao, muco
  nome        text not null,
  tipo        text default 'numerico',     -- numerico | booleano | categorico
  unidade     text,
  faixa_min   numeric,                      -- faixa esperada (normal)
  faixa_max   numeric,
  cond_format boolean default false,        -- formatação condicional ligada?
  ordem       int default 0
);

create table if not exists reqlab_animais (
  id            uuid primary key default gen_random_uuid(),
  pesquisa_id   uuid not null references reqlab_pesquisas(id) on delete cascade,
  grupo_id      uuid references reqlab_grupos(id) on delete set null,
  identificador text not null,              -- "Égua 01"
  ordem         int default 0
);

create table if not exists reqlab_coletas (
  id          uuid primary key default gen_random_uuid(),
  pesquisa_id uuid not null references reqlab_pesquisas(id) on delete cascade,
  animal_id   uuid not null references reqlab_animais(id) on delete cascade,
  dia         text not null,                -- D0, D2, D4, D6...
  data        date,
  created_at  timestamptz not null default now()
);

create table if not exists reqlab_valores (
  id          uuid primary key default gen_random_uuid(),
  coleta_id   uuid not null references reqlab_coletas(id) on delete cascade,
  variavel_id uuid not null references reqlab_variaveis(id) on delete cascade,
  valor_num   numeric,
  valor_bool  boolean,
  valor_texto text,
  unique (coleta_id, variavel_id)
);

-- ----------------------------------------------------------- índices
create index if not exists idx_reqlab_grupos_pesq   on reqlab_grupos(pesquisa_id);
create index if not exists idx_reqlab_vars_pesq      on reqlab_variaveis(pesquisa_id);
create index if not exists idx_reqlab_animais_pesq   on reqlab_animais(pesquisa_id);
create index if not exists idx_reqlab_animais_grupo  on reqlab_animais(grupo_id);
create index if not exists idx_reqlab_coletas_pesq   on reqlab_coletas(pesquisa_id);
create index if not exists idx_reqlab_coletas_animal on reqlab_coletas(animal_id);
create index if not exists idx_reqlab_valores_coleta on reqlab_valores(coleta_id);
create index if not exists idx_reqlab_valores_var    on reqlab_valores(variavel_id);

-- --------------------------------------------------- helpers de acesso
create or replace function reqlab_pode_ver(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from reqlab_pesquisas x
    where x.id = p and (x.is_demo or x.owner = auth.uid())
  );
$$;

create or replace function reqlab_pode_editar(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from reqlab_pesquisas x
    where x.id = p and (x.owner = auth.uid() or (x.is_demo and auth.uid() is not null))
  );
$$;

-- ----------------------------------------------------------- RLS
alter table reqlab_pesquisas enable row level security;
alter table reqlab_grupos    enable row level security;
alter table reqlab_variaveis enable row level security;
alter table reqlab_animais   enable row level security;
alter table reqlab_coletas   enable row level security;
alter table reqlab_valores   enable row level security;

-- pesquisas
drop policy if exists reqlab_pesq_sel on reqlab_pesquisas;
create policy reqlab_pesq_sel on reqlab_pesquisas for select to anon, authenticated
  using (is_demo or owner = auth.uid());
drop policy if exists reqlab_pesq_ins on reqlab_pesquisas;
create policy reqlab_pesq_ins on reqlab_pesquisas for insert to authenticated
  with check (owner = auth.uid());
drop policy if exists reqlab_pesq_upd on reqlab_pesquisas;
create policy reqlab_pesq_upd on reqlab_pesquisas for update to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());
drop policy if exists reqlab_pesq_del on reqlab_pesquisas;
create policy reqlab_pesq_del on reqlab_pesquisas for delete to authenticated
  using (owner = auth.uid());

-- tabelas-filhas com pesquisa_id direto (grupos, variaveis, animais, coletas)
do $$
declare t text;
begin
  foreach t in array array['reqlab_grupos','reqlab_variaveis','reqlab_animais','reqlab_coletas'] loop
    execute format('drop policy if exists %I on %I', t||'_sel', t);
    execute format('create policy %I on %I for select to anon, authenticated using (reqlab_pode_ver(pesquisa_id))', t||'_sel', t);
    execute format('drop policy if exists %I on %I', t||'_w', t);
    execute format('create policy %I on %I for all to authenticated using (reqlab_pode_editar(pesquisa_id)) with check (reqlab_pode_editar(pesquisa_id))', t||'_w', t);
  end loop;
end $$;

-- valores (acesso via coleta -> pesquisa)
drop policy if exists reqlab_valores_sel on reqlab_valores;
create policy reqlab_valores_sel on reqlab_valores for select to anon, authenticated
  using (exists (select 1 from reqlab_coletas c where c.id = coleta_id and reqlab_pode_ver(c.pesquisa_id)));
drop policy if exists reqlab_valores_w on reqlab_valores;
create policy reqlab_valores_w on reqlab_valores for all to authenticated
  using (exists (select 1 from reqlab_coletas c where c.id = coleta_id and reqlab_pode_editar(c.pesquisa_id)))
  with check (exists (select 1 from reqlab_coletas c where c.id = coleta_id and reqlab_pode_editar(c.pesquisa_id)));

-- ----------------------------------------------------------- grants
grant usage on schema public to anon, authenticated;
grant select on reqlab_pesquisas, reqlab_grupos, reqlab_variaveis, reqlab_animais, reqlab_coletas, reqlab_valores to anon, authenticated;
grant insert, update, delete on reqlab_pesquisas, reqlab_grupos, reqlab_variaveis, reqlab_animais, reqlab_coletas, reqlab_valores to authenticated;
grant execute on function reqlab_pode_ver(uuid), reqlab_pode_editar(uuid) to anon, authenticated;

-- ----------------------------------------------- seed: pesquisa DEMO
create or replace function reqlab__seed_grupo(
  p_pid uuid, p_gid uuid, p_vdiam uuid, p_vprog uuid, p_vovul uuid,
  p_diam numeric[], p_prog numeric[], p_ovul boolean[], p_start int
) returns void language plpgsql as $$
declare i int; aid uuid; cid uuid;
begin
  for i in 1..array_length(p_diam,1) loop
    insert into reqlab_animais (pesquisa_id, grupo_id, identificador, ordem)
      values (p_pid, p_gid, 'Égua ' || lpad((p_start+i-1)::text, 2, '0'), p_start+i-1)
      returning id into aid;
    insert into reqlab_coletas (pesquisa_id, animal_id, dia, data)
      values (p_pid, aid, 'D6', date '2026-06-23') returning id into cid;
    insert into reqlab_valores (coleta_id, variavel_id, valor_num)  values (cid, p_vdiam, p_diam[i]);
    insert into reqlab_valores (coleta_id, variavel_id, valor_num)  values (cid, p_vprog, p_prog[i]);
    insert into reqlab_valores (coleta_id, variavel_id, valor_bool) values (cid, p_vovul, p_ovul[i]);
  end loop;
end $$;

do $$
declare
  pid uuid;
  g_ctrl uuid; g_ecg uuid; g_gnrh uuid;
  v_diam uuid; v_prog uuid; v_ovul uuid; v_muco uuid;
begin
  select id into pid from reqlab_pesquisas
    where is_demo and titulo = 'Efeito de eCG e GnRH na dinâmica folicular de éguas' limit 1;

  if pid is null then
    insert into reqlab_pesquisas (owner, titulo, linha, nivel, objetivo, data_inicio, intervalo_dias, n_coletas, is_demo)
    values (null, 'Efeito de eCG e GnRH na dinâmica folicular de éguas',
            'Reprodução · Endocrinologia', 'Doutorado',
            'Comparar a dinâmica folicular e a taxa de ovulação entre protocolos hormonais (eCG, GnRH) e controle.',
            date '2026-06-17', 2, 5, true)
    returning id into pid;

    insert into reqlab_grupos (pesquisa_id, nome, cor, ordem) values (pid,'Controle','#94a3b8',0) returning id into g_ctrl;
    insert into reqlab_grupos (pesquisa_id, nome, cor, ordem) values (pid,'eCG','#2f63d6',1)      returning id into g_ecg;
    insert into reqlab_grupos (pesquisa_id, nome, cor, ordem) values (pid,'GnRH','#1f9d6b',2)     returning id into g_gnrh;

    insert into reqlab_variaveis (pesquisa_id, chave, nome, tipo, unidade, faixa_min, faixa_max, cond_format, ordem)
      values (pid,'diam_folicular','Diâmetro folicular','numerico','mm',25,40,true,0) returning id into v_diam;
    insert into reqlab_variaveis (pesquisa_id, chave, nome, tipo, unidade, faixa_min, faixa_max, cond_format, ordem)
      values (pid,'progesterona','Progesterona','numerico','ng/mL',1,4,true,1) returning id into v_prog;
    insert into reqlab_variaveis (pesquisa_id, chave, nome, tipo, unidade, cond_format, ordem)
      values (pid,'ovulacao','Ovulação','booleano','—',false,2) returning id into v_ovul;
    insert into reqlab_variaveis (pesquisa_id, chave, nome, tipo, unidade, cond_format, ordem)
      values (pid,'muco','Escore de muco','categorico','1–5',false,3) returning id into v_muco;

    perform reqlab__seed_grupo(pid, g_ctrl, v_diam, v_prog, v_ovul,
      array[22.0,23.6,21.3,24.9,25.8,26.1,23.0,22.7],
      array[1.2,1.5,0.8,1.4,1.9,2.1,1.3,1.1],
      array[false,true,false,true,true,false,true,true], 1);

    perform reqlab__seed_grupo(pid, g_ecg, v_diam, v_prog, v_ovul,
      array[34.2,41.8,45.1,38.9,33.5,36.0,29.8,31.2],
      array[3.1,6.4,9.2,4.7,3.8,5.0,2.9,3.4],
      array[true,true,true,true,true,true,false,true], 9);

    perform reqlab__seed_grupo(pid, g_gnrh, v_diam, v_prog, v_ovul,
      array[30.5,31.7,28.9,33.0,29.4,32.1,30.0,34.2],
      array[2.8,3.0,2.5,3.3,2.7,3.1,2.9,3.6],
      array[true,true,false,true,true,true,false,true], 17);
  end if;
end $$;

drop function if exists reqlab__seed_grupo(uuid,uuid,uuid,uuid,uuid,numeric[],numeric[],boolean[],int);

-- Conferência rápida:
-- select g.nome, count(*) n, round(avg(v.valor_num),1) media
-- from reqlab_valores v
-- join reqlab_variaveis va on va.id=v.variavel_id and va.chave='diam_folicular'
-- join reqlab_coletas c on c.id=v.coleta_id
-- join reqlab_animais a on a.id=c.animal_id
-- join reqlab_grupos g on g.id=a.grupo_id
-- group by g.nome order by g.nome;
