with

avaliacoes as (

    select * from {{ ref('stg_educacao__avaliacoes') }}

),

mapa as (

    select * from {{ ref('int_turmas_mapeadas_para_escolas') }}

),

-- Uma linha por aluno + turma + bimestre. Regra de consolidação nas macros
-- consolidar_valor e possui_conflito, com uma flag de conflito por disciplina
-- (permite testar cada nota). nota_ingles fica fora do conflito de notas por
-- ser 100% nula.
consolidado as (

    select
        id_aluno,
        id_turma,
        bimestre,

        {{ consolidar_valor('percentual_frequencia_bimestre') }} as percentual_frequencia_bimestre,
        {{ consolidar_valor('nota_portugues') }} as nota_portugues,
        {{ consolidar_valor('nota_ciencias') }} as nota_ciencias,
        {{ consolidar_valor('nota_ingles') }} as nota_ingles,
        {{ consolidar_valor('nota_matematica') }} as nota_matematica,

        count(*) as qtd_linhas_origem,
        {{ possui_conflito('percentual_frequencia_bimestre') }} as possui_conflito_frequencia,
        {{ possui_conflito('nota_portugues') }} as possui_conflito_nota_portugues,
        {{ possui_conflito('nota_ciencias') }} as possui_conflito_nota_ciencias,
        {{ possui_conflito('nota_matematica') }} as possui_conflito_nota_matematica

    from avaliacoes
    group by id_aluno, id_turma, bimestre

),

-- Left join: turmas fora do mapa ficam com escola nula (cobertura ~81% das
-- linhas), sem perder a avaliação.
final as (

    select
        consolidado.id_aluno,
        consolidado.id_turma,
        mapa.id_escola,
        mapa.bairro_escola,
        consolidado.bimestre,
        consolidado.percentual_frequencia_bimestre,
        consolidado.nota_portugues,
        consolidado.nota_ciencias,
        consolidado.nota_ingles,
        consolidado.nota_matematica,
        consolidado.qtd_linhas_origem,
        consolidado.qtd_linhas_origem > 1 as foi_consolidado,
        (
            consolidado.possui_conflito_nota_portugues
            or consolidado.possui_conflito_nota_ciencias
            or consolidado.possui_conflito_nota_matematica
        ) as possui_conflito_nota,
        consolidado.possui_conflito_nota_portugues,
        consolidado.possui_conflito_nota_ciencias,
        consolidado.possui_conflito_nota_matematica,
        consolidado.possui_conflito_frequencia

    from consolidado
    left join mapa
        on consolidado.id_turma = mapa.id_turma

)

select * from final
