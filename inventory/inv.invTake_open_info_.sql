use fanfan
go
if OBJECT_ID ('inv.invTake_open_info_') is not null drop function inv.invTake_open_info_
go
create function inv.invTake_open_info_(@takeid int) returns table as return
with 
_bc(barcodeid) as (
	select barcodeid from inv.invTake_barcodes i where i.takeid=@takeid
)
, _location(barcodeid, logstateid, divisionid) as (
	select i.barcodeID, i.logstateID, i.divisionID
	from inv.inventory i 
		join _bc b on b.barcodeid=i.barcodeID
	group by i.barcodeID, i.logstateID, i.divisionID
	having sum(i.opersign)>0
)
, _bc_data (barcodeid, styleid, brandid, colorid, sizeid, inventorytypeid, article) as (
	select i.barcodeid, s.styleID, s.brandID, b.colorID, b.sizeID, s.inventorytypeID, s.article
	from _bc i
		join inv.barcodes b on b.barcodeID = i.barcodeid
		join inv.styles s on s.styleID = b.styleID	
)
, _inv (barcodeid, transactionid, num) as (
	select b.barcodeid, i.transactionID, ROW_NUMBER () over (partition by b.barcodeid order by i.transactionid desc) num
	from inv.inventory i
		join  _bc b on b.barcodeid= i.barcodeID
)
select 
	br.brand, 
	b.article, 
	b.barcodeid, 
	it.inventorytyperus, 
	c.color, 
	sz.size, 
	ls.logstate, 
	d.divisionfullname,
	tt.transactiontype, 
	t.transactiondate 
from _bc_data b
	join _inv i on i.barcodeid=b.barcodeid and i.num =1
	join inv.transactions t on t.transactionID=i.transactionid
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	join inv.brands br on br.brandID=b.brandid
	join inv.colors c on c.colorID=b.colorid
	join inv.sizes sz on sz.sizeID=b.sizeid
	join inv.inventorytypes it on it.inventorytypeID=b.inventorytypeid
	join _location l on l.barcodeid=b.barcodeid
	join inv.logstates ls on ls.logstateID=l.logstateid
	join org.divisions d on d.divisionID=l.divisionid
	
go

declare @takeid int =79730
select * from inv.invTake_open_info_(@takeid)

