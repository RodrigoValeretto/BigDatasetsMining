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
----------------------- EXERCICIO 06 -----------------------
-- Assumimos que v-colesterol eh a medida de vldl-colesterol
update exames set de_analito = 'vldl-colesterol'
where de_analito = 'v-colesterol';

drop view if exists exames_colesterol;

-- Cria tabela de auxilio
create view exames_colesterol as
select distinct
    de_analito,
    id_paciente,
    id_atendimento,
    dt_coleta,
    cd_unidade,
    avg(to_number(de_resultado, '99999999D9999999')) over (partition by id_paciente, dt_coleta, de_analito)
from exames e
where e.de_analito ilike '%colesterol%' and de_resultado not like '%impossibilita%'
order by id_paciente, id_atendimento, id_paciente;


-- Pivot
CREATE EXTENSION IF NOT EXISTS tablefunc;

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
  "hdl-colesterol" real,
  "ldl colesterol" real,
  "vldl-colesterol" real)
inner join desfechos d on
  d.id_atendimento = ct.id_atendimento;