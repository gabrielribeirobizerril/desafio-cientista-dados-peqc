with

por_disciplina as (

    select
        id_aluno,
        id_escola,
        soma_faltas,
        soma_dias

    from {{ ref('int_frequencias_por_aluno_escola_disciplina') }}

),

-- Frequência global estimada do aluno na escola, nos períodos da fonte
-- (LDB: total das horas letivas). Soma faltas e dias de todas as disciplinas: cada disciplina pesa
-- pelos seus dias, sem média de médias. Premissa: as disciplinas têm a mesma
-- carga por dia (a fonte não informa aulas por disciplina).
-- Aluno em duas escolas tem uma linha em cada (vínculo aluno-escola); os
-- períodos em que esteve nas duas ao mesmo tempo já saíram do cálculo
-- (int_frequencias_por_aluno_escola_disciplina_periodo).
agregado as (

    select
        id_aluno,
        id_escola,
        count(*) as qtd_disciplinas,
        sum(soma_faltas) as soma_faltas,
        sum(soma_dias) as soma_dias

    from por_disciplina
    group by 1, 2

),

final as (

    select
        id_aluno,
        id_escola,
        qtd_disciplinas,
        soma_faltas,
        soma_dias,
        {{ percentual_frequencia('soma_faltas', 'soma_dias') }}
            as percentual_frequencia,
        {{ abaixo_da_frequencia_minima(
            percentual_frequencia('soma_faltas', 'soma_dias')
        ) }} as possui_absenteismo_cronico

    from agregado

)

select * from final
