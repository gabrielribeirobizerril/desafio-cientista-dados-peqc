{{ config(severity = 'warn') }}

-- Monitoramento da fonte: registros de frequencia sem valor. Não há nenhum na
-- carga atual. Os nulos passam pela staging e tiram do cálculo o período
-- inteiro na intermediate (int_frequencias_por_aluno_escola_disciplina_periodo);
-- este teste avisa se surgirem,
-- para que a redução da população dos indicadores não aconteça em silêncio.
-- Coluna qualificada pelo alias: no GoogleSQL, "frequencia" sozinho pode ser
-- lido como a linha inteira da tabela de mesmo nome.

select
    origem.id_escola,
    origem.id_turma,
    origem.disciplina,
    origem.data_inicio,
    origem.data_fim

from {{ source('educacao', 'frequencia') }} as origem
where origem.frequencia is null
