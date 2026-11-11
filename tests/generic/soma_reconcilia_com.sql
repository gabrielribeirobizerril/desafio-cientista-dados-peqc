{#
    Reconciliação entre models: a soma da coluna testada deve ser igual a uma
    expressão agregada calculada em outro model.
    Argumentos:
      comparar_com: ref() do model de comparação
      expressao: agregação calculada nele (ex.: 'count(*)', 'sum(qtd_alunos)')
    Falha em dois casos, verificados separadamente:
      1. os totais divergem;
      2. o model testado ou o de comparação está vazio (contagem de linhas
         igual a zero).
    Uma soma igual a zero com linhas presentes é legítima (ex.: nenhum caso de
    absenteísmo) e passa. O coalesce trata a soma nula de uma tabela vazia,
    porque nulo != total resulta em nulo, e não em verdadeiro.
#}
{% test soma_reconcilia_com(model, column_name, comparar_com, expressao) %}

with

testado as (

    select
        count(*) as qtd_linhas,
        coalesce(sum({{ column_name }}), 0) as total_testado

    from {{ model }}

),

comparado as (

    select
        count(*) as qtd_linhas,
        coalesce({{ expressao }}, 0) as total_comparado

    from {{ comparar_com }}

)

select
    testado.qtd_linhas as qtd_linhas_testado,
    testado.total_testado,
    comparado.qtd_linhas as qtd_linhas_comparado,
    comparado.total_comparado

from testado
cross join comparado

where
    testado.total_testado != comparado.total_comparado
    or testado.qtd_linhas = 0
    or comparado.qtd_linhas = 0

{% endtest %}
