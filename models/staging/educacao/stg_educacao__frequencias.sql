with

origem as (

    select * from {{ source('educacao', 'frequencia') }}

),

-- Remove linhas idênticas (macro remover_linhas_identicas, aplicada em
-- todas as stagings): 1.483 no perfilamento. Chaves com valores
-- conflitantes são tratadas na intermediate.
deduplicado as (

    {{ remover_linhas_identicas('origem') }}

),

-- Regra de cálculo da fonte (schema.yml do produtor): frequencia =
-- 100 - (faltas / dias letivos). Abaixo de 99, as faltas passariam do número
-- de dias letivos. Esses registros (1.857; 0,07%) são excluídos.
-- Nulos são mantidos como nulos (ausência de informação, não registro
-- inválido) e monitorados na source; a intermediate os exclui do cálculo de
-- forma explícita.
-- Coluna qualificada pela CTE: no GoogleSQL, "frequencia" sozinho pode ser
-- lido como a linha inteira de uma tabela com o mesmo nome.
filtrado as (

    select * from deduplicado
    where
        deduplicado.frequencia >= 99
        or deduplicado.frequencia is null

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
        -- Não é percentual de presença: vai de 99 a 100 depois do filtro.
        frequencia as indice_frequencia_fonte,
        100 - frequencia as faltas_por_dia_letivo,

        -- período de apuração (ano anonimizado para 2000; dia e mês preservados)
        safe.parse_date('%Y-%m-%d', data_inicio) as data_inicio,
        safe.parse_date('%Y-%m-%d', data_fim) as data_fim

    from filtrado

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