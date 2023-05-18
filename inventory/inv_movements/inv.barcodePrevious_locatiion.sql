use fanfan	
go

if OBJECT_ID('inv.barcodePrevious_locatiion') is not null drop function inv.barcodePrevious_locatiion
go
create function inv.barcodePrevious_locatiion (@barcodeid int) returns table as 
return
with _transaction(transactionid) as (
	select distinct top 1 
		i.transactionID
	from inv.inventory i
	where i.barcodeid = @barcodeid
	order by i.transactionID desc
)
select i.logstateID, i.divisionID
from inv.inventory i 
cross apply _transaction t
where i.barcodeID=@barcodeid and i.transactionID < t.transactionid
group by i.logstateid, i.divisionid
having sum (i.opersign) = 1
go
declare @barcodeid int = 658777, @transactionid int = 77537;
select distinct
	i.transactionID 
from inv.inventory i
where i.barcodeID=@barcodeid
order by 1 desc

go
declare @barcodeid int = 658765
select * from  inv.barcodePrevious_locatiion(@barcodeid) pl;
