--select * from web.basket;select * from web.basketLogs;

if OBJECT_ID('web.customer_basket_') is not null drop function web.customer_basket_
go 
create function web.customer_basket_ (@phone char(10)) returns table as 
return
with s as(
	select distinct 
		bl.logid, 
		br.brand, 
		inventorytyperus category, 
		cl.color, 
		sz.size, 
		bl.qty, 
		bl.price, 
		bl.discount, 
		bl.promoDiscount
	from web.basketLogs bl 
		join web.basket ba on ba.logid=bl.logid
		join inv.barcodes b on b.sort_barcodeID=bl.sortCodeId
		join inv.styles s on s.styleID=b.styleID
		join inv.brands br on br.brandID=s.brandID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.colors cl on cl.colorID=b.colorID
		join inv.sizes sz on sz.sizeID = b.sizeID
	where ba.custid=cust.customer_id(@phone)
)
, f as (select 
	brand, category, color, size, price, discount, promoDiscount, sum(qty) qty, sum(price* qty*(1 -discount)*(1 -promoDiscount)) total 
	from s
	group by brand, category, color, size, s.price, discount, promoDiscount
	)
	select * , sum(total) over() gtotal
	from f
go 
declare @phone char(10) = '9167834248';
select * from web.customer_basket_(@phone)