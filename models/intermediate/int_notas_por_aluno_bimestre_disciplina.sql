with

avaliacoes as (

    select
        id_aluno,
        bimestre,
        id_escola,
        bairro_escola,
        nota_portugues,
        nota_ciencias,
        nota_matematica

    from {{ ref('int_avaliacoes_por_aluno_bimestre') }}

),

alunos as (

    select
        id_aluno,
        faixa_etaria,
        ordem_faixa_etaria

    from {{ ref('stg_educacao__alunos') }}

),

-- Formato longo (tidy): uma linha por nota existente. O unpivot do
-- BigQuery exclui nulos por padrão, então ficam fora as notas não lançadas
-- e os pares com conflito de turma (notas nulas por construção).
-- Inglês fica fora: 100% nulo na fonte.
notas_desempilhadas as (

    select
        id_aluno,
        bimestre,
        id_escola,
        bairro_escola,
        disciplina,
        nota

    from avaliacoes
    unpivot (
        nota for disciplina in (
            nota_portugues as 'portugues',
            nota_ciencias as 'ciencias',
            nota_matematica as 'matematica'
        )
    )

),

-- Inner join: todo aluno avaliado existe na tabela aluno (testado na staging).
final as (

    select
        notas_desempilhadas.id_aluno,
        notas_desempilhadas.id_escola,
        notas_desempilhadas.bairro_escola,
        alunos.faixa_etaria,
        notas_desempilhadas.disciplina,
        notas_desempilhadas.bimestre,
        alunos.ordem_faixa_etaria,
        notas_desempilhadas.nota

    from notas_desempilhadas
    inner join alunos
        on notas_desempilhadas.id_aluno = alunos.id_aluno

)

select * from final
