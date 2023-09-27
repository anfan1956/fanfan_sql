if OBJECT_ID ('cust.notify_prefs') is not null drop table cust.notify_prefs
go
create table cust.notify_prefs
(
	custid int not null foreign key references cust.persons (personid), 
	decisionDate datetime not null default (current_timestamp), 
	receipts bit not null, 
	collections bit not null,
	sales bit not null, 
	promos bit not null, 
	primary key (custid, decisionDate)
)


if OBJECT_ID('cust.prefs_update') is not null drop proc cust.prefs_update
go
create proc cust.prefs_update @json varchar(max) as
set nocount on;
with s (phone, receipts, collections, sales, promos) as (
	select phone, receipts, collections, sales, promos 
	from OPENJSON(@json)
	with (
		phone char(10)  '$.phone', 
		receipts bit '$.receipts', 
		collections bit '$.collections', 
		sales bit '$.sales',
		promos bit '$.promos'
	) as jsonValues
)
insert cust.notify_prefs (custid, receipts, collections, sales, promos)
select cust.customer_id(phone), receipts, collections, sales, promos
from s;
select @@ROWCOUNT;

go

--select * from cust.persons p where p.personID = 17448
declare @json varchar(max) =
	'[
		{"phone":"9167834248", "receipts":1, "collections":1, "sales":1, "promos":0} 
	]'
;
exec cust.prefs_update @json
select * from cust.notify_prefs