-- Regra de negócio: as duas fontes do vínculo aluno -> turma final
-- (stg_educacao__alunos e stg_educacao__turmas) devem concordar.
-- Devolve os alunos com turmas diferentes ou presentes em só uma das tabelas.

with

alunos as (

    select id_aluno, id_turma from {{ ref('stg_educacao__alunos') }}

),

turmas as (

    select id_aluno, id_turma from {{ ref('stg_educacao__turmas') }}

),

comparacao as (

    select
        coalesce(alunos.id_aluno, turmas.id_aluno) as id_aluno,
        alunos.id_turma as id_turma_em_alunos,
        turmas.id_turma as id_turma_em_turmas

    from alunos
    full outer join turmas
        on alunos.id_aluno = turmas.id_aluno

)

select * from comparacao
where
    id_turma_em_alunos is null
    or id_turma_em_turmas is null
    or id_turma_em_alunos != id_turma_em_turmas