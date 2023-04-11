if OBJECT_ID('inv.style_id') is not null drop function inv.style_id
go 

create function inv.style_id(@brand varchar(50), @article varchar(50)) returns int as
begin
	declare @styleid int;

	select @styleid = s.styleID 
	from inv.styles s
		join inv.brands b on b.brandID= s.brandID
	where b.brand =@brand and s.article like '%' + @article +'%'
	return @styleid
end
go

declare @styleid int = 19211
select discount from inv.prices_latest_v where styleID= inv.style_id('AERONAUTICA MILITARE' , 'FE1747F488')

if OBJECT_ID ('web.promo_discount_') is not null drop function web.promo_discount_
go

create function web.promo_discount_(@phone char(10), @styleid int, @code char(6)) returns decimal(4,3) as
begin
	declare @discount dec(4,3);

select @discount =  d.discount 
from web.promo_log p
	join web.promo_events e on e.eventid=p.eventid
	join web.promo_styles_discounts d on d.eventid=p.eventid and d.styleid=p.styleid
where 
	p.custid=cust.customer_id(@phone) and p.promocode=@code
	and used = 'False' and d.styleid= @styleid

	return @discount
end
go

declare @phone char(10) = '9167834248', @code char(6) = '786894', 
	@styleid int = 19996

select web.promo_discount_(@phone, @styleid, @code)