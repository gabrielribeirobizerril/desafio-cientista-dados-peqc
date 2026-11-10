{% macro possui_conflito(coluna) %}
    {#
        Par de consolidar_valor: verdadeiro quando a chave tem mais de um valor
        não nulo distinto na coluna, ou seja, quando consolidar_valor anulou o
        valor por conflito.
    #}
    count(distinct {{ coluna }}) > 1
{% endmacro %}
