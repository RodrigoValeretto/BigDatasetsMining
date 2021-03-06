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

-- Trocando o valor do UF para nulo nos dados anonimizados
update pacientes set cd_uf = null where cd_uf = 'UU';

-- Trocando o valor do Munic????pio para nulo nos dados anonimizados ou de estrangeiros
update pacientes set cd_municipio = null where cd_municipio = 'MMMM';

-- Trocando o valor do CEP para nulo nos dados anonimizados ou de estrangeiros
update pacientes set cd_cepreduzido = null where cd_cepreduzido = 'CCCC';

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

-- 2.1
-------------------- TABELA Pacientes
-------- ID_PACIENTE
-- N????mero de Pacientes
select count(id_paciente) as n_atendimentos from pacientes p;

-------- IC_SEXO
-- Distribui????????o dos sexos
select ic_sexo, count(ic_sexo) from pacientes p
group by ic_sexo;

-------- AA_NASCIMENTO
-- N????mero de Idades Anonimizadas (nulas ap????s nossa limpeza)
select count(*) as n_nulos_idade from pacientes p
where aa_nascimento is null;
-- Vari????ncia da idade
select var_samp(aa_nascimento) from pacientes p;
-- Desvio Padr????o da idade
select stddev_samp(aa_nascimento) from pacientes p;

-------- CD_PAIS
-- N????mero de Estrangeiros
select count(*) as n_estrangeiros from pacientes p
where cd_pais = 'XX';

