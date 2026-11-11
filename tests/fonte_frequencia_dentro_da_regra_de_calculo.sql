{{ config(severity = 'warn') }}

-- Monitoramento da fonte: registros de frequencia abaixo de 99, que pela
-- regra de cálculo do produtor (100 - faltas / dias letivos) indicariam mais
-- faltas que dias letivos. A staging
-- os exclui; este teste mostra a cada execução quantos a fonte entrega.
-- Coluna qualificada pelo alias: no GoogleSQL, "frequencia" sozinho pode ser
-- lido como a linha inteira da tabela de mesmo nome.

select
    origem.id_escola,
    origem.id_turma,
    origem.disciplina,
    origem.data_inicio,
    origem.data_fim,
    origem.frequencia

from {{ source('educacao', 'frequencia') }} as origem
where origem.frequencia < 99
