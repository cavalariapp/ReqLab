# ReqLab — Gestão de Pesquisa Equina

Plataforma para grupos de pesquisa em reprodução equina: delineamento de
experimentos, coleta de dados, análises estatísticas e cronograma.

**Projeto independente** — backend Supabase **próprio** (não compartilha banco
nem usuários com o Cavalar.IA). Frontend estático (HTML/CSS/JS), sem build.

## Status (fatia vertical 1)

| Tela | Estado |
|------|--------|
| **Dados** | ✅ ligada ao banco — lista coletas reais, formatação condicional dirigida pela config das variáveis, "+ Nova linha" grava no Supabase |
| **Análises** | ✅ ligada ao banco — média / desvio / CV por grupo, **ANOVA real** (F + p-valor via beta incompleta), taxa de ovulação por grupo, insight automático |
| Visão geral, Cronograma, Tarefas, Nova pesquisa | 🔶 ainda com dados de exemplo (mock) — próximas fases |

Sem `SUPABASE_URL`/`SUPABASE_KEY` preenchidos, a página funciona inteira em
**modo demonstração (mock)** — útil para ver o layout antes de criar o banco.

## Setup

1. **Crie um projeto novo no Supabase** (https://supabase.com) — dedicado ao
   ReqLab. **Não** use o projeto do Cavalar.IA.
2. No **SQL editor**, rode `sql/001_schema.sql`. Ele cria as tabelas, as
   políticas de segurança (RLS), os índices e uma **pesquisa de demonstração**
   já populada (3 grupos × 8 éguas, coleta D6).
3. Em `reqlab.html`, no topo do `<script>`, preencha:
   ```js
   var SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
   var SUPABASE_KEY = 'sua-anon-public-key';
   ```
   (Project Settings → API, no painel do Supabase.)
4. Sirva a pasta e abra `reqlab.html`:
   ```bash
   python3 -m http.server 8000
   # http://localhost:8000/reqlab.html
   ```

## Autenticação

Login por **código de e-mail (OTP)** via Supabase — botão **Entrar** no topo.
O primeiro login cria a conta automaticamente.

- A pesquisa de demonstração é de **leitura pública** (vê sem login).
- **Criar/editar** registros (ex.: "+ Nova linha") exige estar logado.

## Modelo de dados

`reqlab_pesquisas` → `reqlab_grupos`, `reqlab_variaveis`, `reqlab_animais`
→ `reqlab_coletas` → `reqlab_valores` (um valor por variável por coleta).
As colunas exibidas em **Dados** mapeiam variáveis pela `chave`
(`diam_folicular`, `progesterona`, `ovulacao`, `muco`).

## Próximas fases

- Telas Cronograma / Tarefas / Visão geral com dados reais
- Wizard **Nova pesquisa** gravando no banco (gera grupos, variáveis,
  cronograma e animais automaticamente)
- Gráfico de evolução multi-dia (D0…D8), testes t par-a-par, detecção de outliers
- Notificações/lembretes e sincronização orientador ↔ orientados
