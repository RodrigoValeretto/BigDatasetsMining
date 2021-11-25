------------------------------------------------------------
/*
	Trabalho SCC0244 - Mineracao de grandes bases de dados 
	Alunos:
	Joao Pedro Fidelis Belluzzo		NUSP: 10716661
	Leonardo Cerce Guioto			NUSP: 10716640
	Rodrigo Augusto Valeretto		NUSP: 10684792
*/
------------------------------------------------------------

-- Criando Database e Schema
create database "fapesp-covid19";
create schema "hsl";

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
	dt_desfecho date,
	de_desfecho text,
	constraint id_paciente_fk foreign key (id_paciente) references Pacientes(id_paciente) on delete cascade,
	constraint pk_desfechos primary key (id_paciente, id_atendimento)
);

SET datestyle = 'ISO,DMY';
-- Preenchendo tabelas com valores dos csvs
copy Pacientes from '/HSL_Junho2021/HSL_Pacientes_4.csv' delimiter '|' csv header;

copy Exames(id_paciente, id_atendimento, dt_coleta, de_origem, de_exame, de_analito, de_resultado, cd_unidade, de_valor_referencia)
from '/HSL_Junho2021/HSL_Exames_4.csv' delimiter '|' csv header;

copy Desfechos from '/HSL_Junho2021/HSL_Desfechos_4.csv' delimiter '|' csv header;



