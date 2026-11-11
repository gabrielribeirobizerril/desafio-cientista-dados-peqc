{#
    Sensibilidade do absenteísmo crônico (frequência estimada abaixo de 75%)
    a três regras do projeto:
      1. exclusão dos registros de frequência abaixo de 99, que pela regra de
         cálculo da fonte indicariam mais faltas que dias letivos;
      2. junção das turmas do aluno no mesmo período e na mesma escola
         (faltas das turmas somadas, duração do período contada uma vez);
      3. exclusão dos períodos em que o aluno aparece em mais de uma escola
         (não há como atribuir a duração a cada vínculo).

    Recalcula o indicador global (vínculo aluno-escola) em quatro cenários,
    cada um desligando uma regra:
      regra_adotada: as três regras, como nos marts (deve bater com
        int_frequencias_por_aluno_escola);
      mantem_abaixo_de_99: sem a regra 1 (registros abaixo de 99 mantidos com
        o valor original; por coerência, a soma das turmas acima de 1, que é
        o mesmo tipo de valor impossível, também é mantida);
      duracao_por_turma: sem a regra 2 (cada turma soma a duração inteira do
        período, como numa versão anterior do projeto);
      duracao_inteira_em_cada_escola: sem a regra 3 (o período compartilhado
        entra em cada escola com a duração inteira, como numa versão anterior
        do projeto).
    Reaproveita as macros do projeto (remoção de linhas idênticas,
    consolidação, percentual e limite de 75%). As regras 2 e 3 são
    reproduzidas aqui, e não lidas do modelo, porque cada cenário precisa
    desligar uma delas; o cenário regra_adotada confere que a reprodução bate
    com int_frequencias_por_aluno_escola.

    Uso:
      dbt show -s sensibilidade_regras_frequencia
#}

with

origem as (

    select * from {{ source('educacao', 'frequencia') }}

),

deduplicado as (

    {{ remover_linhas_identicas('origem') }}

),

registros as (

    select
        {{ formatar_id_aluno('id_aluno') }} as id_aluno,
        cast(id_turma as string) as id_turma,
        cast(id_escola as string) as id_escola,
        disciplina,
        safe.parse_date('%Y-%m-%d', data_inicio) as data_inicio,
        safe.parse_date('%Y-%m-%d', data_fim) as data_fim,
        deduplicado.frequencia as indice

    from deduplicado

),

cenarios as (

    select 'regra_adotada' as cenario, *
    from registros
    where indice >= 99 or indice is null

    union all

    select 'mantem_abaixo_de_99' as cenario, *
    from registros

    union all

    select 'duracao_por_turma' as cenario, *
    from registros
    where indice >= 99 or indice is null

    union all

    select 'duracao_inteira_em_cada_escola' as cenario, *
    from registros
    where indice >= 99 or indice is null

),

-- Mesma consolidação da intermediate (chave aluno + turma + disciplina +
-- período; valores divergentes viram nulo).
consolidado as (

    select
        cenario,
        id_aluno,
        id_escola,
        disciplina,
        data_inicio,
        date_diff(data_fim, data_inicio, day) + 1 as duracao_periodo_dias,
        100 - {{ consolidar_valor('indice') }} as faltas_por_dia_letivo

    from cenarios
    group by cenario, id_aluno, id_turma, id_escola, disciplina, data_inicio, data_fim

),

-- Regra 2, como em int_frequencias_por_aluno_escola_disciplina_periodo:
-- turmas do mesmo período juntadas (frações somadas, duração uma vez; período
-- com turma em conflito ou com soma acima de 1 fica fora; a soma acima de 1
-- só é mantida no cenário mantem_abaixo_de_99). No cenário
-- duracao_por_turma, cada turma segue como uma linha, com a duração inteira.
periodos as (

    select
        cenario,
        id_aluno,
        id_escola,
        disciplina,
        data_inicio,
        duracao_periodo_dias,
        if(
            countif(faltas_por_dia_letivo is null) = 0
            and (cenario = 'mantem_abaixo_de_99' or sum(faltas_por_dia_letivo) <= 1),
            sum(faltas_por_dia_letivo),
            null
        ) as faltas_por_dia_letivo

    from consolidado
    where cenario != 'duracao_por_turma'
    group by cenario, id_aluno, id_escola, disciplina, data_inicio, duracao_periodo_dias

    union all

    select
        cenario,
        id_aluno,
        id_escola,
        disciplina,
        data_inicio,
        duracao_periodo_dias,
        faltas_por_dia_letivo

    from consolidado
    where cenario = 'duracao_por_turma'

),

-- Regra 3, como em int_frequencias_por_aluno_escola_disciplina_periodo:
-- período em que o aluno aparece em mais de uma escola fica fora (nas duas).
-- Desligada no cenário duracao_inteira_em_cada_escola.
escolas_no_periodo as (

    select
        cenario,
        id_aluno,
        disciplina,
        data_inicio,
        duracao_periodo_dias,
        count(distinct id_escola) as qtd_escolas_no_periodo

    from periodos
    group by 1, 2, 3, 4, 5

),

periodos_atribuiveis as (

    select
        periodos.cenario,
        periodos.id_aluno,
        periodos.id_escola,
        periodos.duracao_periodo_dias,
        if(
            periodos.cenario = 'duracao_inteira_em_cada_escola'
            or escolas_no_periodo.qtd_escolas_no_periodo = 1,
            periodos.faltas_por_dia_letivo,
            null
        ) as faltas_por_dia_letivo

    from periodos
    inner join escolas_no_periodo
        on periodos.cenario = escolas_no_periodo.cenario
        and periodos.id_aluno = escolas_no_periodo.id_aluno
        and periodos.disciplina = escolas_no_periodo.disciplina
        and periodos.data_inicio = escolas_no_periodo.data_inicio
        and periodos.duracao_periodo_dias = escolas_no_periodo.duracao_periodo_dias

),

-- Frequência global do vínculo aluno-escola, como em
-- int_frequencias_por_aluno_escola (soma de faltas e dias de todas as
-- disciplinas e períodos).
vinculos as (

    select
        cenario,
        id_aluno,
        id_escola,
        sum(faltas_por_dia_letivo * duracao_periodo_dias) as soma_faltas,
        sum(duracao_periodo_dias) as soma_dias

    from periodos_atribuiveis
    where faltas_por_dia_letivo is not null
    group by 1, 2, 3

),

final as (

    select
        cenario,
        count(*) as qtd_vinculos_aluno_escola,
        countif(
            {{ abaixo_da_frequencia_minima(percentual_frequencia('soma_faltas', 'soma_dias')) }}
        ) as qtd_vinculos_absenteismo_cronico,
        safe_divide(
            countif(
                {{ abaixo_da_frequencia_minima(percentual_frequencia('soma_faltas', 'soma_dias')) }}
            ),
            count(*)
        ) as taxa_absenteismo_cronico

    from vinculos
    group by 1

)

select * from final
order by cenario
