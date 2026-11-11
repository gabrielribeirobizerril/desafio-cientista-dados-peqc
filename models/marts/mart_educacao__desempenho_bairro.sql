with

notas as (

    select * from {{ ref('int_notas_por_aluno_bimestre_disciplina') }}

),

-- Uma linha por bairro + disciplina (formato tidy).
-- Unidade: a nota do aluno no bimestre na disciplina; média sobre as notas
-- existentes (aluno com mais bimestres avaliados pesa mais).
-- Recalculado a partir das notas, não como média das escolas.
final as (

    select
        bairro_escola,
        disciplina,
        count(distinct id_escola) as qtd_escolas,
        count(distinct id_aluno) as qtd_alunos,
        count(*) as qtd_notas,
        sum(nota) as soma_notas,
        avg(nota) as media_nota,
        stddev_samp(nota) as desvio_padrao_nota

    from notas
    where bairro_escola is not null
    group by 1, 2

)

select * from final
