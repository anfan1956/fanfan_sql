
;
if OBJECT_ID('inv.invTake_info_') is not null drop function inv.invTake_info_
go
create function inv.invTake_info_(@barcodeid int) returns table as return


	with CTE (brand, article, cost, barcodeid, orderid, orderType, category, color, size, showroom ) as (
		select brand, b.article, b.cost, barcodeID, b.orderID, b.orderType, b.category, b.color, b.size, b.showroom
		from  inv.barcode_props_(@barcodeid) b
		

	)
	select 
		c.brand, c.article, c.cost, c.barcodeid, c.orderID, c.orderType, c.category,
		c.color, c.size,
		ls.logstate [status], ls.divisionfullname shop, ls.transactiontype lastTran, 
		ls.transactiondate lastTranDate, c.showroom
	from CTE c
	join	(
			select top 1 l.logstate, i.barcodeID, d.divisionfullname, tt.transactiontype, t.transactiondate 
			from inv.inventory i 
				join inv.logstates l on l.logstateID=i.logstateID 
				join org.divisions d on d.divisionID= i.divisionID
				join inv.transactions t on t.transactionID = i.transactionID
				join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
			where i.barcodeID = @barcodeid
			order by i.transactionID 
			) as ls on ls.barcodeID = c.barcodeid
go

declare @barcodeid int = 668342;
select 
	brand, article, cost, barcodeid, orderID, orderType, category, color, size, status, shop, lastTran, lastTranDate, showroom
from inv.invTake_info_(@barcodeid)

select brand, article, cost, barcodeid, orderID, orderType, category, color, size, status, shop, lastTran, lastTranDate, showroom from inv.invTake_info_(666706)
;
	select 
		i.barcodeID, logstateID,
--		i.divisionID, 
		sum(i.opersign) sumof
	from inv.inventory i
	where i.barcodeID = @barcodeid
	group by i.barcodeID, 
		--i.divisionID,
		logstateID 
	having sum(i.opersign)>0
go
