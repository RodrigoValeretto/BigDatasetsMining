------------------------------------------------------------
/*
	Trabalho SCC0244 - Mineração de grandes bases de dados 
	Alunos:
	João Pedro Fidelis Belluzzo		NUSP: 10716661
	Leonardo Cerce Guioto			NUSP: 10716640
	Rodrigo Augusto Valeretto		NUSP: 10684792
*/
------------------------------------------------------------

-- Criando Database e Schema
create database "fapesp-covid19";
create schema "hsl";

-- Criando tabelas principais
drop table if exists Pacientes;
create table Pacientes(
	id_paciente char(32) primary key,
	ic_sexo char(1) check (ic_sexo in ('M', 'F')),
	aa_nascimento int check (aa_nascimento between 1850 and 2021),
	cd_pais char(2),
	cd_uf char(2),
	cd_municipio text,
	cd_cepreduzido varchar(5)
);

drop table if exists Exames;
create table Exames(
	id_paciente char(32),
	id_atendimento char(32) primary key,
	dt_coleta date,
	de_origem varchar(4),
	de_exame varchar(50),
	de_analito varchar(50),
	de_resultado varchar(50),
	cd_unidade varchar(10),
	de_valor_referencia varchar(50),
	constraint id_paciente_fk foreign key (id_paciente) references Pacientes(id_paciente) on delete cascade
);

drop table if exists Desfechos;
create table Desfechos(
	id_paciente char(32),
	id_atendimento char(32) primary key,
	dt_atendimento date,
	de_tipo_atendimento text,
	id_clinica int,
	de_clinica text,
	dt_desfecho date,
	de_desfecho text,
	constraint id_paciente_fk foreign key (id_paciente) references Pacientes(id_paciente) on delete cascade,
	constraint id_atendimento_fk foreign key (id_atendimento) references Exames(id_atendimento) on delete cascade
);

-- Preenchendo tabelas com valores do csv
copy Pacientes(id_paciente, ic_sexo, aa_nascimento, cd_pais, cd_uf, cd_municipio, cd_cepreduzido) from 'C:/Users/rodri/Desktop/Repositorios/Coding/BigDatabaseMining/CSVs/HSL_Pacientes_4.csv' delimiter '|' csv header;