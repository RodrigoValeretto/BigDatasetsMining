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
----------------------- EXERCICIO 04 -----------------------
-- 4.A - Select para buscar mais novos e mais velhos de cada cidade usando apenas group by
select p.cd_municipio, p.id_paciente, date_part('year', now()) - p.aa_nascimento as idade from (
    select cd_municipio as min_max_mun, max(aa_nascimento) as ano_max, min(aa_nascimento) as ano_min
    from pacientes
    group by cd_municipio
) as min_max_anos, pacientes p where (p.aa_nascimento = ano_max or p.aa_nascimento = ano_min) and p.cd_municipio = min_max_mun
order by cd_municipio, idade asc;

-- 4.B - Select para buscar mais novos e mais velhos de cada cidade usando with
with min_max_anos as (
    select cd_municipio as min_max_mun, max(aa_nascimento) as ano_max, min(aa_nascimento) as ano_min
    from pacientes
    group by cd_municipio
)
select p.cd_municipio, p.id_paciente, date_part('year', now()) - p.aa_nascimento as idade from min_max_anos, pacientes p
where (p.aa_nascimento = ano_max or p.aa_nascimento = ano_min) and p.cd_municipio = min_max_mun
order by cd_municipio, idade asc;

-- 4.C - Select para buscar mais novos e mais velhos de cada cidade usando window function

select cd_municipio, id_paciente, date_part('year', now()) - aa_nascimento as idade
from(
  select cd_municipio, id_paciente, aa_nascimento,
      min(aa_nascimento) over(partition by cd_municipio) ano_min,
      max(aa_nascimento) over(partition by cd_municipio) ano_max
  from pacientes p) as p
where p.aa_nascimento = p.ano_max or p.aa_nascimento = p.ano_min
order by cd_municipio, idade;