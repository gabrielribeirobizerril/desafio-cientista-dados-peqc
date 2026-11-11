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

-- Unidade: vínculo aluno-escola. Um aluno em duas escolas do mesmo bairro
-- conta duas vezes, coerente com o mart por escola (os totais reconciliam).
-- Recalculado a partir dos vínculos, não como média das taxas das escolas.
final as (

    select
        escolas.bairro_escola,
        count(distinct vinculos.id_escola) as qtd_escolas,
        count(*) as qtd_vinculos_aluno_escola,
        countif(vinculos.possui_absenteismo_cronico)
            as qtd_vinculos_absenteismo_cronico,
        safe_divide(
            countif(vinculos.possui_absenteismo_cronico),
            count(*)
        ) as taxa_absenteismo_cronico,
        avg(vinculos.percentual_frequencia) as media_percentual_frequencia

    from vinculos
    inner join escolas
        on vinculos.id_escola = escolas.id_escola
    group by 1

)

select * from final
