use fanfan
go

-- 20250619_CreateOrdersTable.sql

IF  OBJECT_ID('cust.visit')  is not null drop table cust.visit;
IF  OBJECT_ID('cust.visitAction')  is not null drop table cust.visitAction;
if OBJECT_ID ('cust.visitorType') is not null drop table cust.visitorType;
create table cust.visitorType (
	id int primary key identity (1,1)
	, visitorType varchar (10)
)
insert cust.visitorType values 
('муж'), 
('жен'), 
('семья'), 
('друзья'); 

create table cust.visitAction (
		id int primary key identity(1,1) 
	,	actionName varchar(255) not null
)
insert cust.visitAction values 
('быстрый просмотр'), 
('внимательный просмотр'), 
('примерка'), 
('отложка'), 
('переброс')

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[cust].[visit]') AND type = 'U')

CREATE TABLE cust.visit (
    ID INT PRIMARY KEY IDENTITY(1,1)
    , divisionid int not null foreign key references org.divisions (divisionid)
	, userid int foreign key references org.users (userid)
    , visitTime DATETIME  default current_timestamp
    , actionid int not null foreign key references cust.visitAction (id)
	, visitorTypeid int foreign key references cust.visitorType(id)
);



select * from cust.visit
select * from cust.visitorType