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
----------------------- EXERCICIO 11 -----------------------

-- Cria vista de auxilio
drop view if exists exames_contabilizados;
create view exames_contabilizados as
select
	case
		when de_origem ilike '%hos%'
		  or de_origem ilike '%UTI%'
            then 'Hosp'
        when
        	de_origem ilike '%lab%'
        	then 'Lab'
        when de_origem ilike '%atend%'
          or de_origem ilike '%interna%'
          or de_origem ilike '%pronto%'
        	then 'Atend'
		else 'Outros'
	end as de_origem,
	case
		when de_exame ilike '%hemograma%'
            then 'Hemograma'
        when de_exame ilike '%colesterol%'
        	then 'Colesterol'
        when de_exame ilike '%cov%'
          or de_exame  ilike '%corona%'
        	then 'Covid'
		else 'Outros'
	end as de_exame
from exames e;

-- Histograma
select
	'HSL' as de_hospital,
	de_origem as origem,
	de_exame as exame,
	count(*) as contagem
from
	exames_contabilizados e
group by
	origem,
	exame
order by
de_hospital,
origem,
contagem desc;
