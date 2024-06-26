ALTER function [inv].[barcode_reciept_func] (@barcodeid int) returns table as return
	select 
			g.barcodeID,
			g.brand марка, g.season сезон, g.article артикул, 
			g.category категория, g.size размер, g.color цвет, 
			g.composition, g.baseprice цена, g.discount скидка, 
			g.price, 
			case l.logstate
				when 'IN-WAREHOUSE' then 'В НАЛИЧИИ'
				when 'SOLD'  then 'ПРОДАННЫЙ'
				when 'LOST' then 'УТРАЧЕННЫЙ'
				else l.logstate
			end статус, 
			d.divisionfullname магазин
	from inv.v_goods g 
		join inv.v_remains r on r.barcodeID=g.barcodeID
		join inv.logstates l on l.logstateID=r.logstateID
		join org.divisions d on d.divisionID=r.divisionID		
	where g.barcodeID=@barcodeid
go
if OBJECT_ID('inv.barcode_reciept2_func') is not null drop function inv.barcode_reciept2_func
go
create function inv.barcode_reciept2_func (@barcodeid int) returns table as return

	with cte (styleid, price, discount, num) as (
		select 
			s.styleID, s.price, s.discount, 
			ROW_NUMBER () over(partition by s.styleid order by s.pricesetid desc)			
		from inv.prices s
	)	
	select 
		i.barcodeID, 
		br.brand марка, 
		se.season сезон, 
		s.article артикул,
		it.inventorytyperus категория,
		sz.size размер,
		cl.color цвет,
	cmp.composition,	 	
	round (cte.price, -1) цена,
	--case t.transactiontypeid 
	--	when inv.transactiontype_id('consignment')  then cte.price  
	--	else s.cost * isnull(s.cost_adj, 1) * v.rate *v.markup
	--	--when inv.transactiontype_id('order')		then s.cost * isnull(s.cost_adj, 1) * v.rate *v.markup 
	--	--when inv.transactiontype_id('order local')  then s.cost * isnull(s.cost_adj, 1) * v.rate *v.markup 
	--	end цена,
	isnull(ps.discount, 0) скидка, 
	isnull(w.promo_discount, 0) промо, 
	cast(s.cost * isnull(s.cost_adj, 1) *v.rate * 
	case t.transactiontypeID	
		when inv.transactiontype_id('order') then v.markup 
		when inv.transactiontype_id('consignment') then o.markup end
	* (1-isnull(ps.discount, 0)) as money) price,
				case l.logstate
				when 'IN-WAREHOUSE' then 'В НАЛИЧИИ'
				when 'SOLD'  then 'ПРОДАННЫЙ'
				when 'LOST' then 'УТРАЧЕННЫЙ'
				else l.logstate
			end статус,  
	d.divisionfullname магазин 
from inv.inventory i
	join inv.logstates l on l.logstateID=i.logstateID
	join inv.barcodes b on b.barcodeID=i.barcodeID
	join inv.styles s on s.styleID =b.styleID
	join inv.orders o on o.orderID=s.orderID
	join inv.transactions t on t.transactionID=o.orderID
	join inv.brands br on br.brandID=s.brandID
	left join inv.seasons se on isnull(se.seasonID, 0)=isnull (o.seasonID, 0)
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join inv.colors cl on cl.colorID=b.colorID
	join inv.v_compositions cmp on cmp.compositionID=s.compositionID
	join org.divisions d on d.divisionID=i.divisionID
	join cte on cte.styleid =s.styleID and cte.num=1
	left join web.styles_discounts_active_ w on w.styleid=s.styleID
	
	left join (
		select p.*, ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc) rn
		from inv.prices p ) ps on ps.styleID=s.styleID and ps.rn=1
	join inv.current_rate_v v on v.divisionid=i.divisionID and v.currencyid=o.currencyID
where i.barcodeID=@barcodeid
	and i.logstateID in (inv.logstate_id('IN-Warehouse'), inv.logstate_id('SOLD'))
group by 
	l.logstate,
	i.barcodeID, d.divisionfullname, br.brand, se.season, s.article, it.inventorytyperus,
	sz.size, cl.color, cmp.composition, s.retail,
	ps.discount, s.cost, s.cost_adj, 
	v.rate,  v.markup, 
	cte.price, 
	s.styleID, w.promo_discount, 
	t.transactiontypeID, o.markup
having sum(i.opersign)=1
go


declare @barcodeid int = 636862, @shop varchar(max)= '08 ФАНФАН'
select * from inv.barcode_reciept_func(@barcodeid)
select * from inv.barcode_reciept2_func(@barcodeid)
go
declare @shop varchar (25)= '05 УИКЕНД', @barcodeid int =624332; exec inv.barcode_info_func @barcodeid, @shop
select * from inv.barcode_reciept2_func (624332)