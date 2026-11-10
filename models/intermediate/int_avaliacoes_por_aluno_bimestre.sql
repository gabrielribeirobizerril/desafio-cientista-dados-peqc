with

avaliacoes as (
    select * from {{ ref('int_avaliacoes_consolidadas') }}
),

atribuicao as (
    select
        id_aluno,
        bimestre,
        count(*) as qtd_turmas_no_bimestre,
        if(
            count(*) = 1,
            any_value(id_turma),
            max(if(eh_turma_final, id_turma, null))
        ) as id_turma_atribuida
    from avaliacoes
    group by id_aluno, bimestre
),

final as (
    select
        atribuicao.id_aluno,
        atribuicao.bimestre,
        atribuicao.id_turma_atribuida,
        avaliacoes.id_escola,
        avaliacoes.bairro_escola,
        avaliacoes.percentual_frequencia_bimestre,
        avaliacoes.nota_portugues,
        avaliacoes.nota_ciencias,
        avaliacoes.nota_ingles,
        avaliacoes.nota_matematica,
        atribuicao.qtd_turmas_no_bimestre,
        atribuicao.qtd_turmas_no_bimestre > 1 as mudou_turma_no_bimestre,
        atribuicao.id_turma_atribuida is null as turma_indeterminada
    from atribuicao
    left join avaliacoes
        on atribuicao.id_aluno = avaliacoes.id_aluno
        and atribuicao.bimestre = avaliacoes.bimestre
        and atribuicao.id_turma_atribuida = avaliacoes.id_turma
)

select * from final