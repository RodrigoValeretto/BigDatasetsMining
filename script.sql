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
----------------------- EXERCICIO 01 -----------------------

-- Criando tabelas principais
drop table if exists Pacientes cascade;
create table Pacientes(
	id_paciente char(32) primary key,
	ic_sexo char(1) check (ic_sexo in ('M', 'F')),
	aa_nascimento char(4),
	cd_pais char(2),
	cd_uf char(2),
	cd_municipio text,
	cd_cepreduzido varchar(5)
);

drop table if exists Exames cascade;
create table Exames(
	id_exame bigserial primary key,
	id_paciente char(32),
	id_atendimento char(32),
	dt_coleta date,
	de_origem varchar(100),
	de_exame varchar(100),
	de_analito varchar(100),
	de_resultado text,
	cd_unidade varchar(20),
	de_valor_referencia varchar(50),
	constraint id_paciente_fk foreign key (id_paciente) references Pacientes(id_paciente) on delete cascade
);

drop table if exists Desfechos cascade;
create table Desfechos(
	id_paciente char(32),
	id_atendimento char(32),
	dt_atendimento date,
	de_tipo_atendimento text,
	id_clinica int,
	de_clinica text,
	dt_desfecho varchar(10),
	de_desfecho text,
	constraint id_paciente_fk foreign key (id_paciente) references Pacientes(id_paciente) on delete cascade,
	constraint pk_desfechos primary key (id_paciente, id_atendimento)
);

-- Configura banco para aceitar data no estilo DD/MM/YYYY
set datestyle = 'ISO,DMY';

-- Preenchendo tabelas com valores dos csvs
copy Pacientes from '/HSL_Junho2021/HSL_Pacientes_4.csv' delimiter '|' csv header;

copy Exames(id_paciente, id_atendimento, dt_coleta, de_origem, de_exame, de_analito, de_resultado, cd_unidade, de_valor_referencia)
from '/HSL_Junho2021/HSL_Exames_4.csv' delimiter '|' csv header;

copy Desfechos from '/HSL_Junho2021/HSL_Desfechos_4.csv' delimiter '|' csv header;

-- Tratamento dos dados
-- Trocando valor de ano de nascimento indefinido para null e para aqueles que nasceram
-- em 1930 ou antes setamos 1930 como padrao. Depois mudamos o tipo da coluna para inteiro.
update pacientes set aa_nascimento = '1930' where aa_nascimento = 'AAAA';
update pacientes set aa_nascimento = null where aa_nascimento = 'YYYY';
alter table pacientes alter column aa_nascimento type integer using aa_nascimento::integer;

-- Removendo todos os acentos dos analitos na tabela de exames
create extension if not exists unaccent;
update exames set de_analito = lower(unaccent(de_analito));

-- Trocando todos os analitos de exames de deteccao de covid para
-- 'deteccao covid'
update exames set de_analito = 'DETECCAO COVID'
where de_analito ilike 'coronavirus (2019-ncov)'
or de_analito ilike 'covid 19, deteccao por pcr';

-- Troca os diferentes resultados que correspondem a deteccao para o analito
-- 2019-ncov pela string 'DETECTADO'
update exames set de_resultado = 'DETECTADO'
where de_analito = 'DETECCAO COVID' and de_resultado ilike 'DETECT%'; 

-- Troca os diferentes resultados correspondentes a nao deteccao do analito
-- ncov-2019 para 'NAO DETECTADO'
update exames set de_resultado = 'NAO DETECTADO'
where de_analito = 'DETECCAO COVID'
and unaccent(de_resultado) ilike '%nao detectado%'
or unaccent(de_resultado) ilike 'indetectavel';

-- Troca de_resultado inconclusivo do analito 2019-ncov para a string 'INCONCLUSIVO'
update exames set de_resultado = 'INCONCLUSIVO'
where de_analito = 'DETECCAO COVID'
and de_resultado ilike 'inconclusivo';

-- Renomeando analitos de anticorpos igm
update exames set de_analito = 'COVID 19 - ANTICORPOS IGM'
where de_analito ilike 'covid 19, anticorpos igm, quimioluminescencia'
or de_analito ilike 'covid 19, anticorpos igm, teste rapido';

-- Renomeando analitos de anticorpos igg
update exames set de_analito = 'COVID 19 - ANTICORPOS IGG'
where de_analito ilike 'covid 19, anticorpos igg, quimioluminescencia'
or de_analito ilike 'covid 19, anticorpos igg, teste rapido';

