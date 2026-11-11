-- Reconciliação entre camadas: o unpivot de
-- int_notas_por_aluno_bimestre_disciplina deve ter exatamente uma linha para
-- cada nota não nula de int_avaliacoes_por_aluno_bimestre (Português,
-- Ciências e Matemática). Garante que os marts de desempenho partem de todas
-- as notas atribuídas, nem mais nem menos.

with

esperado as (

    select
        countif(nota_portugues is not null)
        + countif(nota_ciencias is not null)
        + countif(nota_matematica is not null) as qtd_notas

    from {{ ref('int_avaliacoes_por_aluno_bimestre') }}

),

observado as (

    select count(*) as qtd_notas
    from {{ ref('int_notas_por_aluno_bimestre_disciplina') }}

)

select
    esperado.qtd_notas as qtd_esperada,
    observado.qtd_notas as qtd_observada

from esperado
cross join observado

where
    esperado.qtd_notas != observado.qtd_notas
    or esperado.qtd_notas = 0
