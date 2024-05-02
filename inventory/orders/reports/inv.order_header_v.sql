USE fanfan
GO

if OBJECT_ID('inv.order_header_v') is not null drop view inv.order_header_v
go
create view inv.order_header_v as

with s (client, showroom, vendor, brand, season, gender, order_date, orderid, orderType, currency, total_pieces, amount) as (select 
 
	bu.contractor client, 
	c.contractor showroom, 
	ve.contractor,
	b.brand, 
	se.season, 
	case o.gender 
		when 'm' then 'муж'
		when 'f' then 'жен'
		else null end gender,
	t.transactiondate order_date, 
	o.orderID, 
	oc.orderclassRus,
	cr.currencycode currency,
	count(br.barcodeID) [total pieces] , sum(br.cost* (1-o.orderdiscount)) amount
	
from inv.orders o
	join inv.orderclasses oc on oc.orderclassID=o.orderclassID
	join inv.transactions t on t.transactionID=o.orderID
	left join inv.brands b on b.brandID=o.brandID
	left join inv.seasons se on se.seasonID=o.seasonID
	left join org.contractors c on c.contractorID=o.showroomID
	join org.contractors ve on ve.contractorID=o.vendorID
	join org.contractors bu on bu.contractorID=o.buyerID
	left join inv.barcode_info_v br on br.orderID=o.orderID
	join cmn.currencies cr on cr.currencyID=o.currencyID
	left join pmt.payment_orders po on po.orderid=o.orderID	

group by 
	b.brand, se.season, c.contractor, bu.contractor , t.transactiondate, o.orderID, cr.currencycode, 
	o.gender, ve.contractor, oc.orderclassRus
)
select 
	s.client, showroom, vendor, brand, season, gender, order_date, s.orderid, s.orderType, currency, total_pieces, s.amount, 
	sum (po.amount) paid, inv.orderClosed_(s.orderid) closed
from s
	left join pmt.payment_orders po on po.orderid=s.orderid
group by client, showroom, vendor, brand, season, gender, order_date, s.orderid, s.orderType, currency, total_pieces, s.amount	
	;
GO

declare @date date = '20240309';

select * from inv.order_header_v where order_date>= @date  order by orderid desc ;
with _inv as (
	select  
		i.clientID, i.transactionID, inv.barcodeShowroom_(i.barcodeID) showroom, 
		inv.barcodeVendor_(i.barcodeID) vendor, se.season, br.brand, b.barcodeID, s.cost
	from inv.inventory i		
		join inv.barcodes b on b.barcodeID = i.barcodeID
		join inv.styles s on s.styleID = b.styleID
		join inv.seasons se on se.seasonID=s.seasonID
		left join inv.brands br on br.brandID=s.brandID
)
select 
	cl.clientRus, i.showroom, i.vendor, i.brand, i.season, t.transactiondate, t.transactionID, tt.transactiontype, 
	count(i.barcodeID) pieces, sum(i.cost) amount, null paid, 1 closed
	
from inv.transactions t
	join _inv i on i.transactionID=t.transactionID
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	join org.clients cl on cl.clientID=i.clientID
where tt.transactiontype in ('order','consignment','consignment return') and DATEPART(YYYY, t.transactiondate)>=2024
group by cl.clientRus, i.showroom, i.vendor, i.brand, i.season, t.transactiondate, t.transactionID, tt.transactiontype 
order by t.transactionID desc
