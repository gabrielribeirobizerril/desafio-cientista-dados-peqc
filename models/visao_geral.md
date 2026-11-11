{% docs __overview__ %}

# RMI Educação — visão geral

Projeto dbt sobre os dados educacionais anonimizados do RMI. As camadas são
staging → intermediate → marts.

**Onde ver a linhagem**

- **Grafo interativo:** clique no ícone azul no canto inferior direito, ou
  abra qualquer modelo e use "View Lineage Graph". O grafo é gerado pelo dbt a
  partir das chamadas `ref()` e `source()`; os últimos nós são as
  *exposures*, as entregas que consomem o projeto (o relatório de resultados
  e o notebook de análise exploratória).
- **Diagrama com o número de linhas:** a figura abaixo mostra o mesmo fluxo,
  com a contagem de linhas de cada tabela na carga atual (clique para ampliar).

[![Linhagem com o número de linhas por etapa](assets/linhagem.svg)](assets/linhagem.svg)

O dicionário de dados de cada tabela está na página do modelo (descrição,
colunas, tipos e testes). As mesmas descrições são gravadas no BigQuery pelo
`persist_docs`.

## Linhagem e número de linhas por etapa

Contagens da carga atual, geradas por `analyses/contagem_linhas_por_etapa.sql`
(`dbt show -s contagem_linhas_por_etapa --limit 50`).

### Avaliação (desempenho)

| Etapa | Tabela | Linhas | O que muda |
|---|---|---|---|
| source | `avaliacao` | 221.687 | — |
| staging | `stg_educacao__avaliacoes` | 221.684 | remove 3 linhas idênticas |
| intermediate | `int_avaliacoes_consolidadas` | 221.653 | consolida 31 chaves duplicadas (aluno + turma + bimestre), com uma flag de conflito por disciplina |
| intermediate | `int_avaliacoes_por_aluno_bimestre` | 221.106 | uma turma por aluno + bimestre (538 pares em várias turmas; 283 sem atribuição) |
| intermediate | `int_notas_por_aluno_bimestre_disciplina` | 558.039 | unpivot: uma linha por nota existente |
| marts | `mart_educacao__desempenho_escola` | 1.425 | 475 escolas × 3 disciplinas |
| marts | `mart_educacao__desempenho_bairro` | 402 | 134 bairros × 3 disciplinas |
| marts | `mart_educacao__desempenho_faixa_etaria` | 9 | 3 faixas com nota × 3 disciplinas |

### Frequência (absenteísmo)

| Etapa | Tabela | Linhas | O que muda |
|---|---|---|---|
| source | `frequencia` | 2.727.684 | — |
| staging | `stg_educacao__frequencias` | 2.724.344 | remove linhas idênticas e registros abaixo de 99 (nulos são mantidos) |
| intermediate | `int_frequencias_consolidadas` | 2.723.254 | consolida 1.090 chaves duplicadas |
| intermediate | `int_frequencias_por_aluno_escola_disciplina_periodo` | 2.687.455 | junta as turmas do aluno no mesmo período e na mesma escola (faltas somadas, duração uma vez); deixa sem valor os períodos compartilhados entre escolas |
| intermediate | `int_frequencias_por_aluno_escola_disciplina` | 396.095 | agrega os períodos por aluno + escola + disciplina |
| intermediate | `int_frequencias_por_aluno_escola` | 99.032 | agrega as disciplinas por vínculo aluno–escola |
| marts | `mart_educacao__absenteismo_escola` | 521 | uma linha por escola |
| marts | `mart_educacao__absenteismo_bairro` | 135 | uma linha por bairro |
| marts | `mart_educacao__absenteismo_disciplina` | 4 | uma linha por disciplina |

### Aluno, turma, escola e mapa

| Etapa | Tabela | Linhas | O que muda |
|---|---|---|---|
| source → staging | `aluno` → `stg_educacao__alunos` | 97.044 | 1:1 |
| source → staging | `turma` → `stg_educacao__turmas` | 97.044 | 1:1 (uma linha por aluno) |
| source → staging | `escola` → `stg_educacao__escolas` | 1.558 | 1:1 |
| intermediate | `int_turmas_mapeadas_para_escolas` | 5.516 | uma linha por turma da frequência (521 escolas) |

## Análises

- `analyses/contagem_linhas_por_etapa.sql`: contagens desta página.
- `analyses/sensibilidade_regras_frequencia.sql`: absenteísmo crônico com e
  sem a exclusão dos registros abaixo de 99 e com e sem a junção das turmas
  do mesmo período
  (`dbt show -s sensibilidade_regras_frequencia`).

{% enddocs %}
