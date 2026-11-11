with

frequencias as (

    select
        id_aluno,
        id_escola,
        nome_disciplina,
        data_inicio,
        data_fim,
        duracao_periodo_dias,
        faltas_por_dia_letivo

    from {{ ref('int_frequencias_consolidadas') }}

),

-- Uma linha por aluno + escola + disciplina + período, juntando as turmas do
-- aluno naquele período na mesma escola (mudança de turma no meio do período).
-- Regra: as frações de falta das turmas são SOMADAS e a duração do período
-- conta UMA vez. Evidência (diagnóstico de 2026-11-11, grupos com alguma
-- falta): nos períodos com 2+ turmas, a fração por turma é cerca de metade da
-- dos períodos com 1 turma (0,109 x 0,214) e a soma das turmas é igual
-- (0,219 x 0,214). Ou seja, cada turma registra só as faltas dos dias em que
-- o aluno esteve nela, sobre os dias letivos do período inteiro.
-- Ficam fora do cálculo (fração nula), com flag:
-- (1) período com alguma turma em conflito (fração nula na consolidação):
--     sem a fração de uma das turmas, as faltas seriam subestimadas;
-- (2) período em que a soma das turmas passa de 1: mais faltas que dias
--     letivos, o que viola a regra de cálculo da fonte (mesmo critério dos
--     registros abaixo de 99, excluídos na staging);
-- (3) período em que o aluno aparece em mais de uma escola (mudança de
--     escola no meio do período): a fonte não informa quantos dias o aluno
--     ficou em cada escola, então não há como atribuir a duração a cada
--     vínculo sem inventar uma divisão. O período sai dos dois vínculos.
agregado as (

    select
        id_aluno,
        id_escola,
        nome_disciplina as disciplina,
        data_inicio,
        data_fim,
        duracao_periodo_dias,
        count(*) as qtd_turmas,
        countif(faltas_por_dia_letivo is null) as qtd_turmas_sem_valor,
        sum(faltas_por_dia_letivo) as soma_fracoes_turmas

    from frequencias
    group by 1, 2, 3, 4, 5, 6

),

-- Escolas do aluno em cada disciplina e período (regra 3). Conta todas as
-- linhas, inclusive as sem valor: se a outra escola está em conflito, o
-- período continua sem atribuição possível.
escolas_no_periodo as (

    select
        id_aluno,
        disciplina,
        data_inicio,
        data_fim,
        count(distinct id_escola) as qtd_escolas_no_periodo

    from agregado
    group by 1, 2, 3, 4

),

final as (

    select
        agregado.id_aluno,
        agregado.id_escola,
        agregado.disciplina,
        agregado.data_inicio,
        agregado.data_fim,
        agregado.duracao_periodo_dias,
        agregado.qtd_turmas,
        escolas_no_periodo.qtd_escolas_no_periodo,
        agregado.qtd_turmas > 1 as possui_multiplas_turmas_no_periodo,
        escolas_no_periodo.qtd_escolas_no_periodo > 1 as possui_multiplas_escolas_no_periodo,
        agregado.qtd_turmas_sem_valor > 0 as possui_turma_sem_valor,
        coalesce(agregado.soma_fracoes_turmas > 1, false) as possui_faltas_acima_do_periodo,
        if(
            agregado.qtd_turmas_sem_valor = 0
            and agregado.soma_fracoes_turmas <= 1
            and escolas_no_periodo.qtd_escolas_no_periodo = 1,
            agregado.soma_fracoes_turmas,
            null
        ) as faltas_por_dia_letivo

    from agregado
    inner join escolas_no_periodo
        on agregado.id_aluno = escolas_no_periodo.id_aluno
        and agregado.disciplina = escolas_no_periodo.disciplina
        and agregado.data_inicio = escolas_no_periodo.data_inicio
        and agregado.data_fim = escolas_no_periodo.data_fim

)

select * from final
