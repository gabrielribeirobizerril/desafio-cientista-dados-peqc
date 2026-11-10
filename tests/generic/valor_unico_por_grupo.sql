{% test valor_unico_por_grupo(model, column_name, agrupar_por) %}

    {#
        Regra: para cada valor de `agrupar_por`, a coluna testada tem um único
        valor. Devolve os grupos que violam a regra (zero linhas = passa).
    #}

    select
        {{ agrupar_por }} as grupo,
        count(distinct {{ column_name }}) as valores_distintos

    from {{ model }}

    where {{ agrupar_por }} is not null

    group by 1

    having count(distinct {{ column_name }}) > 1

{% endtest %}