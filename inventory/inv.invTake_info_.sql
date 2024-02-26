
;
if OBJECT_ID('inv.invTake_info_') is not null drop function inv.invTake_info_
go
create function inv.invTake_info_(@barcodeid int) returns table as return
with 
_b (barcodeid, logstateid, divisionid) as (
	select 
		i.barcodeID, logstateID,
		i.divisionID
	from inv.inventory i
	where i.barcodeID = @barcodeid
	group by i.barcodeID, logstateID, i.divisionID
	having sum(i.opersign)>0
)
, _lastTran (transactionid) as (
	select top 1 i.transactionID
	from inv.inventory i
	where i.barcodeID=@barcodeid
	order by 1 desc
)
select 
	br.brand, 
	article, 
	s.cost, 
	b.barcodeid, 
	o.orderID,
	oc.orderclass orderType,
	it.inventorytyperus category, 
	c.color, 
	sz.size, 
	ls.logstate status, 
	d.divisionfullname shop, 
	tt.transactiontype lastTran, 
	t.transactiondate lastTranDate, 
	cn.contractor showroom

from _b b
	cross apply _lastTran lt
	join inv.transactions t on t.transactionID=lt.transactionid
	join inv.barcodes bc on bc.barcodeID=b.barcodeid
	join inv.styles s on s.styleID=bc.styleID
	join inv.orders o on o.orderID=s.orderID
	join inv.orderclasses oc on oc.orderclassID=o.orderclassID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.colors c on c.colorID=bc.colorID
	join inv.sizes sz on sz.sizeID=bc.sizeID
	join inv.logstates ls on ls.logstateID=b.logstateid
	join org.divisions d on d.divisionID= b.divisionid
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	left join org.contractors cn on cn.contractorID=o.showroomID
go

declare @barcodeid int = 667861;
select 
	brand, article, cost, barcodeid, orderID, orderType, category, color, size, status, shop, lastTran, lastTranDate, showroom
from inv.invTake_info_(@barcodeid)

select brand, article, cost, barcodeid, orderID, orderType, category, color, size, status, shop, lastTran, lastTranDate, showroom from inv.invTake_info_(666706)
;
go
