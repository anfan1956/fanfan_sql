USE [fanfan]
GO

ALTER view [inv].[styles_catalog_v] as

-- there is hardcoding in logstates and divisions in order to speed up the executionm
with  
_discounts (styleid, discount, num) as (
	select 
		p.styleID,
		p.discount, 
		ROW_NUMBER() over(partition by p.styleid order by p.pricesetid desc)
	from inv.prices p
		join inv.pricesets ps on ps.pricesetID=p.pricesetID
)
, _photos (styleid, parent_styleid, photo_filename, receipt_date, num) as(
	select 
		p.styleid, 
		p.parent_styleid,
		p.photo_filename, receipt_date, 
		ROW_NUMBER()  over (partition by p.parent_styleid order by p.photo_filename)
	from inv.styles_photos p 
)

, _avail_styles as (
	select  distinct s.styleID, i.logstateID
	from inv.inventory i
		join inv.barcodes b on b.barcodeID=i.barcodeID
		join inv.styles s on s.styleID=b.styleID
	where i.logstateID=inv.logstate_id('in-warehouse') and i.divisionID in (0, 14, 18, 25, 27)
	group by s.styleID, i.logstateID
	having sum(opersign)>0
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
	b.brand, 
	it.inventorytyperus category, 
	s.article,
--	a.styleID, 
	p.parent_styleid styleid, 
	s.cost * isnull (cost_adj, 1) * cr.rate * cr.markup price, 
	d.discount, 
	p.photo_filename,
	p.receipt_date
from _avail_styles a 
	join _photos p on p.styleid=a.styleID
	join inv.styles s on s.styleID=p.styleid
	join inv.brands b on b.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.orders o on o.orderID=s.orderID
	join inv.current_rate_v cr on cr.currencyid=o.currencyID and cr.divisionid = org.division_id('fanfan.store')
	join _discounts d on d.styleid=p.parent_styleid and d.num = 1
where p.num= 1

GO
select * from inv.styles_catalog_v

--select gender, styleid, price, discount, promo, article, category, brand, color, photo from inv.style_photos_f(20294) ORDER BY photo asc