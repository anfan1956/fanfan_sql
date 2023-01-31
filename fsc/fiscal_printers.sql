use fanfan
go

if OBJECT_ID('fsc.ccts_divisions') is not null drop table fsc.ccts_divisions
if OBJECT_ID('fsc.f_registrations') is not null drop table fsc.f_registrations
if OBJECT_ID('fsc.CCTs') is not null drop table fsc.CCTs
--go 
create table fsc.CCTs (
	cctid int not null identity primary key,
	cct_factoryid varchar (50) not null unique, 
	model varchar (25) not null, 
	manufactured_date date not null, 
	cctname varchar(25)
)

create table fsc.f_registrations (
	regid int not null identity primary key,
	cctid int not null foreign key references fsc.CCTS(cctid),
	regnum char(16) not null,
	regdate date null,
	regexpire date null, 
	clientid int foreign key references org.clients (clientid)
)

create table fsc.ccts_divisions (
	cctid int foreign key references fsc.CCTs (cctid),  
	divisionid int foreign key references org.divisions (divisionid),  
	datestart date not null,
	datefinish date null, 
	primary key (cctid, divisionid, datestart), 
	unique (cctid, datestart)
)
go
declare @date date = '20230123'
insert fsc.CCTs (cct_factoryid, model, manufactured_date, cctname) values 
('00105702687153', 'АТОЛ 25Ф', '20170120', 'johnny'), 
('00105702686501', 'АТОЛ 25Ф', '20170120', 'peter'), 
('00108728989932', 'АТОЛ 27Ф', '20210420', 'misha'),  
('00108723706768', 'АТОЛ 27Ф', '20210220', 'jimmy')  
;
insert fsc.f_registrations (cctid, regnum, regdate, regexpire, clientid) 
values 
(2, '0001347729022957', '20191216', null, 187), 
(2, '0001308055045483', '20230321', '20220706', 187),
(3, '000777197006485', null, '20240906', 619), 
(4, '0005625170043743', null, '20240901', 619) 

insert fsc.ccts_divisions (cctid, divisionid, datestart) values
(3, 27, @date), 
(4, 25, @date) 

--select * from fsc.CCTs
--select * from fsc.f_registrations
select c.*, d.divisionfullname, cctname
from fsc.ccts_divisions c
	join org.divisions d on d.divisionID = c.divisionid
	join fsc.CCTs ct on ct.cctid=c.cctid

if OBJECT_ID('fsc.ccts_current_v') is not null drop view fsc.ccts_current_v
if OBJECT_ID('fsc.ccts_current_f') is not null drop view fsc.ccts_current_f
go
create view fsc.ccts_current_v as
with s (cctid, divisionid, datestart, num) as (
	select 
		cd.cctid, 
		cd.divisionid, 
		datestart, 
		ROW_NUMBER() over(partition by cd.cctid order by cd.datestart desc ) 
	from fsc.ccts_divisions cd
)
select cctid, divisionid, datestart 
from s
where s.num =1
go

select * from fsc.ccts_current_v
if OBJECT_ID('fsc.cct_mode') is not null drop table fsc.cct_mode
create table fsc.cct_mode (
	divisionid int foreign key references org.divisions (divisionid), 
	dev_mode bit not null default ('False'), 
	fiscal_mode bit not null default ('True')
)
;
with _sales_divisions (divisionid) as (
select divisionid
from org.retail_active_v
)
insert fsc.cct_mode(divisionid, dev_mode, fiscal_mode)
select 
	s.divisionid, d.dev_mode, 
	case d.dev_mode 
		when 'True' then 'False'
		else 'True' end
	fiscal_mode 
from _sales_divisions s
		cross apply (select 'True' dev_mode union select 'False') d
;
--select * from fsc.cct_mode

if OBJECT_ID('fsc.terminal_mode') is not null drop function fsc.terminal_mode
go 
create function fsc.terminal_mode (@divisionid int, @dev_mode bit) returns varchar(7) as 
begin 
	declare @mode varchar(7);
		select @mode = iif(fiscal_mode = 'True', 'online', 'offline') 
		from org.retail_active_v v
			join fsc.cct_mode f on f.divisionid=v.divisionid
		where v.divisionid = @divisionid and f.dev_mode = @dev_mode
	return @mode;
end
go
declare @devmode bit = 'True'
select fsc.terminal_mode(d.divisionID, @devmode) from org.divisions d 
where d.divisionfullname = '05 Уикенд'

if OBJECT_ID ('fsc.cct_mode_switch_p') is not null drop proc fsc.cct_mode_switch_p
go 
create proc fsc.cct_mode_switch_p @divisionid int, @dev_mode bit 
as
set nocount on;
begin
	update c set c.fiscal_mode = 1 - c.fiscal_mode 
	from fsc.cct_mode c 
	where c.divisionid = @divisionid and c.dev_mode = @dev_mode;
end
go
set nocount on; declare @divisionid int = 27, @dev_mode bit = 'True';
declare @r int;
exec @r = fsc.cct_mode_switch_p @divisionid, @dev_mode;
select @r

--select c.fiscal_mode
--from fsc.cct_mode c 
--where c.divisionid = @divisionid and c.dev_mode = @dev_mode




	