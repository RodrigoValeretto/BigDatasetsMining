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

-- Trocando o valor do Municipio para nulo nos dados anonimizados ou de estrangeiros
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