use fanfan
go

-- unless there is change in table structure  - no more runs!


declare @start_date date = '20220101'
--select * from fin.gross_p_l_func(@start_date)
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
	rent_objectid int not null,
	date_start date not null,
	date_finish date null,
	currencyid int not null, 
	currency_rate dec (8, 5) null, 
	rent_per_meter_year money null,
	fixed_per_month money default (0),
	VAT dec (3,2) default (0),
	turnover_rate dec(3,2) default (0),
	constraint pk_rent primary key (divisionid, date_start)
)
go 
insert fin.rent (divisionid, rent_objectid, date_start, currencyid, rent_per_meter_year, VAT, turnover_rate )
select 
	18, 1, '20220819', 840, 50, .20, .15
insert fin.rent (divisionid, rent_objectid, date_start, currencyid, fixed_per_month,  VAT, turnover_rate )
values  
	(25, 2, '20220801', 840, 200, .20, .13), 
	(27, 3, '20220801', 840, 200, .20, .13)
select * from fin.rent