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
----------------------- EXERCICIO 02 -----------------------

-- 2.1
-------------------- TABELA Pacientes
-------- ID_PACIENTE
-- Numero de Pacientes
select count(id_paciente) as n_atendimentos from pacientes p;

-------- IC_SEXO
-- Distribuicao dos sexos
select ic_sexo, count(ic_sexo) from pacientes p
group by ic_sexo;

-------- AA_NASCIMENTO
-- Numero de Idades Anonimizadas (nulas apos nossa limpeza)
select count(*) as n_nulos_idade from pacientes p
where aa_nascimento is null;
-- Variancia da idade
select var_samp(aa_nascimento) from pacientes p;
-- Desvio Padrao da idade
select stddev_samp(aa_nascimento) from pacientes p;

-------- CD_PAIS
-- Numero de Estrangeiros
select count(*) as n_estrangeiros from pacientes p
where cd_pais = 'XX';

-------- CD_UF
-- Distribuicao dos UF
select cd_uf, count(cd_uf) from pacientes p
where cd_uf is not null
group by cd_uf;
-- Numero de Anonimizados (nulos apos nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_uf is null;

-------- CD_MUNICIPIO
-- Distribuicao dos Municipios
select cd_municipio, count(cd_municipio) from pacientes p
where cd_municipio is not null
group by cd_municipio;
-- Numero de Anonimizados (nulos apos nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_municipio is null;

-------- CD_CEPREDUZIDO
-- Distribuicao dos CEPS
select cd_cepreduzido, count(cd_cepreduzido) from pacientes p
where cd_cepreduzido is not null
group by cd_cepreduzido;
-- Numero de Anonimizados (nulos apos nossa limpeza)
select count(*) as n_nulos from pacientes p
where cd_cepreduzido is null;

-------------------- TABELA Exames
-------- ID_PACIENTE
-- Numero de pacientes que pediram exames
select count(distinct id_paciente) as n_atendimentos from exames e;

-------- ID_ATENDIMENTO
-- Numero de atendimentos
select count(distinct id_atendimento) as n_atendimentos from exames e;
-- Media de exames por atendimento
select
	avg(numero_exames)
from
	(
	select
		count(*) over (partition by id_atendimento) numero_exames
	from
		exames e) as a;

-------- DT_COLETA
-- Media de coletas por dia
select
	avg(numero_coletas) as media_coletas_dia
from
	(
	select
		count(*) over (partition by dt_coleta) numero_coletas
	from
		exames e) as a;

-------- DE_ORIGEM
-- Numero de origens existentes
select count(distinct de_origem) as n_origens from exames e;
-- Distribuicao das origens
select de_origem, count(de_origem) from exames e
where de_origem is not null
group by de_origem;

-------- DE_EXAME
-- Numero total de exames realizados
select count(de_exame) as numero_exames from exames e;
-- Numero de tipos de exames existentes na tabela
select count(distinct de_exame) as numero_distinto_exames from exames e;

-------- DE_ANALITO
-- Numero de tipos de analitoss existentes na tabela
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

-- Desfechos maioria por dÃ©cada de vida
select floor(aa_nascimento/10)*10 as decada, mode() within group (order by de_desfecho) desfecho_maioria from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
group by decada;

-- Desfechos maioria por idade
select (2020 -aa_nascimento) as decada, mode() within group (order by de_desfecho) desfecho_maioria from desfechos d
join pacientes p on d.id_paciente = p.id_paciente
group by decada;
