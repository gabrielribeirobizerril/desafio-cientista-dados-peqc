with

origem as (

    select * from {{ source('educacao', 'escola') }}

),

-- Remove linhas idênticas (macro remover_linhas_identicas, aplicada em
-- todas as stagings).
deduplicado as (

    {{ remover_linhas_identicas('origem') }}

),

renomeado as (

    select
        -- ids
        cast(id_escola as string) as id_escola,

        -- categorias
        cast(bairro as string) as bairro_escola

    from deduplicado

)

select * from renomeado