declare @phone char (10) ='9167834248', @parentid int = 9574
if OBJECT_ID('web.basketContent_') is not null drop function web.basketContent_
go
create function web.basketContent_(@phone char(10)) returns varchar(max) as
begin
declare @content varchar (max);

;with s (parent_styleid, color, size, qty) as (
	select l.parent_styleid, cmn.norm_(l.color), l.size, sum(l.qty)
	from web.baskets l join web.logs b	 on b.logid=l.logid 
	where b.custid= cust.customer_id(@phone)
	group by 
		l.parent_styleid, 
		cmn.norm_(l.color), 
		l.size
	having sum(qty)<>0
)
, _avail (parent_styleid, color, size, qty, avail, brandid, catId) as (
	select 
		st.parent_styleid, cmn.norm_(c.color), s.size, 
		s.qty, 
		sum(i.opersign) qty, 
		st.brandID, 
		st.inventorytypeID
	from inv.inventory i 
		join inv.barcodes b on b.barcodeID= i.barcodeID
		join inv.styles st on st.styleID=b.styleID
		join inv.colors c on c.colorID=b.colorID 
		join inv.sizes sz on sz.sizeID=b.sizeID 
		join s  
			on s.parent_styleid=st.parent_styleid 
			and cmn.norm_(s.color) = cmn.norm_(c.color)
			and s.size=sz.size 
	where  
		i.logstateid = 8 
		and i.divisionID in (0, 14, 18, 25, 27)
	group by 
		cmn.norm_(c.color), s.size, st.parent_styleid, s.qty, st.brandID, st.inventorytypeID
	having sum(i.opersign)>0
) 
, _prices  as (
select  
	st.parent_styleid,p.styleid, 
	p.discount, 
	st.cost * isnull (st.cost_adj, 1) * cr.rate * cr.markup price, 
	ROW_NUMBER() over (partition by st.parent_styleid order by p.pricesetid desc) num

from inv.prices p
	join inv.styles st on st.styleID=p.styleID
	join inv.orders o on o.orderID =st.orderID
	join inv.current_rate_v cr on cr.currencyid=o.currencyID and cr.divisionid = org.division_id('fanfan.store')
	join s on s.parent_styleid=st.parent_styleid
		
)
--select * from _prices
, _h (	марка, модель ,категория, цвет, размер, цена, скидка, промо, количество, всего, наличие, photo )  as (
	select distinct
		br.brand,  
		a.parent_styleid, 
		it.inventorytyperus,
		a.color, 
		a.size, 
		p.price,
		p.discount, 
		isnull(d.discount, 0) , 
		a.qty,
		'', 
		a.avail,
		inv.styleColor_photo_(a.parent_styleid, a.color) photo 
	from _avail a		
		join inv.brands br on br.brandID=a.brandid
		join  inv.inventorytypes it on it.inventorytypeID= a.catId
		join _prices p on p.parent_styleID=a.parent_styleid
		left join  web.promo_styles_discounts d on d.styleid=a.parent_styleid
		left join web.promo_events e on e.eventid=d.eventid and	e.eventClosed=0 
				and cast(datefinish as date ) >= cast(getdate() as date)
		where p.num =1
)
--select * from _h
select @content = (
select * from _h 
for json path,  INCLUDE_NULL_VALUES);
		if @content is null
		select @content= (select 'Пустая' корзина for json path)
--select @content
return @content
end
go



declare @phone char (10)= '9167834248';
--select * from web.customer_basket_(@phone)


declare @start datetime = getdate();
--select * from web.baskets
select web.basketContent_(@phone)

declare @end datetime = getdate()
select DATEDIFF(ms, @start, @end)
