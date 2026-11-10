{% macro consolidar_valor(coluna) %}
    {#
        Regra de consolidação de chaves duplicadas (usar dentro de um group by
        pela chave do modelo). Se os valores não nulos da coluna coincidem, mantém
        o valor; se divergem, devolve nulo. Nulos não contam como divergência:
        linhas que se completam são fundidas. Nunca calcula média entre valores.
        Usar sempre junto com possui_conflito(coluna).
    #}
    if(count(distinct {{ coluna }}) <= 1, max({{ coluna }}), null)
{% endmacro %}
