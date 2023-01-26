USE [fanfan]
GO

ALTER view [inv].[styles_catalog_v] as

-- there is hardcoding in logstates and divisions in order to speed up the executionm
	with _date(date) as (select '19700101')
	, _s  (styleid, parent_styleid, photo_filename, photo_priority, receipt_date) as (
		select 
			sp.styleid, sp.parent_styleid, sp.photo_filename, cast (sp.photo_priority as int) photo_priority, sp.receipt_date
		from inv.styles_photos sp
	)
	, _p as (
		select sa.styleid, sa.parent_styleid, sa.photo_filename, sa.photo_priority, sa.receipt_date
			, ROW_NUMBER() over (partition by sa.parent_styleid order by isnull(sa.photo_priority, 100) )  topnum
		from _s sa
	)
	select distinct 
		case o.gender 
			when 'm' then 'МУЖ'
			when 'f' then 'ЖЕН' 
			when null then 'NA'
			end gender,
		v.brand, v.category, v.article,
		--v.styleID,	
		sp.parent_styleid styleid,
		--v.price, 
		s.cost * isnull (cost_adj, 1) * cr.rate * cr.markup price,
		v.discount,	sp.photo_filename,
		--datediff(s, d.date, receipt_date) 
		receipt_date
	from 
		inv.v_goods v
		join inv.v_remains r on r.barcodeID=v.barcodeID
		join _p sp on sp.styleid=v.styleid
		join inv.orders o on o.orderID=v.orderID
		join inv.current_rate_v cr on cr.currencyid=o.currencyID and cr.divisionid = org.division_id('fanfan.store')
		join inv.styles s on s.styleID=v.styleID
		cross apply _date d
	where 
		r.logstateID=8 and r.divisionID in (0, 14, 18, 25, 27)
		and sp.topnum=1 and sp.parent_styleid is not null
GO


