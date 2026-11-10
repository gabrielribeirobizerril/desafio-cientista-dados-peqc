-- Reconciliação entre camadas: os pares aluno + bimestre do modelo por aluno
-- devem ser exatamente os pares de int_avaliacoes_consolidadas.
-- Retorna os pares que existem em só um dos lados.

with

pares_origem as (

    select distinct
        id_aluno,
        bimestre

    from {{ ref('int_avaliacoes_consolidadas') }}

),

pares_modelo as (

    select
        id_aluno,
        bimestre

    from {{ ref('int_avaliacoes_por_aluno_bimestre') }}

)

select
    coalesce(pares_origem.id_aluno, pares_modelo.id_aluno) as id_aluno,
    coalesce(pares_origem.bimestre, pares_modelo.bimestre) as bimestre,
    pares_origem.id_aluno is null as so_no_modelo,
    pares_modelo.id_aluno is null as so_na_origem

from pares_origem
full outer join pares_modelo
    on pares_origem.id_aluno = pares_modelo.id_aluno
    and pares_origem.bimestre = pares_modelo.bimestre

where
    pares_origem.id_aluno is null
    or pares_modelo.id_aluno is null
