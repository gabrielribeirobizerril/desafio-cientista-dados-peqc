{#
    Frequência em percentual a partir das faltas ponderadas pelos dias.
    soma_faltas: soma de (faltas_por_dia_letivo * duracao_periodo_dias)
    soma_dias: soma de duracao_periodo_dias
    Única definição da conversão índice da fonte -> percentual no projeto.
#}
{% macro percentual_frequencia(soma_faltas, soma_dias) %}
    100 * (1 - safe_divide({{ soma_faltas }}, {{ soma_dias }}))
{% endmacro %}
