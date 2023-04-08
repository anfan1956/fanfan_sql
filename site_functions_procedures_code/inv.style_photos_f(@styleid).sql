USE [fanfan]
GO

ALTER function [inv].[style_photos_f](@styleid int) returns table as return

with _s  (styleid, parent_styleid, photo_filename, photo_priority, receipt_date, colorid) as (
	select 
		sp.styleid, sp.parent_styleid, sp.photo_filename, cast (sp.photo_priority as int) photo_priority, sp.receipt_date,
		colorid
	from inv.styles_photos sp
		join inv.barcodes b on b.barcodeID=sp.barcodeid
		where parent_styleid is not null
),  _p as (
		select sa.styleid, sa.parent_styleid, sa.photo_filename photo, sa.photo_priority, sa.receipt_date, sa.colorid
			, ROW_NUMBER() over (partition by sa.parent_styleid order by sa.styleid desc, isnull(sa.photo_priority, 100) )  topnum
		from _s sa
	)
select distinct
		case 
			when o.gender = 'm' then 'МУЖ'
			when o.gender = 'f' then 'ЖЕН' 
			when o.gender is null then 
				case when s.gender = 'm' then 'МУЖ'
				when s.gender = 'f' then 'ЖЕН' 
				when s.gender= 'u' then 'ЮНИ'
				when s.gender is null then ''
				end
			end gender,
		v.brand, v.category, v.article, c.color,
		--v.styleID,	
		sp.parent_styleid styleID,	
--		v.price, 
		s.cost * isnull(s.cost_adj, 1) * cr.rate * cr.markup price, 
		v.discount,	sp.photo,
		--datediff(s, d.date, receipt_date) 
		receipt_date, 
		isnull(wp.discount, 0) promo
from _p sp
		join inv.v_goods v  on sp.styleid=v.styleid
		join inv.v_remains r on r.barcodeID=v.barcodeID
		join inv.orders o on o.orderID=v.orderID
		join inv.colors c on c.colorID=sp.colorid		
		join inv.current_rate_v cr on cr.currencyid=o.currencyID and cr.divisionid = org.division_id('fanfan.store')
		join inv.styles s on s.styleID=sp.styleid
		left join web.promo_styles_discounts wp on wp.styleid=sp.parent_styleid
	where 
		r.logstateID=8 and r.divisionID in (0, 14, 18, 25, 27) and 
		sp.parent_styleid=@styleid
go
select gender, styleid, price, discount, promo, article, category, brand, color, photo from inv.style_photos_f(19973) ORDER BY photo asc