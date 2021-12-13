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
----------------------- EXERCICIO 05 -----------------------
-- 5.A - Consulta para mostrar quais analitos podem ser medidos em exames de 'hemograma' em cada origem
-- Versao sem window function
select de_origem, array_agg(distinct de_analito) from exames e
where e.de_exame ilike '%hemograma%'
group by de_origem;

-- Versao com window function
select de_origem, array_agg from (
select
    de_origem,
    array_agg(de_analito) over (partition by de_origem),
    row_number() over (partition by de_origem)
from
    exames e
where
    e.de_exame ilike '%hemograma%'
    ) as p
where row_number = 1;

-- 5.B
-- Dois nomes completos foram substituidos pela sigla
update exames set de_analito = 'hcm' where de_analito ilike 'hemoglobina corpuscular media';
update exames set de_analito = 'chcm' where de_analito ilike 'concentracao de hemoglobina corpuscular';
