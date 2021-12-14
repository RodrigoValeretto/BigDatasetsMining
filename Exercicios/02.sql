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

-- Funcao para calcular estatisticas de tabelas, retirada do materia de aula, e modificada levemente para nao calcular desvio padrao e variancia dos ids
create or replace
function MinhasEstatisticas(Tab text) returns table(NomeAtrib text, Tipo text, nulls INTEGER, Cardinalidade INTEGER, Variancia DOUBLE precision, DesvioPadrao DOUBLE precision) as $$
declare
	Var_r Record;

Var_Cmd text;

Var_Cmd2 text;

begin Var_Cmd = 'SELECT A.AttName::TEXT AN, T.TypName::TEXT ATy
FROM pg_Class C, pg_attribute A, pg_type T
WHERE C.RelName NOT LIKE ''pg_%'' AND C.RelName NOT LIKE ''sql_%'' AND
C.RelKind=''r'' AND
A.AttRelId=C.OID AND
A.AttTypId=T.OID AND A.AttNum>0 AND
C.RelName = ''' || Tab || '''';

for Var_r in execute Var_Cmd loop Var_Cmd2 := 'SELECT Count(*) from ' || Tab || ' WHERE ' || Var_r.AN || ' IS NULL;';

execute Var_Cmd2
into
	nulls;

Var_Cmd2 := 'SELECT Count(DISTINCT ' || Var_r.AN || '), ';

if Var_r.ATy in('int2', 'int4', 'int8', 'float4', 'float8', 'numeric')
and Var_r.AN not ilike '%id%' then Var_Cmd2 := Var_Cmd2 || 'Var_Pop(' || Var_r.AN || '), stddev_pop(' || Var_r.AN || ')';
else Var_Cmd2 := Var_Cmd2 || 'NULL, NULL';
end if;

Var_Cmd2 := Var_Cmd2 || ' FROM ' || Tab || ';';

execute Var_Cmd2
into
	Cardinalidade,
	Variancia,
	DesvioPadrao;

NomeAtrib := Var_r.AN;

Tipo := Var_r.ATy;

return next;
end loop;
end;
$$ language plpgsql;

/*
 * Estatisticas Gerais das tabelas. 
*/
select * from MinhasEstatisticas('pacientes');
select * from MinhasEstatisticas('exames');
select * from MinhasEstatisticas('desfechos');

/*
 * Algumas consultas mais especificas.
*/
-- Distribuicao dos sexos na tabela pacientes
select ic_sexo, count(ic_sexo) from pacientes p
group by ic_sexo;

-- Numero de Estrangeiros na tabela pacientes
select count(*) as n_estrangeiros from pacientes p
where cd_pais = 'XX';

-- Distribuicao dos UF na tabela pacientes
select cd_uf, count(cd_uf) from pacientes p
where cd_uf is not null
group by cd_uf;

-- Distribuicao dos Municipios na tabela pacientes
select cd_municipio, count(cd_municipio) from pacientes p
where cd_municipio is not null
group by cd_municipio;

-- Distribuicao dos CEPS na tabela pacientes
select cd_cepreduzido, count(cd_cepreduzido) from pacientes p
where cd_cepreduzido is not null
group by cd_cepreduzido;

-- Media de exames por atendimento na tabela exames
select
	avg(numero_exames)
from
	(
	select
		count(*) over (partition by id_atendimento) numero_exames
	from
		exames e) as a;

-- Media de coletas por dia na tabela exames
select
	avg(numero_coletas) as media_coletas_dia
from
	(
	select
		count(*) over (partition by dt_coleta) numero_coletas
	from
		exames e) as a;

-- Distribuicao das origens na tabela exames
select de_origem, count(de_origem) from exames e
where de_origem is not null
group by de_origem;

-- Media de atendimentos por dia na tabela atendimentos
select
	avg(numero_atendimentos) as media_atendimentos
from
	(
	select
		count(*) over (partition by dt_atendimento) numero_atendimentos
	from
		desfechos d) as a;

-- Distribuicao dos tipos de atendimento na tabela atendimentos
select de_tipo_atendimento, count(de_tipo_atendimento) from desfechos d
where de_tipo_atendimento is not null
group by de_tipo_atendimento;

-- Media de desfechos por dia na tabela atendimentos
select
	avg(numero_desfechos) as media_atendimentos
from
	(
	select
		count(*) over (partition by dt_desfecho) numero_desfechos
	from
		desfechos d) as a;

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
