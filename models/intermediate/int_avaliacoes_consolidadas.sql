with

avaliacoes as (

    select * from {{ ref('stg_educacao__avaliacoes') }}

),

turmas_finais as (

    select
        id_aluno,
        id_turma as id_turma_final

    from {{ ref('stg_educacao__turmas') }}

),

mapa as (

    select * from {{ ref('int_turmas_mapeadas_para_escolas') }}

),

-- Uma linha por aluno + turma + bimestre. Regra de consolidação nas macros
-- consolidar_valor e possui_conflito. nota_ingles fica fora do conflito de
-- notas por ser 100% nula.
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
        (
            {{ possui_conflito('nota_portugues') }}
            or {{ possui_conflito('nota_ciencias') }}
            or {{ possui_conflito('nota_matematica') }}
        ) as possui_conflito_nota

    from avaliacoes
    group by id_aluno, id_turma, bimestre

),

-- Left joins: turmas fora do mapa ficam com escola nula (cobertura ~81%),
-- sem perder a avaliação.
final as (

    select
        consolidado.id_aluno,
        consolidado.id_turma,
        mapa.id_escola,
        mapa.bairro_escola,
        turmas_finais.id_turma_final,
        consolidado.bimestre,
        consolidado.percentual_frequencia_bimestre,
        consolidado.nota_portugues,
        consolidado.nota_ciencias,
        consolidado.nota_ingles,
        consolidado.nota_matematica,
        consolidado.qtd_linhas_origem,
        consolidado.qtd_linhas_origem > 1 as foi_consolidado,
        consolidado.possui_conflito_nota,
        consolidado.possui_conflito_frequencia,
        consolidado.id_turma = turmas_finais.id_turma_final as eh_turma_final

    from consolidado
    left join mapa
        on consolidado.id_turma = mapa.id_turma
    left join turmas_finais
        on consolidado.id_aluno = turmas_finais.id_aluno

)

select * from final
