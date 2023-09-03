if OBJECT_ID('web.customer_basket_v') is not null drop view web.customer_basket_v
go 
create view web.customer_basket_v  as 
with s (logid, parentid, brand, category, color, size, price, discount, promoDiscount,  qty, custid) as (
	select 
		bl.logid, 
		bl.parent_styleid,
		br.brand, t.inventorytyperus category, 
		cmn.norm_( bl.color), 
		bl.size, 
		c.price, 
		c.discount, 
		isnull(a.promo_discount, 0)		promoDiscount, 
		bl.qty, 
		b.custid
	from web.baskets bl
		join web.logs b on b.logid=bl.logid
		join inv.styles s on s.parent_styleid= bl.parent_styleid
		join inv.brands br on br.brandID=s.brandID
		join inv.inventorytypes t on t.inventorytypeID=s.inventorytypeID
		join inv.barcodes bc on bc.styleID=s.styleID
		join inv.styles_catalog_v c on c.styleid=bl.parent_styleid
		left join web.styles_discounts_active_ a on a.styleid=bl.parent_styleid

	group by 
		bl.logid, bl.parent_styleid, br.brand, t.inventorytyperus, 
		cmn.norm_( bl.color), bl.size, bl.qty, 
		b.custid, 
		c.price,c.discount, 
		promo_discount 
	)	select 
		brand, parentid, category, s.color, size, price, discount, promoDiscount
		, custid	
		, sum (qty) qty, sum(qty * price * (1-discount) * (1-promoDiscount)) total
	from s
	group by 
		brand, parentid, category, color, size, custid, price, discount, promoDiscount
	having sum (qty)<>0
go 

if OBJECT_ID('web.customer_basket_') is not null drop function web.customer_basket_
go 
create function web.customer_basket_ (@phone char(10)) returns table as 
	return
		select * from web.customer_basket_v v where v.custid= cust.customer_id(@phone)
go 


select * from web.customer_basket_v;