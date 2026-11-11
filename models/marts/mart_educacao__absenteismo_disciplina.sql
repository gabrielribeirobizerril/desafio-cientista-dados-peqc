with

vinculos_disciplina as (

    select
        disciplina,
        percentual_frequencia,
        possui_absenteismo_cronico

    from {{ ref('int_frequencias_por_aluno_escola_disciplina') }}

),

-- Uma linha por disciplina. Unidade: vínculo aluno-escola na disciplina.
-- A frequência por disciplina é um recorte do projeto; a LDB define o
-- mínimo sobre o total das horas letivas (ver mart por escola).
final as (

    select
        disciplina,
        count(*) as qtd_vinculos_aluno_escola,
        countif(possui_absenteismo_cronico)
            as qtd_vinculos_absenteismo_cronico,
        safe_divide(countif(possui_absenteismo_cronico), count(*))
            as taxa_absenteismo_cronico,
        avg(percentual_frequencia) as media_percentual_frequencia

    from vinculos_disciplina
    group by 1

)

select * from final
