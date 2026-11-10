with

atribuicoes_com_mudanca as (
    select
        id_aluno,
        bimestre,
        id_turma_atribuida
    from {{ ref('int_avaliacoes_por_aluno_bimestre') }}
    where mudou_turma_no_bimestre
        and not turma_indeterminada
),

turmas_finais as (
    select
        id_aluno,
        id_turma as id_turma_final
    from {{ ref('stg_educacao__turmas') }}
)

select
    atribuicoes_com_mudanca.id_aluno,
    atribuicoes_com_mudanca.bimestre,
    atribuicoes_com_mudanca.id_turma_atribuida,
    turmas_finais.id_turma_final
from atribuicoes_com_mudanca
left join turmas_finais
    on atribuicoes_com_mudanca.id_aluno = turmas_finais.id_aluno
where turmas_finais.id_turma_final is null
    or atribuicoes_com_mudanca.id_turma_atribuida != turmas_finais.id_turma_final