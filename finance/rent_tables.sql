use fanfan
go
declare @start_date date = '20220101'
select * from fin.gross_p_l_func(@start_date)
--select * from cmn.numbers
if OBJECT_ID('fin.rent') is not null drop table fin.rent
if OBJECT_ID('fin.rent_objects') is not null drop table fin.rent_objects
if OBJECT_ID('org.landlords') is not null drop table org.landlords
create table org.landlords (
	landlordid int not null constraint pk_landlords primary key
							constraint fk_landlords_contractors foreign key references org.contractors (contractorid)
)
insert org.landlords values (273), (364), (634)

create table fin.rent_objects (
	rent_objectid int not null identity constraint pk_rent_objects primary key,
	landlordid int not null constraint fk_rent_objects_landlords foreign key references org.landlords (landlordid),
	footage dec (10,2) not null, 
	obj_description varchar (125) not null
)
insert fin.rent_objects (landlordid, footage, obj_description)	values 
(364, 94.5, 'ТК Дримхаус, 2 этаж'), 
(364, 140, 'ТК Крокус СМ, 1 этаж, помещение 31'), 
(364, 150, 'ТК Крокус СМ, 1 этаж, помещение 32') 
select * from fin.rent_objects;

create table fin.rent (
	divisionid int not null,
	date_start date not null,
	date_finish date null,
	currencyid int not null, 
	currency_rate dec (8, 5) null, 
	rent_per_meter_year dec(10, 8) not null,
	VAT dec (3,2) default (0),
	turnover_rate dec(3,2) default (0),
	constraint pk_rent primary key (divisionid, date_start)
)
go 


select * from org.contractors c
where 
	c.contractor like '%дрим%' or
	c.contractor like 'dream' or
	c.contractor like '%кро%' or
	c.contractor like '%балтия%' 







