------------------------------------------------------------
/*
	Trabalho SCC0244 - Mineracao de grandes bases de dados 
	Alunos:
	Andr� Bermudes Viana			NUSP: 10684580
	Joao Pedro Fidelis Belluzzo		NUSP: 10716661
	Leonardo Cerce Guioto			NUSP: 10716640
	Rodrigo Augusto Valeretto		NUSP: 10684792
*/
------------------------------------------------------------


-- Criando Database e Schema
create database "fapesp-covid19";
create schema "hsl";

------------------- EXERC�CIO 01 -------------------

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
SET datestyle = 'ISO,DMY';

-- Preenchendo tabelas com valores dos csvs
copy Pacientes from '/HSL_Junho2021/HSL_Pacientes_4.csv' delimiter '|' csv header;

copy Exames(id_paciente, id_atendimento, dt_coleta, de_origem, de_exame, de_analito, de_resultado, cd_unidade, de_valor_referencia)
from '/HSL_Junho2021/HSL_Exames_4.csv' delimiter '|' csv header;

copy Desfechos from '/HSL_Junho2021/HSL_Desfechos_4.csv' delimiter '|' csv header;

-- Tratamento dos dados

update pacientes set aa_nascimento = '1930' where aa_nascimento = 'AAAA';
update pacientes set aa_nascimento = null where aa_nascimento = 'YYYY';
alter table pacientes alter column aa_nascimento type integer using aa_nascimento::integer;


------------------- EXERC�CIO 02 -------------------

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

-- Conta quantos homens e mulheres nasceram em cada decada (O valor NULL corresponde � pessoas que nao tem dados)
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
select count(id_exame) as qnt_exames_covid from exames e where de_analito = 'Coronav�rus (2019-nCoV)';

-- Conta quantos exames de covid possuem resultado positivo
select count(id_exame) as qnt_exames_covid_positivo from exames e where de_analito = 'Coronav�rus (2019-nCoV)' and de_resultado like 'DETECTADO%';

-- Quest�o estranha, perguntar pro prof
select p.aa_nascimento, count(e.de_resultado) from exames e
join pacientes p on p.id_paciente = e.id_paciente 
where de_analito = 'Coronav�rus (2019-nCoV)'
group by p.aa_nascimento
order by p.aa_nascimento asc;

-- 2.4
select mode() within group (order by de_desfecho) from desfechos;

select d.de_desfecho, d.id_paciente from desfechos d where lower(d.de_desfecho) <> 'alta administrativa'

select mode() within group (order by de_desfecho) from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
where d.id_paciente = 'DDE9B798AE77982101C3291C2DE47074';
