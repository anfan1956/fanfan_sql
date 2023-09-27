if OBJECT_ID ('cust.notify_prefs') is not null drop table cust.notify_prefs
go
create table cust.notify_prefs
(
	prefid int not null identity primary key, 
	custid int not null foreign key references cust.persons (personid), 
	decisionDate datetime not null default (current_timestamp), 
	receipts bit not null, 
	collections bit not null,
	sales bit not null, 
	promos bit not null, 
	unique (custid, decisionDate)
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

if OBJECT_ID('cust.customer_prefs') is not null drop function cust.customer_prefs
go
create function cust.customer_prefs (@phone char(10)) returns varchar(max) as
begin
	declare @prefs varchar(max);
	select @prefs = (
		select 	top 1 receipts, collections, sales, promos from cust.notify_prefs n
		where n.custid = cust.customer_id(@phone)
		order by n.prefid desc for json path
	)
	if @prefs is null select @prefs = (select 'no prefs' prefs for json path);

	return @prefs
end 
go

declare @phone char(10) = '9637633465'
select cust.customer_prefs (@phone)



--select * from cust.persons p where p.personID = 17448
declare @json varchar(max) =
	'[
		{"phone":"9167834248", "receipts":1, "collections":1, "sales":1, "promos":0} 
	]'
;
exec cust.prefs_update @json
select * from cust.notify_prefs