-- Troca os diferentes resultados correspondentes a deteccao do analito
-- para 'DETECTADO'
update exames set de_resultado = 'DETECTADO'
where (de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
and unaccent(de_resultado) ilike 'reagente';

-- Troca os diferentes resultados correspondentes a nao deteccao do analito
-- para 'NAO DETECTADO'
update exames set de_resultado = 'NAO DETECTADO'
where (de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
and unaccent(de_resultado) ilike 'nao reagente';

-- Troca os diferentes resultados correspondentes a indeterminacao do analito
-- para 'INCONCLUSIVO'
update exames set de_resultado = 'INCONCLUSIVO'
where (de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
and unaccent(de_resultado) ilike 'indeterminado';

----------------------- EXERCICIO 02 -----------------------

-- 2.1 - TODO

-- 2.2
-- Conta pacientes da base
select count(id_paciente) as n_pacientes from pacientes;

-- Conta pacientes da base por sexo
select ic_sexo as sexo, count(id_paciente) as n_pacientes from pacientes group by ic_sexo;

-- Descobre faixa etaria por sexo
select ic_sexo, date_part('year', now()) - max(aa_nascimento) as idade_min, date_part('year', now()) - min(aa_nascimento) as idade_max
from pacientes group by ic_sexo;

-- Encontra distribuicao de quartis para cada genero
select
	ic_sexo as "sexo",
	date_part('year', now()) - percentile_cont(0.25) within group (order by aa_nascimento asc) as "1o_quart",
	date_part('year', now()) - percentile_cont(0.5) within group (order by aa_nascimento asc) as "2o_quart",
	date_part('year', now()) - percentile_cont(0.75) within group (order by aa_nascimento asc) as "3o_quart"
from pacientes group by ic_sexo;

-- Conta quantos homens e mulheres nasceram em cada decada (O valor NULL corresponde a pessoas que nao tem dados)
select ic_sexo, floor(aa_nascimento/10)*10 as decada, count(id_paciente) as n_pacientes
from pacientes
group by decada, ic_sexo order by ic_sexo, decada asc;

--2.3
-- Calculando numero maximo de exames para um paciente
select max(n_exames) as n_max_exames from 
	(select count(id_exame) as n_exames, id_paciente from exames group by id_paciente) as count_exames;
	
-- Calculando media de exames por genero
-- Query para homens
select avg(n_exames) as media_exames_M from (
	select count(e.id_exame) as n_exames, e.id_paciente from exames e
	join pacientes p on p.id_paciente = e.id_paciente
	where p.ic_sexo = 'M'
	group by e.id_paciente
	) as count_exames;

-- Query para mulheres
select avg(n_exames) as media_exames_F from (
    select count(e.id_exame) as n_exames, e.id_paciente from exames e
	join pacientes p on p.id_paciente = e.id_paciente
	where p.ic_sexo = 'F'
	group by e.id_paciente
	) as count_exames;
	
-- Conta quantos exames de covid foram solicitados
select count(id_exame) as qnt_exames_covid from exames e
where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG');

-- Conta quantos exames de covid possuem resultado positivo
select count(id_exame) as qnt_exames_covid_positivo from exames e
where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
and de_resultado ilike 'DETECTADO';

-- Query que retorna quantas pessoas de cada idade obtiveram determinado resultado 
select date_part('year', now()) - p.aa_nascimento as idade, de_resultado, count(e.de_resultado) from exames e
join pacientes p on p.id_paciente = e.id_paciente 
where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
group by p.aa_nascimento, de_resultado 
order by p.aa_nascimento asc;

-- 2.4
select mode() within group (order by de_desfecho) from desfechos;

select d.de_desfecho, d.id_paciente from desfechos d where lower(d.de_desfecho) <> 'alta administrativa'

-- TODO Ultimo topico
select p.ic_sexo, mode() within group (order by de_desfecho) from desfechos d
join pacientes p on d.id_paciente = p.id_paciente


----------------------- EXERCICIO 03 -----------------------
-- Calcular numero de mortes de pessoas que tiveram resultado positivo em Covid-19
-- e tambem numero de mortes agrupados por decada de nascimento dos pacientes.
select count(*) as n_mortes from (
    select distinct id_paciente as id_pacientes_positivos from exames e
    where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
    and de_resultado like 'DETECTADO'   
) as consulta_positivos join desfechos d on d.id_paciente = id_pacientes_positivos
where d.dt_desfecho like 'DDMMAA'

select floor(p.aa_nascimento/10)*10 as decada_de_nascimento, count(p.id_paciente) as n_mortes
from (
    select distinct id_paciente as id_pacientes_positivos from exames e
    where (de_analito = 'DETECCAO COVID' or de_analito = 'COVID 19 - ANTICORPOS IGM' or de_analito = 'COVID 19 - ANTICORPOS IGG')
    and de_resultado like 'DETECTADO'   
) as consulta_positivos join desfechos d on d.id_paciente = id_pacientes_positivos
join pacientes p on p.id_paciente = id_pacientes_positivos 
where d.dt_desfecho like 'DDMMAA'
group by decada_de_nascimento order by decada_de_nascimento asc;


----------------------- EXERCICIO 04 -----------------------
-- 4.A - Select para buscar mais novos e mais velhos de cada cidade usando apenas group by
select p.cd_municipio, p.id_paciente, date_part('year', now()) - p.aa_nascimento as idade from (
    select cd_municipio as min_max_mun, max(aa_nascimento) as ano_max, min(aa_nascimento) as ano_min
    from pacientes
    group by cd_municipio
) as min_max_anos, pacientes p where (p.aa_nascimento = ano_max or p.aa_nascimento = ano_min) and p.cd_municipio = min_max_mun
order by cd_municipio, idade asc

-- 4.B - Select para buscar mais novos e mais velhos de cada cidade usando with
with min_max_anos as (
    select cd_municipio as min_max_mun, max(aa_nascimento) as ano_max, min(aa_nascimento) as ano_min
    from pacientes
    group by cd_municipio   
) 
select p.cd_municipio, p.id_paciente, date_part('year', now()) - p.aa_nascimento as idade from min_max_anos, pacientes p
where (p.aa_nascimento = ano_max or p.aa_nascimento = ano_min) and p.cd_municipio = min_max_mun
order by cd_municipio, idade asc

-- 4.C - Select para buscar mais novos e mais velhos de cada cidade usando window function

select cd_municipio, id_paciente, date_part('year', now()) - aa_nascimento as idade
from(
  select cd_municipio, id_paciente, aa_nascimento,
      min(aa_nascimento) over(partition by cd_municipio) ano_min,
      max(aa_nascimento) over(partition by cd_municipio) ano_max
  from pacientes p) as p
where p.aa_nascimento = p.ano_max or p.aa_nascimento = p.ano_min
order by cd_municipio, idade;


----------------------- EXERCICIO 05 -----------------------
-- 5.A - Consulta para mostrar quaais analitos podem ser medidos em exames de 'hemograma' em cada hospital
-- Versao sem window function
select de_origem, array_agg(distinct de_analito) from exames e
where upper(e.de_exame) like '%HEMOGRAMA%'
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
    upper(e.de_exame) like '%HEMOGRAMA%' 
    ) as p 
where row_number = 1

-- 5.B

----------------------- EXERCICIO 06 -----------------------
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
where lower(e.de_analito) like '%colesterol%' and de_resultado not like '%impossibilita%'
order by id_paciente, id_atendimento, id_paciente


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
                    ('v-colesterol'),
                    ('vldl-colesterol'))$$
  )
             as ct (id_atendimento char(32),
  "colesterol nao-hdl, soro" real,
  "colesterol total" real,
  "hdl-colesterol" real,
  "ldl colesterol" real,
  "v-colesterol" real,
  "vldl-colesterol" real)
