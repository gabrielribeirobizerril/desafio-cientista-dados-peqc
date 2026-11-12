with

periodos as (

    select
        id_aluno,
        id_escola,
        disciplina,
        duracao_periodo_dias,
        faltas_por_dia_letivo

    from {{ ref('int_frequencias_por_aluno_escola_disciplina_periodo') }}
    -- nulo = turma sem valor, soma acima de 1 ou aluno em mais de uma
    -- escola no período; o período fica fora do numerador e do denominador
    where faltas_por_dia_letivo is not null

),

-- Frequência ESTIMADA do aluno na escola e na disciplina, nos períodos que a
-- fonte traz (2000-02-05 a 2000-10-03, concentrados até 2000-07-17).
-- Cada período entra uma vez, com as faltas de todas as turmas do aluno nele
-- (regra em int_frequencias_por_aluno_escola_disciplina_periodo).
-- Premissas: (1) faltas e dias letivos da fonte estão na mesma unidade;
-- (2) a duração do período (dias corridos) aproxima os dias letivos.
-- O vínculo aluno -> turma desta fonte não corresponde ao da tabela aluno:
-- nunca ligar este model a alunos ou avaliações.
agregado as (

    select
        id_aluno,
        id_escola,
        disciplina,
        count(*) as qtd_periodos,
        sum(faltas_por_dia_letivo * duracao_periodo_dias) as soma_faltas,
        sum(duracao_periodo_dias) as soma_dias

    from periodos
    group by 1, 2, 3

),

final as (

    select
        id_aluno,
        id_escola,
        disciplina,
        qtd_periodos,
        soma_faltas,
        soma_dias,
        {{ percentual_frequencia('soma_faltas', 'soma_dias') }}
            as percentual_frequencia,
        {{ abaixo_da_frequencia_minima(
            percentual_frequencia('soma_faltas', 'soma_dias')
        ) }} as possui_absenteismo_cronico

    from agregado

)

select * from final
