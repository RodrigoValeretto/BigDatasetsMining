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
----------------------- EXERCICIO 12 -----------------------

-- Extrair as medidas de cada analito como um atributo de tipo numerico
--(evitando erros de conversao quando o atributo original contiver apenas texto)

-- Criando uma tabela a partir da consulta do Exercicio 06
drop table if exists exames_colesterol_crosstab;

create table exames_colesterol_crosstab as
select
  ct.*,
  de_desfecho
from
  crosstab($$select id_atendimento,
  de_analito,
  avg
from
  exames_colesterol
order by
  1,
  2 $$,
          $$(
values('colesterol nao-hdl, soro'),
                    ('colesterol total'),
                    ('hdl-colesterol'),
                    ('ldl colesterol'),
                    ('vldl-colesterol'))$$
  )
             as ct (id_atendimento char(32),
  "colesterol nao-hdl, soro" real,
  "colesterol total" real,
  "hdl colesterol" real,
  "ldl colesterol" real,
  "vldl colesterol" real)
inner join desfechos d on
  d.id_atendimento = ct.id_atendimento;

-- Reduzir a quantidade de valores que estao nulos.

-- a partir do hdl e total
update exames_colesterol_crosstab set "colesterol nao-hdl, soro" = ("colesterol total" - "hdl colesterol")
where "colesterol nao-hdl, soro" is null
and "hdl colesterol" is not null
and "colesterol total" is not null;

------- CAlCULAR VLDL-COLESTEROL
-- vldl = nao_HDL - LDL
update exames_colesterol_crosstab set "vldl colesterol" = ("colesterol nao-hdl, soro" - "ldl colesterol")
where "vldl colesterol" is null
and "colesterol nao-hdl, soro" is not null
and "ldl colesterol" is not null;

-- a partir de vldl e ldl
update exames_colesterol_crosstab set "colesterol nao-hdl, soro" = ("vldl colesterol" + "ldl colesterol")
where "colesterol nao-hdl, soro" is null
and "vldl colesterol" is not null
and "ldl colesterol" is not null;

------- CAlCULAR HDL-COLESTEROL
-- a partir de total - nao_hdl
update exames_colesterol_crosstab set "hdl colesterol" = ("colesterol total" - "colesterol nao-hdl, soro")
where "hdl colesterol" is null
and "colesterol total" is not null
and "colesterol nao-hdl, soro" is not null;

------- CAlCULAR LDL-COLESTEROL
-- a pratir do nao_hdl e vldl
update exames_colesterol_crosstab set "ldl colesterol" = ("colesterol nao-hdl, soro" - "vldl colesterol")
where "ldl colesterol" is null
and "colesterol nao-hdl, soro" is not null
and "vldl colesterol" is not null;

-------- LIMPEZA DE DADOS FORA DO PADRAO ---------
delete from exames_colesterol_crosstab ecc
where abs("colesterol nao-hdl, soro" - ("colesterol total" - "hdl colesterol")) > 1;

-- Uns testes pra ver a contagem de nulos
select count(*) from exames_colesterol_crosstab ecc
where "colesterol nao-hdl, soro" is null
or "colesterol total" is null
or "hdl colesterol" is null
or "ldl colesterol" is null
or "vldl colesterol" is null;
-- 2643 tuplas contem nulos antes
-- 87 tuplas contem nulos depois

select count(*) from exames_colesterol_crosstab ecc
where "colesterol nao-hdl, soro" is not null
and "colesterol total" is not null
and "hdl colesterol" is not null
and "ldl colesterol" is not null
and "vldl colesterol" is not null;
-- 2265 tuplas não contem nulos antes
-- 4807 tuplas não contem nulos depois

/* Considerando a maneira como essa tabela foi gerada, incluindo quatro analitos, e sabendo como eles
 * estao correlacionados, qual e a maior dimensao fractal possivel para esses atributos?
 */

--Não precisamos mais desse analito
alter table exames_colesterol_crosstab drop column "colesterol nao-hdl, soro";

/*
 * Calcule a dimensao fractal dos exames de colesterol, e deem a sua interpretacao do resultado.
 */
drop function if exists EuclideanDist(real[], real[]);

create function EuclideanDist(real[], real[]) returns float as
		'select sqrt(($1[1] - $2[1])^2 + ($1[2] - $2[2])^2 +
					 ($1[3] - $2[3])^2 + ($1[4] - $2[4])^2);'
language sql immutable
returns null on null input;

/*
* Calcula a dimensao de correlacao.
*/
with Grid as (
select
	ecc1."colesterol total" as ct1,
	ecc1."hdl colesterol" as hc1,
	ecc1."ldl colesterol" as lc1,
	ecc1."vldl colesterol" as vc1,
	ecc2."colesterol total" as ct2,
	ecc2."hdl colesterol" as hc2,
	ecc2."ldl colesterol" as lc2,
	ecc2."vldl colesterol" as vc2,
	EuclideanDist(array[ecc1."colesterol total", ecc1."hdl colesterol", ecc1."ldl colesterol", ecc1."vldl colesterol"], 
				array[ecc2."colesterol total", ecc2."hdl colesterol", ecc2."ldl colesterol", ecc2."vldl colesterol"]) Dist
from
	exames_colesterol_crosstab ecc1
cross join exames_colesterol_crosstab ecc2),
Contagem as (
select
	ct1,
	hc1,
	lc1,
	vc1,
	ct2,
	hc2,
	lc2,
	vc2,
	Dist,
	ROUND(2048 * Percent_Rank() over (order by Dist)) Pos --> 11 divisoes
	from Grid ),
DistExp as (
select
	Pos,
	Avg(Dist) ADist,
	Count(Pos),
	Sum(Count(Pos)) over (
	order by Pos asc rows between unbounded preceding and current row) PDF
from
	Contagem
where
	Dist > 0
	and Pos > 0
group by
	Pos
order by
	Pos)
select
	regr_slope(Log(Pos), Log(PDF)) Slope, --> Dimensao Fractal
 regr_intercept(Log(Pos), Log(PDF)) Intercept
from
	DistExp ;