inner join desfechos d on
  d.id_atendimento = ct.id_atendimento;
  

----------------------- EXERCICIO 07 -----------------------
  
drop view if exists exames_hemograma;

-- Cria view de auxilio (ignorando morfologias e plaquetas)
create view exames_hemograma as
select distinct
    de_exame,
    de_analito,
    id_paciente,
    id_atendimento,
    dt_coleta,
    cd_unidade,
    avg(to_number(de_resultado, '99999999D9999999')) over (partition by id_paciente, dt_coleta, de_analito)
from exames e
where lower(e.de_exame) like '%hemograma%' and de_analito not like '%morfologia%' and de_analito <> 'plaquetas' 
order by id_paciente, id_atendimento, id_paciente

select
    ct.*,
    de_desfecho
from
    crosstab (
 'select id_atendimento,de_analito,avg from exames_hemograma order by 1,2',
    $$(
values('basofilos (%)'),
                    ('basofilos'),
                    ('bastonetes (%)'),
                    ('bastonetes'),
                    ('blastos (%)'),
                    ('blastos'),
                    ('chcm'),
                    ('concentracao de hemoglobina corpuscular'),
                    ('eosinofilos (%)'),
                    ('eosinofilos'),
                    ('eritrocitos'),
                    ('racao imatura de plaquetas'),
                    ('hcm'),
                    ('hematocrito'),
                    ('hemoglobina corpuscular media'),
                    ('hemoglobina'),
                    ('indice de green & king'),
                    ('leucocitos'),
                    ('linfocitos (%)'),
                    ('linfocitos'),
                    ('metamielocitos (%)'),
                    ('metamielocitos'),
                    ('mielocitos (%)'),
                    ('mielocitos'),
                    ('monocitos (%)'),
                    ('monocitos'),
                    ('neutrofilos (%)'),
                    ('neutrofilos'),
                    ('plasmocitos (%)'),
                    ('plasmoticos'),
                    ('promielocitos (%)'),
                    ('promielocitos'),
                    ('rdw'),
                    ('segmentados (%)'),
                    ('segmentados'),
                    ('vcm'),
                    ('volume plaquetario medio'))$$
 )
 as ct (
    id_atendimento char(32),
    "basofilos (%)" real,
    "basofilos" real,
    "bastonetes (%)" real,
    "bastonetes" real,
    "blastos (%)" real,
    "blastos" real,
    "chcm" real,
    "concentracao de hemoglobina corpuscular" real,
    "eosinofilos (%)" real,
    "eosinofilos" real,
    "eritrocitos" real,
    "racao imatura de plaquetas" real,
    "hcm" real,
    "hematocrito" real,
    "hemoglobina corpuscular media" real,
    "hemoglobina" real,
    "indice de green & king" real,
    "leucocitos" real,
    "linfocitos (%)" real,
    "linfocitos" real,
    "metamielocitos (%)" real,
    "metamielocitos" real,
    "mielocitos (%)" real,
    "mielocitos" real,
    "monocitos (%)" real,
    "monocitos" real,
    "neutrofilos (%)" real,
    "neutrofilos" real,
    "plasmocitos (%)" real,
    "plasmoticos" real,
    "promielocitos (%)" real,
    "promielocitos" real,
    "rdw" real,
    "segmentados (%)" real,
    "segmentados" real,
    "vcm" real,
    "volume plaquetario medio" real
 )
