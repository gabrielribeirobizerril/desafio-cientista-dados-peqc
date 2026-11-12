{% macro consolidar_valor(coluna) %}
    {#
        Regra de consolidação de chaves duplicadas (usar dentro de um group by
        pela chave do modelo). Se os valores não nulos da coluna coincidem, mantém
        o valor; se divergem, devolve nulo. Nulos não contam como divergência:
        linhas que se completam são fundidas. Nunca calcula média entre valores.
        Acompanhar de uma flag possui_conflito na mesma consolidação (sobre
        esta coluna ou sobre a coluna da qual ela deriva), para que a
        divergência não fique silenciosa.
    #}
    if(count(distinct {{ coluna }}) <= 1, max({{ coluna }}), null)
{% endmacro %}
