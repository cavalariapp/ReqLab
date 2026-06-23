# Modelo de planilha para importar dados (CSV)

Abra `modelo_importacao.csv` no Excel/Google Sheets, troque pelos seus dados e
salve como CSV. Depois é só importar pelo botão **Importar CSV** na tela **Dados**.

## Como a planilha é organizada

Cada **linha** = um indivíduo num momento. As **3 primeiras colunas são fixas
(obrigatórias)**; depois vem **uma coluna para cada variável**.

| Coluna | O que é | Exemplo |
|--------|---------|---------|
| `grupo` | Grupo do experimento | Controle, eCG |
| `individuo` | Identificação do animal | Égua 01 |
| `tempo` | Momento da coleta | T0, T30, T60, D6… |
| *(daqui pra frente)* | **Uma coluna por variável** | Peso (kg), Progesterona (ng/mL)… |

As variáveis tanto podem ser **características do animal** (idade, raça, peso)
quanto **dados coletados** (folículo, progesterona, ovulação). Não precisa
separar — é só colocar cada uma numa coluna.

## Regras simples

- **Unidade** vai entre parênteses no título: `Peso (kg)`, `Progesterona (ng/mL)`.
- **Números:** use ponto para decimais (`22.5`), não vírgula.
- **Sim/Não** (ex.: Ovulação): escreva `sim` / `não`.
- **Não mediu** algo naquele tempo? Deixe a célula **em branco**.
- Repita as características (idade, raça…) em cada linha do animal, ou preencha
  só na linha `T0` — tanto faz.

## Exemplo

Mesma égua medida em dois tempos = duas linhas:

```
grupo,individuo,tempo,Peso (kg),Diâmetro folicular (mm),Ovulação
eCG,Égua 09,T0,450,34.2,não
eCG,Égua 09,T30,448,41.8,sim
```
