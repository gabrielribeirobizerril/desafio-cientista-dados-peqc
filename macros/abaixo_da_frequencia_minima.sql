{#
    Absenteísmo crônico: frequência abaixo do mínimo da LDB (art. 24, VI).
    O limite vem da var percentual_frequencia_minima (dbt_project.yml).
    Única definição da regra no projeto.
#}
{% macro abaixo_da_frequencia_minima(coluna_percentual) %}
    {{ coluna_percentual }} < {{ var('percentual_frequencia_minima') }}
{% endmacro %}
