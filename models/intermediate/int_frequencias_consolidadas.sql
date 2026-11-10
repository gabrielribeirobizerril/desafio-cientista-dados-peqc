with

frequencias as (
    select * from {{ ref('stg_educacao__frequencias') }}
),

consolidado as (
    select
        id_aluno,
        id_turma,
        id_escola,
        disciplina,
        nome_disciplina,
        data_inicio,
        data_fim,
        duracao_periodo_dias,

        if(count(distinct indice_frequencia_fonte) <= 1, max(indice_frequencia_fonte), null) as indice_frequencia_fonte,
        if(count(distinct faltas_por_dia_letivo) <= 1, max(faltas_por_dia_letivo), null) as faltas_por_dia_letivo,

        count(*) as qtd_linhas_origem,
        count(distinct indice_frequencia_fonte) > 1 as possui_conflito_frequencia

    from frequencias
    group by
        id_aluno, id_turma, id_escola, disciplina, nome_disciplina,
        data_inicio, data_fim, duracao_periodo_dias
),

final as (
    select
        *,
        qtd_linhas_origem > 1 as foi_consolidado
    from consolidado
)

select * from final