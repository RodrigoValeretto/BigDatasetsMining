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
----------------------- EXERCICIO 03 -----------------------
-- Calcular numero de mortes de pessoas que tiveram resultado positivo em Covid-19
-- e tambem numero de mortes agrupados por decada de nascimento dos pacientes.
select count(*) as n_mortes from (
    select distinct id_paciente as id_pacientes_positivos from exames e
    where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
    and de_resultado like 'DETECTADO'
) as consulta_positivos join desfechos d on d.id_paciente = id_pacientes_positivos
where d.dt_desfecho like 'DDMMAA';

select floor(p.aa_nascimento/10)*10 as decada_de_nascimento, count(p.id_paciente) as n_mortes
from (
    select distinct id_paciente as id_pacientes_positivos from exames e
    where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
    and de_resultado like 'DETECTADO'
) as consulta_positivos join desfechos d on d.id_paciente = id_pacientes_positivos
join pacientes p on p.id_paciente = id_pacientes_positivos
where d.dt_desfecho like 'DDMMAA'
group by decada_de_nascimento order by decada_de_nascimento asc;
