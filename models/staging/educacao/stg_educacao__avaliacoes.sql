with

origem as (

    select * from {{ source('educacao', 'avaliacao') }}

),

-- Remove linhas idênticas (macro remover_linhas_identicas, aplicada em
-- todas as stagings): 3 no perfilamento. Chaves com valores conflitantes
-- são tratadas na intermediate.
deduplicado as (

    {{ remover_linhas_identicas('origem') }}

),

renomeado as (

    select
        -- chaves
        {{ formatar_id_aluno('id_aluno') }} as id_aluno,
        cast(id_turma as string) as id_turma,
        safe_cast(bimestre as int64) as bimestre,

        -- frequência geral do aluno no bimestre (0 a 100)
        frequencia as percentual_frequencia_bimestre,

        -- notas de 0 a 10, com ruído de ±0,2 aplicado na anonimização
        disciplina_1 as nota_portugues,
        disciplina_2 as nota_ciencias,
        disciplina_3 as nota_ingles,  -- 100% nula na carga atual
        disciplina_4 as nota_matematica

    from deduplicado

)

select * from renomeado