with

vinculos as (

    select
        id_escola,
        percentual_frequencia,
        possui_absenteismo_cronico

    from {{ ref('int_frequencias_por_aluno_escola') }}

),

escolas as (

    select
        id_escola,
        bairro_escola

    from {{ ref('stg_educacao__escolas') }}

),

-- Agrega antes do join. Unidade: o aluno na escola (vínculo aluno-escola).
-- Frequência estimada nos períodos da fonte (2000-02-05 a 2000-10-03,
-- concentrados até 2000-07-17).
por_escola as (

    select
        id_escola,
        count(*) as qtd_alunos,
        countif(possui_absenteismo_cronico) as qtd_alunos_absenteismo_cronico,
        avg(percentual_frequencia) as media_percentual_frequencia

    from vinculos
    group by 1

),

-- Inner join: id_escola da frequência tem relationships com escolas na
-- staging.
final as (

    select
        por_escola.id_escola,
        escolas.bairro_escola,
        por_escola.qtd_alunos,
        por_escola.qtd_alunos_absenteismo_cronico,
        safe_divide(
            por_escola.qtd_alunos_absenteismo_cronico,
            por_escola.qtd_alunos
        ) as taxa_absenteismo_cronico,
        por_escola.media_percentual_frequencia

    from por_escola
    inner join escolas
        on por_escola.id_escola = escolas.id_escola

)

select * from final