inner join desfechos d on
    d.id_atendimento = ct.id_atendimento;


----------------------- EXERCICIO 08 -----------------------
drop view if exists exames_covid;

create view exames_covid as
select
    id_exame,
    id_atendimento,
    de_exame,
    de_analito,
    de_resultado,
    NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') as valor_referencia,
    case when de_resultado > NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') then 'POSITIVO'
    when de_resultado < NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') then 'NEGATIVO'
    when NULLIF(regexp_replace(de_valor_referencia, '[^0-9,]*','','g'), '') = null then null
    end as estado_result
from exames e 
where de_analito ilike '%covid%' and de_resultado ~ '^[0-9]*[.,]?[0-9]+$';

/*  UPDATE DA TABELA COM VALOR DE POSITIVO E NEGATIVO
update exames_covid set 
de_resultado = case when de_resultado > valor_referencia then 'POSITIVO'
    when de_resultado < valor_referencia then 'NEGATIVO'
    when valor_referencia = null then null
    end;
*/

----------------------- EXERCICIO 09 -----------------------

-- Pivot
CREATE EXTENSION IF NOT EXISTS tablefunc;

select
    *
from
    crosstab($$select id_atendimento,
    de_analito,
    estado_result
from
    exames_covid
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
    "covid 19, anticorpos iga" varchar,
    "covid 19, anticorpos iga, indice" varchar,
    "covid 19, anticorpos igg" varchar,
    "covid 19, anticorpos igg, indice" varchar,
    "covid 19, anticorpos igg, quimiolumin.-indice" varchar,
    "covid 19, anticorpos igm, quimiolumin.-indice" varchar,
    "covid 19, anticorpos totais, eletroquim-indic" varchar,
    "covid 19, anti-spike neutralizantes - indice" varchar)








