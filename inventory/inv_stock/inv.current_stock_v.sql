USE fanfan
GO

if OBJECT_ID('inv.current_stock_v') is not null drop view inv.current_stock_v
go
create view inv.current_stock_v as

	WITH _s (styleID, discount, price, num) as(
		SELECT 
			p.styleID,
			p.discount, 
			p.price,
			ROW_NUMBER() OVER (PARTITION BY P.styleID ORDER BY P.pricesetID desc)
		FROM inv.prices p
	)
	select 
		i.barcodeID, 
		s.styleID, 
		s.orderID,
		cn.contractor ������, 
		cl.orderclassRus orderType,
		d.divisionfullname �������, 
		s.article, 
		br.brand, 
		it.inventorytyperus ���������, 
		c.color ����, 
		sz.size ������, 
		se.season �����, 
		s.cost costCUR,
		s.cost * r.rate cost,
		round(
			cte.price, -1) price		
		--lp.price
	from inv.inventory i
		join org.divisions d on d.divisionID=i.divisionID
		join inv.barcodes b on b.barcodeID=i.barcodeID
		join inv.styles s on s.styleID =  b.styleID
		join inv.brands br on br.brandID = s.brandID
		join inv.colors c on c.colorID=b.colorID
		join inv.sizes sz on sz.sizeID=b.sizeID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		left join inv.seasons se on se.seasonID=s.seasonID
		join inv.orders o on o.orderid=s.orderID
		left join org.contractors cn on cn.contractorID=showroomID
		left join inv.orderclasses cl on cl.orderclassID = o.orderclassID
--		join inv.current_rate_v r on r.currencyid= o.currencyID	
		--left JOIN inv.current_rate_v r ON r.divisionid= d.divisionID AND r.currencyid= o.currencyID
		--join cmn.vCurrentRates r on r.currencyID=o.currencyID
		join cmn.rateOnDate_(getdate()) r on r.currencyid = isnull(o.currencyID, s.currencyID)
		join inv.v_lastprices lp on lp.styleID=s.styleID
		join _s cte on cte.styleID=s.styleID and cte.num=1
	where  i.logstateID= inv.logstate_id('IN-WAREHOUSE')
	group by 
		i.barcodeID, 
		s.styleID, 
		s.orderID,
		cn.contractor, 
		cl.orderclassRus,
		s.article,
		d.divisionfullname, 
		br.brand, it.inventorytyperus, c.color, sz.size, 
		se.season, 
		s.cost, lp.price,	
		r.rate, 
		o.orderclassID, cte.price
	having sum(i.opersign)>0
GO


select * from inv.current_stock_v
where orderid = 81048