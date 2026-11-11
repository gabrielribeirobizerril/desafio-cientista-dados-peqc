with

notas as (

    select * from {{ ref('int_notas_por_aluno_bimestre_disciplina') }}

),

-- Uma linha por faixa etária + disciplina (formato tidy).
-- Unidade: a nota do aluno no bimestre na disciplina; média sobre as notas
-- existentes (aluno com mais bimestres avaliados pesa mais).
-- Inclui notas de turmas fora do mapa turma -> escola (a faixa etária
-- não depende da escola).
final as (

    select
        faixa_etaria,
        ordem_faixa_etaria,
        disciplina,
        count(distinct id_aluno) as qtd_alunos,
        count(*) as qtd_notas,
        sum(nota) as soma_notas,
        avg(nota) as media_nota,
        stddev_samp(nota) as desvio_padrao_nota

    from notas
    group by 1, 2, 3

)

select * from final
