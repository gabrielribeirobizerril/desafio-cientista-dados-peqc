with

notas as (

    select * from {{ ref('int_notas_por_aluno_bimestre_disciplina') }}

),

-- Uma linha por escola + disciplina (formato tidy).
-- Unidade: a nota do aluno no bimestre na disciplina; média sobre as notas
-- existentes (aluno com mais bimestres avaliados pesa mais).
-- Notas de turmas fora do mapa turma -> escola ficam fora (cobertura
-- documentada no YAML).
final as (

    select
        id_escola,
        bairro_escola,
        disciplina,
        count(distinct id_aluno) as qtd_alunos,
        count(*) as qtd_notas,
        sum(nota) as soma_notas,
        avg(nota) as media_nota,
        stddev_samp(nota) as desvio_padrao_nota

    from notas
    where id_escola is not null
    group by 1, 2, 3

)

select * from final
