set nocount on;

if OBJECT_ID('web.baskets') is not null drop table web.baskets
if OBJECT_ID('web.logs') is not null drop table web.logs
if OBJECT_ID('web.basketProcs') is not null drop table web.basketProcs


create table web.basketProcs (
	procid int not null identity primary key, 
	procName char(36) not null unique
)
insert web.basketProcs values ('select'), ('insert'), ('delete'), ('merge')

create table web.logs (
	logid int not null identity primary key, 
	uuid char(36)  null,
	custid int  null foreign key references cust.persons (personid), 
	logdate datetime not null default current_timestamp
)

create table web.baskets (
	logid int not null foreign key references web.logs (logid), 
	parent_styleid int not null, 
	color varchar (50) not null, 
	size varchar(20) not null, 
	qty int not null
)
------------------------------------------------------------------------------------------------------------




declare @json varchar(max) 
select @json =
/*
	{"styleid": "19628", "color": "blUE NAVY", "size": "XXXL", "qty": "2"},
*/
'[
	{"styleid": "13530", "color": "WHITE", "size": "3", "qty": "1"}, 
	{
		"phone": "9167834248", 
		"uuid": "735d8d32-5wdc-46cd-814c-907753956fdb",
		"procName": "insert" 
	} 
]';



--exec web.basketAction_p @json






declare @resp varchar(max) = '[{"this":1,"maximum":1,"total":1}]'





