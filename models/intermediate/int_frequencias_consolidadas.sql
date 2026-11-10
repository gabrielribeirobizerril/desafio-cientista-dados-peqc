with

frequencias as (

    select * from {{ ref('stg_educacao__frequencias') }}

),

-- Uma linha por aluno + turma + disciplina + período. Mesma regra de
-- consolidação de int_avaliacoes_consolidadas (macros consolidar_valor e
-- possui_conflito). id_escola, nome_disciplina e duracao_periodo_dias
-- dependem da chave, então agrupar por elas não cria grupos novos.
-- faltas_por_dia_letivo é consolidada, não recalculada: a fórmula mora só
-- na staging.
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

        {{ consolidar_valor('indice_frequencia_fonte') }} as indice_frequencia_fonte,
        {{ consolidar_valor('faltas_por_dia_letivo') }} as faltas_por_dia_letivo,

        count(*) as qtd_linhas_origem,
        {{ possui_conflito('indice_frequencia_fonte') }} as possui_conflito_frequencia

    from frequencias
    group by
        id_aluno, id_turma, id_escola, disciplina, nome_disciplina,
        data_inicio, data_fim, duracao_periodo_dias

),

final as (

    select
        id_aluno,
        id_turma,
        id_escola,
        disciplina,
        nome_disciplina,
        data_inicio,
        data_fim,
        duracao_periodo_dias,
        indice_frequencia_fonte,
        faltas_por_dia_letivo,
        qtd_linhas_origem,
        qtd_linhas_origem > 1 as foi_consolidado,
        possui_conflito_frequencia

    from consolidado

)

select * from final
