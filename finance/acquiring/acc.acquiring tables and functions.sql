if OBJECT_ID ('acc.acquiring') is not null drop table acc.acquiring
if OBJECT_ID ('acc.cross_table_rectypes') is not null drop table acc.cross_table_rectypes
go
create table acc.cross_table_rectypes (
	acqType varchar(15) not null unique,
	acqTypeid int not null primary key,
)
insert acc.cross_table_rectypes values

('по карте', 5), 
('по QR-коду', 7), 
('по телефону', 8), 
('наличными', 1)

go
create table acc.acquiring (
	id int not null identity primary key,
	registerid int not null constraint fk_acquiring_registerid  foreign key references acc.registers (registerid),
	acqTypeid int not null  constraint fk_acq_types foreign key references acc.cross_table_rectypes (acqTypeid),
	rate dec (5, 4) not null default (0),
	days_off int not null default (0),
	datestart date not null, 
	datefinish date null, 
	constraint uq_acquiring unique (registerid, acqTypeid,  datestart)
)

declare @temp table (
	bank varchar(25), 
	client varchar(25),
	acqType varchar (25),
	rate dec (5, 4), 
	days_off int,
	datestart date
)
--if OBJECT_ID('tmp.acquiring') is not null drop table tmp.acquiring
--go 
--create table tmp.acquiring (
--	bank varchar(25), 
--	client varchar(25),
--	acqType varchar (25),
--	rate dec (5, 4), 
--	days_off int,
--	datestart date
--)

insert tmp.acquiring (bank, client, acqType, rate, days_off, datestart) values 
('АЛЬФА-БАНК', 'ИП Федоров', 'по карте', 0.021, 1, '2022.12.25'), 
('АЛЬФА-БАНК', 'ИП Федоров', 'по QR-коду', 0.004, 0, '2022.12.25'), 
('АЛЬФА-БАНК', 'ПРОЕКТ Ф', 'по карте', 0.021, 1, '2022.12.25'), 
('АЛЬФА-БАНК', 'ПРОЕКТ Ф', 'по QR-коду', 0.004, 0, '2022.12.25'), 
('АЛЬФА-БАНК', 'ФЕДОРОВ А. Н.', 'по телефону', 0, 0, '2022.12.25'), 
('ВТБ БАНК', 'ФЕДОРОВ А. Н.', 'по телефону', 0, 0, '2022.12.25'), 
('ПОЧТА БАНК', 'ФЕДОРОВ А. Н.', 'по телефону', 0, 0, '2022.12.25'), 
('СБЕРБАНК', 'ИП Федоров', 'по карте', 0.018, 1, '2022.12.25'), 
('СБЕРБАНК', 'ПРОЕКТ Ф', 'по карте', 0.018, 1, '2022.12.25'), 
('СБЕРБАНК', 'ФЕДОРОВ А. Н.', 'по телефону', 0, 0, '2022.12.25'), 
('ТИНЬКОФФ', 'ИП Федоров', 'по карте', 0.022, 1, '2022.12.15'), 
('ТИНЬКОФФ', 'ИП Федоров', 'по карте', 0.0179, 1, '2021.01.01'), 
('ТИНЬКОФФ', 'ПРОЕКТ Ф', 'по карте', 0.0229, 1, '2022.12.15'), 
('ТИНЬКОФФ', 'ПРОЕКТ Ф', 'по карте', 0.0179, 1, '2021.01.01'), 
('ТИНЬКОФФ', 'ФЕДОРОВ А. Н.', 'по телефону', 0, 0, '2022.12.15')
;


if OBJECT_ID('acc.acquiring_merge_p') is not null drop proc acc.acquiring_merge_p
go 
create proc acc.acquiring_merge_p 
as
	set nocount on;
	begin try
		begin transaction;			
			with s (registerid, acqTypeid, rate, days_off, datestart) as (
			select 
				r.registerid,
				a.acqTypeid,
				t.rate, 
				t.days_off, 
				t.datestart
			from  tmp.acquiring t
				join org.contractors c on c.contractor=t.bank
				join org.contractors cn on cn.contractor=t.client
				join acc.cross_table_rectypes a on a.acqType= t.acqType
				join acc.registers r on r.bankid= c.contractorid
					and r.clientid= cn.contractorID and r.currencyid =643 -- harcoding rouble
			)
			merge acc.acquiring as t using s
				on t.registerid = s.registerid
					and t.acqTypeid=s.acqTypeid
					and t.datestart=s.datestart
			when not matched then
				insert (registerid, acqTypeid, rate, days_off, datestart)
				values (registerid, acqTypeid, rate, days_off, datestart)
			when matched  and
				t.rate<>s.rate or
				t.days_off<>s.days_off
			then update set
				t.rate=s.rate,
				t.days_off=s.days_off
			when not matched by source then delete;

			truncate table tmp.acquiring;
		commit transaction
		return 1;
	end try
	begin catch
		select ERROR_MESSAGE();
		rollback transaction
	end catch
go

set nocount on; declare @r int;  exec @r = acc.acquiring_merge_p; select @r
--truncate table tmp.acquiring;
--select * from tmp.acquiring;
select * from acc.acquiring
if OBJECT_ID('acc.acquiring_v') is not null drop view acc.acquiring_v
go
create view acc.acquiring_v as
select 
	id, c.contractor bank, cn.contractor client, ct.acqType type, a.rate, a.days_off, 
	cast(datestart as datetime) datestart, cast(datefinish as datetime) datefinish
from acc.acquiring a
	join acc.registers r on r.registerid = a.registerid
	join org.contractors c on c.contractorID = r.bankid
	join org.contractors cn on cn.contractorID=r.clientid
	join acc.cross_table_rectypes ct on ct.acqTypeid	= a.acqTypeid
go

select * from acc.acquiring_v


