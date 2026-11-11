{% test compara_linhas_com_origem(model, origem, coluna_contagem) %}
    {# Regra: a soma de `coluna_contagem` no modelo consolidado deve ser igual
       ao total de linhas do modelo de origem. Falha se alguma linha da origem
       foi perdida ou contada duas vezes na consolidação.
       Tabela vazia conta como falha: coalesce evita que soma nula (tabela
       vazia) passe despercebida, porque nulo != total resulta em nulo, e não
       em verdadeiro. #}

    with

    destino as (
        select coalesce(sum({{ coluna_contagem }}), 0) as total_linhas
        from {{ model }}
    ),

    origem as (
        select count(*) as total_linhas
        from {{ origem }}
    )

    select
        destino.total_linhas as total_destino,
        origem.total_linhas as total_origem
    from destino
    cross join origem
    where
        destino.total_linhas != origem.total_linhas
        or origem.total_linhas = 0

{% endtest %}
