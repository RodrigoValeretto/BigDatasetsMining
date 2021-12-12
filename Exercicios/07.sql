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
