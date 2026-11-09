with

origem as (

    select * from {{ source('educacao', 'turma') }}

),

renomeado as (

    select
        -- ids
        {{ formatar_id_aluno('id_aluno') }} as id_aluno,
        cast(id_turma as string) as id_turma,

        -- ano letivo anonimizado pelo produtor (constante: 2000)
        ano as ano_letivo

    from origem

)

select * from renomeado