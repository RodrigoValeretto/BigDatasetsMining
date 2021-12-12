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