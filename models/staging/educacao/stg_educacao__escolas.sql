with

origem as (

    select * from {{ source('educacao', 'escola') }}

),

renomeado as (

    select
        -- ids
        cast(id_escola as string) as id_escola,

        -- categorias
        cast(bairro as string) as bairro_escola

    from origem

)

select * from renomeado