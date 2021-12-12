------------------------------------------------------------
/*
	Trabalho SCC0244 - Mineracao de grandes bases de dados
	Alunos:
	Andre Bermudes Viana			NUSP: 10684580
	Joao Pedro Fidelis Belluzzo		NUSP: 10716661
	Leonardo Cerce Guioto			NUSP: 10716640
	Rodrigo Augusto Valeretto		NUSP: 10684792
*/
------------------------------------------------------------
----------------------- EXERCICIO 08 -----------------------
drop table if exists exames_covid;

create table exames_covid as
select
    id_exame,
    id_paciente,
    id_atendimento,
    dt_coleta,
    de_exame,
    de_analito,
    NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') as valor_referencia,
    case when de_resultado > NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') then 'POSITIVO'
    when de_resultado < NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') then 'NEGATIVO'
    when NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') = null then null
    end as de_resultado
from exames e
where de_analito ilike '%covid%' and de_resultado ~ '^[0-9]*[.,]?[0-9]+$';
