use fanfan
go

if OBJECT_ID('inv.barcode_lastsale_id') is not null drop function inv.barcode_lastsale_id
go
create function inv.barcode_lastsale_id (@barcodeid int) returns int as
begin 
	declare @saleid int;
	with lt (transactionid) as (
		select top 1  i.transactionID
		from inv.inventory i
		where i.barcodeid = @barcodeid
		order by i.transactionID desc, i.opersign desc
	)
	, ls (saleid, num) as (
		select 
			i.transactionID, 
			ROW_NUMBER() over (order by i.transactionid desc)
		from inv.inventory i 
			where i.barcodeID = @barcodeid
			and i.logstateID = inv.logstate_id('SOLD')
	)
	select  @saleid =
		case when ls.saleid=lt.transactionid then ls.saleid
		else 0 end
	from ls
		cross apply lt
	where ls.num =1;
	if @saleid is null select @saleid =0;
	return @saleid
end 
go

if OBJECT_ID('cust.customer_id_name') is not null drop function cust.customer_id_name
go
create function cust.customer_id_name (@saleid int ) returns table as return
	select s.customerID, lfmname customer, c.connect
		from inv.sales s 
			join cust.persons p on p.personID =s.customerID
			join cust.connect c on c.personID = s.customerID 
				and c.connecttypeID=1 and c.prim = 'true'
		where s.saleID= @saleid
go

declare @barcodeid int = 658826
declare @saleid int = inv.barcode_lastsale_id (@barcodeid);

--select customerid, customer, connect from cust.customer_id_name(@saleid);

	with lt (transactionid) as (
		select top 1  i.transactionID
		from inv.inventory i
		order by i.transactionID desc, i.opersign desc
	)
	, ls (saleid, num) as (
		select 
			i.transactionID, 
			ROW_NUMBER() over (order by i.transactionid desc)
		from inv.inventory i 
			where i.barcodeID = @barcodeid
			and i.logstateID = inv.logstate_id('SOLD')
	)
	select * from 
	--ls
	lt