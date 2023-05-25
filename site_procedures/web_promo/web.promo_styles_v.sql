declare @phone char(10) = '9167834248', @code char(6) = '786894', @styleid int = 19996
--select * from web.promo_events; 
--update e set e.datefinish='20230531' from web.promo_events e where e.eventid=1
--select * from web.promo_log;select * from web.promo_styles_discounts

	--select d.discount 
	--from web.promo_log p
	--	join web.promo_events e on e.eventid=p.eventid
	--	join web.promo_styles_discounts d on d.eventid=p.eventid and d.styleid=p.styleid
	--where 
	--	p.custid=cust.customer_id(@phone) and p.promocode=@code
	--	and used = 'False' and d.styleid= @styleid;

if OBJECT_ID('web.promo_styles_v') is not null drop view web.promo_styles_v
go
create view web.promo_styles_v as
	with _date(thisDate) as (select cast(getdate() as date))
	select  STRING_AGG  (
		cast(ps.styleid as varchar(10)) + ',' + cast( ps.discount as varchar(10))
			+ ',' + cast( v.price as varchar(10)), 
		';') as Styles
	from web.promo_styles_discounts ps
		join web.promo_events pe on pe.eventid=ps.eventid
		join web.stylesPrices_discounts_v v on v.styleID=ps.styleid
		
		cross apply _date d
	where d.thisDate between pe.datestart and pe.datefinish
--	for Json Auto 

go 
select Styles from web.promo_styles_v

if OBJECT_ID('web.stylesPrices_discounts_v') is not null drop view web.stylesPrices_discounts_v
go 
create view web.stylesPrices_discounts_v as


select s.styleID, s.cost * v.rate * v.markup * isnull(s.cost_adj, 1) price
from inv.styles s
	join web.promo_styles_discounts sd on sd.styleid=s.styleID
	join inv.orders o on o.orderID=s.orderID
	join inv.current_rate_v v on v.currencyid=o.currencyID

where divisionid=31
go

select * from web.stylesPrices_discounts_v

--select styles_string from web.promo_styles_active_