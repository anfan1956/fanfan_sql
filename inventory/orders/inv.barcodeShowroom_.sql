if OBJECT_ID('inv.barcodeShowroom_') is not null drop function inv.barcodeShowroom_
go
create function inv.barcodeShowroom_(@barcodeid int) returns varchar(max) as 
begin
declare @showroom varchar(max)
	select distinct @showroom = c.contractor 
	from inv.inventory i 
		join inv.orders o on o.orderID=i.transactionID
		join org.contractors c on c.contractorID=o.showroomID
	where i.barcodeID = @barcodeid
	return @showroom
end
go
select inv.barcodeShowroom_(667862)

