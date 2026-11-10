with

-- A escola de cada turma vem da frequência (única tabela com id_escola).
-- Cada turma pertence a uma única escola (testado na staging).
frequencias as (

    select distinct
        id_turma,
        id_escola

    from {{ ref('stg_educacao__frequencias') }}

),

escolas as (

    select * from {{ ref('stg_educacao__escolas') }}

),

-- Left join: uma escola ausente do cadastro não elimina a turma do mapa
-- (o teste not_null de bairro_escola acusa o caso).
turmas_com_escola as (

    select
        frequencias.id_turma,
        frequencias.id_escola,
        escolas.bairro_escola

    from frequencias
    left join escolas
        on frequencias.id_escola = escolas.id_escola

)

select * from turmas_com_escola
