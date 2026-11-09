with

origem as (

    select * from {{ source('educacao', 'frequencia') }}

),

-- Remove apenas linhas idênticas em todas as colunas (1.483 no perfilamento).
-- Chaves com valores conflitantes são tratadas na intermediate.
deduplicado as (

    select distinct * from origem

),

renomeado as (

    select
        -- ids
        {{ formatar_id_aluno('id_aluno') }} as id_aluno,
        cast(id_turma as string) as id_turma,
        cast(id_escola as string) as id_escola,

        -- categorias
        disciplina,
        case disciplina
            when 'disciplina_1' then 'portugues'
            when 'disciplina_2' then 'ciencias'
            when 'disciplina_3' then 'ingles'
            when 'disciplina_4' then 'matematica'
        end as nome_disciplina,

        -- índice calculado pela fonte: 100 - (faltas / dias letivos), sem o fator 100.
        -- Não é percentual de presença (valores entre 97,3 e 100).
        frequencia as indice_frequencia_fonte,
        100 - frequencia as faltas_por_dia_letivo,

        -- período de apuração (ano anonimizado para 2000; dia e mês preservados)
        safe.parse_date('%Y-%m-%d', data_inicio) as data_inicio,
        safe.parse_date('%Y-%m-%d', data_fim) as data_fim

    from deduplicado

),

final as (

    select
        id_aluno,
        id_turma,
        id_escola,
        disciplina,
        nome_disciplina,
        indice_frequencia_fonte,
        faltas_por_dia_letivo,
        -- duração inclusiva do período, base da ponderação
        date_diff(data_fim, data_inicio, day) + 1 as duracao_periodo_dias,
        data_inicio,
        data_fim

    from renomeado

)

select * from final