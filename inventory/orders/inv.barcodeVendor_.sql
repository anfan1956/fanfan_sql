if OBJECT_ID('inv.barcodeVendor_') is not null drop function inv.barcodeVendor_
go
create function inv.barcodeVendor_(@barcodeid int) returns varchar(max) as 
begin
declare @vendor varchar(max)
	select distinct @vendor= c.contractor 
	from inv.inventory i 
		join inv.orders o on o.orderID=i.transactionID
		join org.contractors c on c.contractorID=o.vendorID
	where i.barcodeID = @barcodeid
	return @vendor
end
go
select inv.barcodeShowroom_(667862)
select inv.barcodeVendor_(667862)

select brand, article, cost, barcodeid, orderid, category, color, size, 
status, shop, lastTran, lastTranDate
from inv.invTake_info_(667862)