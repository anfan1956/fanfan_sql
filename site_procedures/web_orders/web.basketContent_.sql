if OBJECT_ID('web.basketContent_') is not null drop function web.basketContent_
go
create function web.basketContent_(@phone char(10)) returns varchar(max) as
begin
declare @content varchar (max);

with s (parent_styleid, color, size, qty) as (
	select l.parent_styleid, cmn.norm_(l.color), l.size, sum(l.qty)
	from web.basket b join web.basketLogs l	 on b.logid=l.logid 
	where b.custid= cust.customer_id(@phone)
	group by 
		l.parent_styleid, 
		cmn.norm_(l.color), 
		l.size
	having sum(qty)<>0
)
, _avail (parent_styleid, color, size, qty, avail) as (
	select 
		st.parent_styleid, cmn.norm_(c.color), s.size, 
		s.qty, 
		sum(i.opersign) qty
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
		cmn.norm_(c.color), s.size, st.parent_styleid, s.qty
	having sum(i.opersign)>0
) 
, _h (марка, модель , категория, цвет, размер, цена, скидка, промо, количество, всего, наличие, photo )  as (
	select distinct
		v.brand,  
		a.parent_styleid, 
		v.category,
		a.color, 
		a.size, 
		v.price,
		v.discount, 
		isnull(d.discount, 0) , 
		a.qty, 
		'', 
		a.avail,
		inv.styleColor_photo_(a.parent_styleid, a.color) photo 
	from _avail a
		join inv.styles_catalog_v v on v.styleid= a.parent_styleid  
		left join  web.promo_styles_discounts d on d.styleid=a.parent_styleid
		left join web.promo_events e on e.eventid=d.eventid and	e.eventClosed=0 
				and cast(datefinish as date ) >= cast(getdate() as date)
)
select @content = (
select * 
from _h for json path
);
		if @content is null
		select @content= (select 'Пустая' корзина for json path)
return @content
end
go
declare @phone char (10)= '9167834248';
select web.basketContent_(@phone)
select * from web.customer_basket_(@phone)