
if OBJECT_ID('web.basketContent_consolidated_json_') is not null drop proc web.basketContent_consolidated_json_
go
create proc web.basketContent_consolidated_json_ @json varchar(max) as
begin
set nocount on;
declare @content varchar (max);
declare @phone char(10), @uuid char(36), @custid int


;with 
j (phone, uuid) as (
	select  phone, Session
	from OPENJSON(@json)
	with (
		phone char(10) '$.phone', 
		Session char(36) '$.Session'
	)
)	
select @phone=phone, @uuid=uuid, @custid= cust.customer_id(phone)
from j;

update l set custid=@custid, uuid=@uuid
from web.baskets b
	join web.logs l on l.logid=b.logid
where cust.customer_id(@phone) =l.custid or uuid = @uuid;



   
with s (parent_styleid, color, size, qty) as (
	select l.parent_styleid, cmn.norm_(l.color), l.size, sum(l.qty)
	from web.baskets l 
		join web.logs b	 on b.logid=l.logid 
--		join j on cust.customer_id(j.phone) = b.custid or j.uuid= b.uuid 
	where b.custid= cust.customer_id(@phone) or b.uuid=@uuid
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
		and i.divisionID in ( 18, 25, 27)
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
, _h (	марка, модель ,категория, цвет, размер, цена, скидка, промо, [в корзине] , всего, наличие, photo )  as (
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
select @content
--return @content
end
go

--select * from web.logs order by 1 desc
declare @json varchar (max) = 
'{"phone":"9167834248", "Session":"e8a0e246-c3cc-4f5e-b338-6c07c235b200"}';


---select web.basketContent_json_(@json)

exec web.basketContent_consolidated_json_ @json





