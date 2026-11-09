{% macro formatar_id_aluno(coluna) %}
    {#
        id_aluno chega como BYTES (hash binário de 17 bytes).
        Converte para STRING hexadecimal (34 caracteres): sem perda, determinístico
        e com caracteres seguros. Usar em todas as tabelas que têm id_aluno,
        para garantir que os joins entre elas funcionem.
    #}
    to_hex({{ coluna }})
{% endmacro %}