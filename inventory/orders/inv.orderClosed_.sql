declare @barcodes table (barcodeid int, styleid int)

insert @barcodes (barcodeid, styleid)
select i.barcodeID, b.styleID
from inv.orders o 
	join inv.inventory i on i.transactionID=o.orderID
	join inv.barcodes b on b.barcodeID=i.barcodeID
where o.orderID = 81240	and i.logstateID = 8;

if OBJECT_ID('inv.orderClosed_') is not null drop function inv.orderClosed_
go
create function inv.orderClosed_(@orderid int) returns bit as 
begin
	declare @status bit;
	select @status =  count(p.pricesetID) 
		from inv.orders o
			join inv.styles s on s.orderID=o.orderID
			join inv.prices p on p.styleID= s.styleID
		where o.orderID=@orderid
	return @status
end
go

select inv.orderClosed_(68468)--(81240)

select  distinct s.orderid, p.pricesetID 
from inv.styles s
	left join inv.prices p on p.styleID=s.styleID
where s.brandID = inv.brand_id('james perse')
order by 1 desc