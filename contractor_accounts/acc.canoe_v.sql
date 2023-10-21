
declare @barcodeid int = 664459
if OBJECT_ID('acc.canoe_v') is not null drop view acc.canoe_v
go
create view acc.canoe_v as

select 
	t.transactionID transid,
	format (t.transactiondate, 'dd.MM.yyyy') дата,
	DATEPART(MM, t.transactiondate) месяц,
	i.barcodeID, 
	c.color, 
	sz.size, 
	s.gender [муж/жен], 
	br.brand марка, 
	s.styleID, 
	s.article артикул, 
	it.inventorytyperus категория, 
	d.divisionfullname магазин, 
	s.cost стоимость, 
	--it.inventorytypeID typeid,
	 case when it.inventorytypeID in (70, 27) then 0.10 else 0.00  end discount, 
	s.cost * (1 - case when it.inventorytypeID in (70, 27) then 0.1 else 0 end) к_оплате
from inv.transactions t
	join inv.inventory i on i.transactionID= t.transactionID
	join inv.barcodes b on b.barcodeID=i.barcodeID
	join inv.styles s on s.styleID=b.styleID
	join inv.colors c on c.colorID=b.colorID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join org.divisions d on d.divisionID=i.divisionID

where t.transactiontypeID in (12, 13) and s.brandID =343 and i.logstateID=inv.logstate_id('sold')
	and t.transactionID>77013
group by 
	i.barcodeID, t.transactionID, c.color, t.transactiondate, sz.size, s.gender, br.brand, s.styleID, s.article,
	it.inventorytyperus, d.divisionfullname, s.cost, t.transactiontypeID, it.inventorytypeID
having sum (i.opersign)>0
go
select * from acc.canoe_v order by 1 desc


