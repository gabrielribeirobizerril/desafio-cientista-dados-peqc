with

avaliacoes as (

    select
        *,
        -- nota_ingles fica fora por ser 100% nula
        (
            nota_portugues is not null
            or nota_ciencias is not null
            or nota_matematica is not null
        ) as possui_nota

    from {{ ref('int_avaliacoes_consolidadas') }}

),

-- Turmas candidatas de cada aluno + bimestre.
candidatas as (

    select
        id_aluno,
        bimestre,
        count(*) as qtd_turmas_no_bimestre,
        countif(possui_nota) as qtd_turmas_com_nota,
        countif(percentual_frequencia_bimestre is not null) as qtd_turmas_com_frequencia,
        any_value(id_turma) as id_turma_qualquer,
        -- só usada quando exatamente uma candidata tem nota
        max(if(possui_nota, id_turma, null)) as id_turma_com_nota,
        -- só usada quando nenhuma tem nota e exatamente uma tem frequência
        max(if(percentual_frequencia_bimestre is not null, id_turma, null)) as id_turma_com_frequencia

    from avaliacoes
    group by id_aluno, bimestre

),

-- Regra de atribuição. Único lugar onde ela existe.
-- Só se atribui turma quando há uma única turma candidata:
--   (1) turma única; ou
--   (2) várias turmas, mas só uma com nota; ou
--   (3) nenhuma turma com nota e só uma com frequência.
-- Hierarquia: a nota define a turma (onde o aluno fez prova é onde ele
-- estava); a frequência acompanha essa turma e só desempata sem nota.
-- Nos demais casos (inclusive várias turmas sem nota nem frequência),
-- possui_conflito_turma = true e a turma fica nula.
-- Nunca se calcula média entre turmas.
atribuicao as (

    select
        id_aluno,
        bimestre,
        qtd_turmas_no_bimestre,
        qtd_turmas_com_nota,
        qtd_turmas_com_frequencia,
        case
            when qtd_turmas_no_bimestre = 1 then id_turma_qualquer
            when qtd_turmas_com_nota = 1 then id_turma_com_nota
            when qtd_turmas_com_nota = 0 and qtd_turmas_com_frequencia = 1
                then id_turma_com_frequencia
        end as id_turma_atribuida

    from candidatas

),

-- Left join pela chave completa (única em int_avaliacoes_consolidadas):
-- não duplica e mantém os pares sem turma atribuída.
final as (

    select
        atribuicao.id_aluno,
        atribuicao.bimestre,
        atribuicao.id_turma_atribuida,
        atribuicao.id_turma_atribuida is null as possui_conflito_turma,
        avaliacoes.id_escola,
        avaliacoes.bairro_escola,
        avaliacoes.percentual_frequencia_bimestre,
        avaliacoes.nota_portugues,
        avaliacoes.nota_ciencias,
        avaliacoes.nota_ingles,
        avaliacoes.nota_matematica,
        atribuicao.qtd_turmas_no_bimestre,
        atribuicao.qtd_turmas_com_nota,
        atribuicao.qtd_turmas_com_frequencia,
        atribuicao.qtd_turmas_no_bimestre > 1 as possui_multiplas_turmas_no_bimestre

    from atribuicao
    left join avaliacoes
        on atribuicao.id_aluno = avaliacoes.id_aluno
        and atribuicao.bimestre = avaliacoes.bimestre
        and atribuicao.id_turma_atribuida = avaliacoes.id_turma

)

select * from final
