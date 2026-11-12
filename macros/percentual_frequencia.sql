{#
    Frequência em percentual a partir das faltas ponderadas pelos dias.
    soma_faltas: soma de (faltas_por_dia_letivo * duracao_periodo_dias)
    soma_dias: soma de duracao_periodo_dias
    Única definição da conversão faltas ponderadas -> percentual no projeto
    (o índice da fonte vira faltas por dia letivo em stg_educacao__frequencias).
#}
{% macro percentual_frequencia(soma_faltas, soma_dias) %}
    100 * (1 - safe_divide({{ soma_faltas }}, {{ soma_dias }}))
{% endmacro %}
