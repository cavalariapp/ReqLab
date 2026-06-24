# ReqLab — Gestão de Pesquisa Equina

Plataforma para grupos de pesquisa em reprodução equina: delineamento de
experimentos, coleta de dados, análises estatísticas em tempo real e (em breve)
cronograma. App único `index.html` (HTML/CSS/JS, sem build) + backend **Supabase**.

## Como funciona

- **Login** por e-mail + senha. Sem autocadastro: o **orientador** cria as contas
  dentro do app (tela **Usuários**).
- **Papéis:** o orientador edita todos os experimentos e gerencia usuários; o
  orientado edita só o seu e vê os dos colegas em leitura (página **Pesquisas**).
- **Experimentos:** grupos, variáveis (com faixa esperada → cores) e tempos.
  Importa CSV ou preenche/edita direto no app. Análises automáticas (descritivas,
  ANOVA, evolução temporal, taxas, leitura em linguagem simples).

## Setup do banco (uma vez, no SQL editor do Supabase)

Rode, em ordem, o conteúdo de:
1. `sql/001_schema.sql` — tabelas, RLS e índices.
2. `sql/003_experimentos.sql` — coluna de tempos do experimento.
3. `sql/005_bootstrap_papeis.sql` — papéis (o 1º usuário vira orientador).

Se precisar promover sua conta manualmente: `sql/006_promover_orientador.sql`
(troque pelo seu e-mail). O `002` (limpar demo) e o `004` são opcionais/antigos.

## Criar usuários pelo app

A criação usa uma **Edge Function** (a chave de administrador fica só no servidor):
painel do Supabase → **Edge Functions** → *Deploy a new function* → nome
`criar-orientado` → cole `supabase/functions/criar-orientado/index.ts` → Deploy.

## Rodar local

```bash
python3 -m http.server 8000
# abra http://localhost:8000/
```

## Publicar (GitHub Pages)

Repositório → **Settings → Pages** → *Deploy from a branch* → `main` / `/ (root)`
→ Save. O app fica em `https://cavalariapp.github.io/ReqLab/`.

## Logos

Coloque em `assets/`: `logo-laboratorio.png` (dashboard/login) e
`icone-app.png` (ícone do WebApp, 512×512). Detalhes em `assets/LEIA-ME.md`.

## Modelo de dados

`reqlab_pesquisas` → `reqlab_grupos`, `reqlab_variaveis`, `reqlab_animais`
→ `reqlab_coletas` (uma por indivíduo×tempo) → `reqlab_valores`.
Papéis em `reqlab_perfis`. Modelo de planilha em `modelos/`.
