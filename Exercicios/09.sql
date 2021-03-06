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
----------------------- EXERCICIO 09 -----------------------

-- Pivot
CREATE EXTENSION IF NOT EXISTS tablefunc;

drop view if exists exames_covid_ct;

-- Cria uma view auxiliar, semelhante a do hemograma
create view exames_covid_ct as
select
    *,
    case when (
    'POSITIVO' in (    "iga",
    "iga, indice",
    "igg",
    "igg, indice",
    "igg, quimio",
    "igm, quimio" ,
    "anticorpos totais",
    "anti-spike neutralizantes")
    )then 'POSITIVO'
    	else 'NEGATIVO'
   	end as resultado_agregado
from
    crosstab($$select id_atendimento,
    de_analito,
    de_resultado
from
    exames
    where de_analito ilike '%covid%'
    and de_resultado ~ 'POSITIVO|NEGATIVO'
    or de_resultado is null
order by
    1,
    2 $$,
                    $$(
values('covid 19, anticorpos iga'), 
                    ('covid 19, anticorpos iga, indice'),
                    ('covid 19, anticorpos igg'),
                    ('covid 19, anticorpos igg, indice'),
                    ('covid 19, anticorpos igg, quimiolumin.-indice'),
                    ('covid 19, anticorpos igm, quimiolumin.-indice'),
                    ('covid 19, anticorpos totais, eletroquim-indic'),
                    ('covid 19, anti-spike neutralizantes - indice'))$$
    )
             as ct (id_atendimento char(32),
    "iga" varchar,
    "iga, indice" varchar,
    "igg" varchar,
    "igg, indice" varchar,
    "igg, quimio" varchar,
    "igm, quimio" varchar,
    "anticorpos totais" varchar,
    "anti-spike neutralizantes" varchar);

-- Consulta para ver o numero de dias entre um resultado positivo e um futuro resultado negativo para um mesmo paciente.
select distinct 
	calculo_positivo.id_atendimento,
	calculo_positivo."iga",
	calculo_positivo."iga, indice",
	calculo_positivo."igg",
	calculo_positivo."igg, indice",
	calculo_positivo."igg, quimio",
	calculo_positivo."igm, quimio",
	calculo_positivo."anticorpos totais",
	calculo_positivo."anti-spike neutralizantes",
	calculo_positivo."resultado_agregado",
	(max(dt_coleta) filter (
where
	resultado_agregado = 'NEGATIVO'
	and dt_coleta > Primeiro_Positivo) over (partition by id_paciente)) - Primeiro_Positivo as Dias_Diferenca
	from
	(
	select
		ct.*, dt_coleta, id_paciente, min(dt_coleta) filter (
	where
		resultado_agregado = 'POSITIVO') over (partition by id_paciente) Primeiro_Positivo
	from
		exames_covid_ct as ct
	inner join (
		select
			id_atendimento, id_paciente, dt_coleta
		from
			exames) as e on
		e.id_atendimento = ct.id_atendimento) as calculo_positivo
order by
	Dias_Diferenca;