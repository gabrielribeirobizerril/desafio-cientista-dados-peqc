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

consolidado as (
    select
        id_aluno,
        id_turma,
        bimestre,

        if(count(distinct percentual_frequencia_bimestre) <= 1, max(percentual_frequencia_bimestre), null) as percentual_frequencia_bimestre,
        if(count(distinct nota_portugues) <= 1, max(nota_portugues), null) as nota_portugues,
        if(count(distinct nota_ciencias) <= 1, max(nota_ciencias), null) as nota_ciencias,
        if(count(distinct nota_ingles) <= 1, max(nota_ingles), null) as nota_ingles,
        if(count(distinct nota_matematica) <= 1, max(nota_matematica), null) as nota_matematica,

        count(*) as qtd_linhas_origem,
        count(distinct percentual_frequencia_bimestre) > 1 as possui_conflito_frequencia,
        (
            count(distinct nota_portugues) > 1
            or count(distinct nota_ciencias) > 1
            or count(distinct nota_matematica) > 1
        ) as possui_conflito_nota

    from avaliacoes
    group by id_aluno, id_turma, bimestre
),

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