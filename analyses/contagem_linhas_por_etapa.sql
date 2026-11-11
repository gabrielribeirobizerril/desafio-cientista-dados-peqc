{#
    Número de linhas de cada tabela em cada etapa (source, staging,
    intermediate, marts). Alimenta a tabela da página inicial do dbt docs
    (models/visao_geral.md).

    Uso:
      dbt show -s contagem_linhas_por_etapa --limit 50
#}

{% set fontes = ['aluno', 'turma', 'escola', 'frequencia', 'avaliacao'] %}

{% set modelos = {
    '2_staging': [
        'stg_educacao__alunos',
        'stg_educacao__turmas',
        'stg_educacao__escolas',
        'stg_educacao__frequencias',
        'stg_educacao__avaliacoes',
    ],
    '3_intermediate': [
        'int_turmas_mapeadas_para_escolas',
        'int_avaliacoes_consolidadas',
        'int_avaliacoes_por_aluno_bimestre',
        'int_notas_por_aluno_bimestre_disciplina',
        'int_frequencias_consolidadas',
        'int_frequencias_por_aluno_escola_disciplina_periodo',
        'int_frequencias_por_aluno_escola_disciplina',
        'int_frequencias_por_aluno_escola',
    ],
    '4_marts': [
        'mart_educacao__desempenho_escola',
        'mart_educacao__desempenho_bairro',
        'mart_educacao__desempenho_faixa_etaria',
        'mart_educacao__absenteismo_escola',
        'mart_educacao__absenteismo_bairro',
        'mart_educacao__absenteismo_disciplina',
    ],
} %}

with

contagens as (

    {% for fonte in fontes %}
    select
        '1_source' as etapa,
        '{{ fonte }}' as tabela,
        count(*) as qtd_linhas

    from {{ source('educacao', fonte) }}

    union all
    {% endfor %}

    {% for etapa, lista in modelos.items() %}
    {% set ultima_etapa = loop.last %}
    {% for modelo in lista %}
    select
        '{{ etapa }}' as etapa,
        '{{ modelo }}' as tabela,
        count(*) as qtd_linhas

    from {{ ref(modelo) }}

    {% if not (ultima_etapa and loop.last) %}union all{% endif %}
    {% endfor %}
    {% endfor %}

)

select * from contagens
order by etapa, tabela