-------- CD_UF
-- Distribui????????o dos UF
select cd_uf, count(cd_uf) from pacientes p
where cd_uf is not null
group by cd_uf;
-- N????mero de Anonimizados (nulos ap????s nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_uf is null;

-------- CD_MUNICIPIO
-- Distribui????????o dos Municipios
select cd_municipio, count(cd_municipio) from pacientes p
where cd_municipio is not null
group by cd_municipio;
-- N????mero de Anonimizados (nulos ap????s nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_municipio is null;

-------- CD_CEPREDUZIDO
-- Distribui????????o dos CEPS
select cd_cepreduzido, count(cd_cepreduzido) from pacientes p
where cd_cepreduzido is not null
group by cd_cepreduzido;
-- N????mero de Anonimizados (nulos ap????s nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_cepreduzido is null;

-------------------- TABELA Exames
-------- ID_PACIENTE
-- N????mero de pacientes que pediram exames
select count(distinct id_paciente) as n_atendimentos from exames e;

-------- ID_ATENDIMENTO
-- N????mero de atendimentos
select count(distinct id_atendimento) as n_atendimentos from exames e;
-- M????dia de exames por atendimento	
select
	avg(numero_exames)
from
	(
	select
		count(*) over (partition by id_atendimento) numero_exames
	from
		exames e) as a;

-------- DT_COLETA
-- M????dia de coletas por dia	
select
	avg(numero_coletas) as media_coletas_dia
from
	(
	select
		count(*) over (partition by dt_coleta) numero_coletas
	from
		exames e) as a;
	
-------- DE_ORIGEM
-- N????mero de origens existentes
select count(distinct de_origem) as n_origens from exames e;
-- Distribui????????o das origens
select de_origem, count(de_origem) from exames e
where de_origem is not null
group by de_origem;

-------- DE_EXAME
-- N????mero total de exames realizados
select count(de_exame) as numero_exames from exames e;
-- N????mero de tipos de exames existentes na tabela
select count(distinct de_exame) as numero_distinto_exames from exames e;

-------- DE_ANALITO
-- N????mero de tipos de analitoss existentes na tabela
select count(distinct de_analito) as numero_distinto_analitos from exames e;

-------- DE_RESULTADO
-- ?????
-------- CD_UNIDADE
-- ?????
-------- DE_VALOR_REFERENCIA
-- ?????

-------------------- TABELA Desfechos
-------- DT_ATENDIMENTO
-- Media de atendimentos por dia	
select
	avg(numero_atendimentos) as media_atendimentos
from
	(
	select
		count(*) over (partition by dt_atendimento) numero_atendimentos
	from
		desfechos d) as a;

-------- DE_TIPO_ATENDIMENTO
-- Tipos distintos de atendimentos
select distinct de_tipo_atendimento tipos_unicos from desfechos d;
-- Distribuicao dos tipos de atendimento
select de_tipo_atendimento, count(de_tipo_atendimento) from desfechos d
where de_tipo_atendimento is not null
group by de_tipo_atendimento;

-------- ID_CLINICA
-- Numero de clinicas
select  count(distinct id_clinica) n_clinicas from desfechos d;

-------- DE_CLINICA
-- ?????

-------- DT_DESFECHO
-- Media de desfechos por dia	
select
	avg(numero_desfechos) as media_atendimentos
from
	(
	select
		count(*) over (partition by dt_desfecho) numero_desfechos
	from
		desfechos d) as a;

-------- DE_DESFECHO
-- Tipos distintos de desfechos
select distinct de_desfecho desfechos_unicos from desfechos d;

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
-- Desfecho para a maioria dos casos registrados
select mode() within group (order by de_desfecho) desfecho_maioria from desfechos;

-- Visualizar a quantidade de cada desfecho
select de_desfecho, count(de_desfecho) as contagem from desfechos d
group by de_desfecho
order by contagem desc;

-- Visualizar a quantidade de cada desfecho mas com window function
select distinct de_desfecho , count(de_desfecho) over (partition by de_desfecho) contagem from desfechos
order by contagem desc;

-- Desfechos maioria para cada genero
select p.ic_sexo, mode() within group (order by de_desfecho) desfecho_maioria from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
group by p.ic_sexo;

-- Desfechos maioria por d????cada de vida
select floor(aa_nascimento/10)*10 as decada, mode() within group (order by de_desfecho) desfecho_maioria from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
group by decada;

-- Desfechos maioria por idade
select (2020 -aa_nascimento) as decada, mode() within group (order by de_desfecho) desfecho_maioria from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
group by decada;

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


----------------------- EXERCICIO 05 -----------------------
-- 5.A - Consulta para mostrar quaais analitos podem ser medidos em exames de 'hemograma' em cada origem
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
-- N????o existem diferentes nomes para um mesmo analito
select distinct de_analito from exames e
where e.de_exame ilike '%hemograma%'
order by de_analito;

----------------------- EXERCICIO 06 -----------------------
-- Assumimos que v-colesterol ???? a medida de vldl-colesterol
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
where e.de_exame ilike '%hemograma%' and de_analito not like '%morfologia%' and de_analito <> 'plaquetas' 
order by id_paciente, id_atendimento, id_paciente;

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
	calculo_positivo.*,
	max(dt_coleta) filter (
	where resultado_agregado = 'NEGATIVO'
	and dt_coleta > Primeiro_Positivo) over (partition by id_paciente) Primeiro_Negativo,
	(max(dt_coleta) filter (
	where resultado_agregado = 'NEGATIVO'
	and dt_coleta > Primeiro_Positivo) over (partition by id_paciente)) - Primeiro_Positivo as Dias_Diferenca
from
	(
	select
		ct.*, dt_coleta, id_paciente, min(dt_coleta) filter (
		where resultado_agregado = 'POSITIVO') over (partition by id_paciente) Primeiro_Positivo
	from
		exames_covid_ct as ct
	inner join (
		select
			id_atendimento, id_paciente, dt_coleta
		from
			exames_covid) as e on
		e.id_atendimento = ct.id_atendimento) as calculo_positivo
where
	Primeiro_Positivo is not null;
 
----------------------- EXERCICIO 10 -----------------------
-- ITEM 1
-- Histograma equi-largura de distribuicao das idades dos pacientes
-- com bins de largura 2
select
    Bins.B as Idade,
    case
        when Tab.Conta is null then 0
        else Tab.Conta
    end Contagem
from
        (with Lim as (
    select
        Min(2020 - p.aa_nascimento) Mi,
        Max(2020 - p.aa_nascimento) Ma
    from
        pacientes p)
    select
        Generate_Series(Lim.Mi, Lim.Ma, 2)
        as B
    from
        Lim) as Bins
left outer join
    (
    select
        floor((2020 - p2.aa_nascimento)/ 2)* 2 as Idade,
        Count(*) Conta
    from
        pacientes p2
    group by
        Idade) as Tab
on
    Bins.B = Tab.Idade;

-- ITEM 2 
-- Histograma equilargura com 10 bins
with MinMax as
(
SELECT
    9 as NB,
    Min(2020 - p.aa_nascimento) as Mi,
    Max(2020 - p.aa_nascimento) as Ma
from
    pacientes p)
select
    Trunc((select Mi from MinMax)+
((Bin-1)*((select Ma from MinMax)-(select Mi from MinMax))/
(select NB from MinMax)), 2) as Ini,
    Trunc(((select Mi from MinMax) +
(Bin)*((select Ma from MinMax)-(select Mi from MinMax))/
(select NB from MinMax)), 2) as Fim,
    Conta
from
    (
    select
        width_bucket(2020 - p2.aa_nascimento, (select Mi from MinMax),
(select Ma from MinMax), (select NB from MinMax)) as Bin,
        Count(*) as Conta
    from
        pacientes p2
    group by
        Bin
    order by
        Bin) Histo;

----------------------- EXERCICIO 11 -----------------------

----------- CONSULTAS DE TESTE  ---------
select distinct de_origem from exames;
select distinct de_origem from exames
where de_origem ilike '%UTI%';
select distinct de_exame from exames
where de_exame ilike '%cov%';
-----------------------------------------

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
 
-- Reduzir a quantidade de valores que est????o nulos.

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
where abs("colesterol nao-hdl, soro" - ("colesterol total" - "hdl colesterol")) > 1

select * from exames_colesterol_crosstab ecc;

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
-- 2265 tuplas n??o contem nulos antes
-- 4807 tuplas n??o contem nulos depois

/* Considerando a maneira como essa tabela foi gerada, incluindo quatro analitos, e sabendo como eles 
 * estao correlacionados, qual e a maior dimensao fractal possivel para esses atributos?  
 */

--N??o precisamos mais desse analito
alter table exames_colesterol_crosstab drop column "colesterol nao-hdl, soro";

select * from exames_colesterol_crosstab ecc
where id_atendimento ilike '%A';

/*
 * Calcule a dimensao fractal dos exames de colesterol, e deem a sua interpretacao do resultado.
 */
drop function if exists EuclideanDist(real[], real[]);

create function EuclideanDist(real[], real[]) returns float as 
		'select sqrt(($1[1] - $2[1])^2 + ($1[2] - $2[2])^2 + 
					 ($1[3] - $2[3])^2 + ($1[4] - $2[4])^2);' 
language sql immutable 
returns null on null input;

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
cross join exames_colesterol_crosstab ecc2
	where ecc1.id_atendimento ilike '%A'
	and ecc2.id_atendimento ilike '%A';

/*with Grid as (
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
	ROUND(128 * Percent_Rank() over (order by Dist)) Pos --> 7 divisoes
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
	DistExp ;*/

--- 128
-- slope: 1.0005853569094085
-- intercept: -5.276227192610893

--- 32
-- slope: 1.0015382080977138
-- intercept: -5.884653364248793
