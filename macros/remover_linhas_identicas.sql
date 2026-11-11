{#
    Remove linhas idênticas em todas as colunas (cópias exatas da fonte).
    É a única deduplicação feita na staging: não muda o significado nem a
    granularidade da tabela. Chaves repetidas com valores diferentes não são
    tocadas aqui; ficam para a consolidação da intermediate (macros
    consolidar_valor e possui_conflito).
    Aplicada em todas as stagings, para a regra ser a mesma em toda a fonte.
#}
{% macro remover_linhas_identicas(relacao) %}
    select distinct * from {{ relacao }}
{% endmacro %}
