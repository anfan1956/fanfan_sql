use fanfan
go


ALTER function [inv].[style_colors_sizes_avail](@styleid int) returns table as return

with _art (article, brandid) as (
	select s.article, s.brandID
	from inv.styles s 
	where s.styleID =@styleid
)
, _site_price_parameters (divisionid, currencyid, rate, markup) as (
	select cr.divisionid, currencyid, rate, markup
	from inv.current_rate_v cr 
)

, _s (styleid, colorid, sizeid, qty, price, cost, divisionid, division) as (
	select 
		st.styleID, b.colorID, b.sizeID, count(b.barcodeid), 
		st.cost * isnull(st.cost_adj, 1) * cr.rate * cr.markup,
		max(st.cost) over(),
		r.divisionID, d.division
	from _art a
		join inv.styles st on st.article=a.article and	st.brandID=a.brandid
		join inv.orders o on o.orderID=st.orderID
		join inv.barcodes b on b.styleID=st.styleID
		join inv.v_remains r on r.barcodeID=b.barcodeID and r.logstateID =inv.logstate_id ('IN-WAREHOUSE')
		join org.active_retail_divisions_f(getdate()) d on d.divisionID=r.divisionID
		join inv.current_rate_v cr on cr.currencyid = o.currencyID and  cr.divisionID= org.division_id('fanfan.store')
	group by st.styleID, b.colorID, b.sizeID, st.cost, st.cost_adj, cr.rate, cr.markup, r.divisionid, d.division
)
	select sz.size, s.sizeid, cl.color, s.qty, s.price, s.styleid, s.division
	from _s s
	join inv.sizes sz on sz.sizeID=s.sizeid
	join inv.colors cl on cl.colorID=s.colorid
GO

declare @styleid int = 19691--19321;
select color, size, sizeid, price, qty, styleid, division
from inv.style_colors_sizes_avail (@styleid) ORDER BY color ASC, sizeid

select * from inv.styles st  where st.styleid =@styleid;

