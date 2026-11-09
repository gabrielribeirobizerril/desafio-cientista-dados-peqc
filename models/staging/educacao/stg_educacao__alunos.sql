with

origem as (

    select * from {{ source('educacao', 'aluno') }}

),

renomeado as (

    select
        -- ids
        {{ formatar_id_aluno('id_aluno') }} as id_aluno,
        cast(id_turma as string) as id_turma,

        -- categorias
        faixa_etaria,
        cast(bairro as string) as bairro_residencia,

        -- ordem das faixas etárias (a ordem alfabética coloca "11-14" antes de "6-10")
        case faixa_etaria
            when '0-5' then 1
            when '6-10' then 2
            when '11-14' then 3
            when '15-17' then 4
            when '18+' then 5
        end as ordem_faixa_etaria

    from origem

)

select * from renomeado