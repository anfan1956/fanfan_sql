use fanfan
go
if OBJECT_ID ('inv.inventoryStatus_v') is not null drop view inv.inventoryStatus_v
go
create view inv.inventoryStatus_v as
with _bc (barcodeid, photo, num) as (
	select 
		b.barcodeID, sp.photo_filename, 
		ROW_NUMBER() over(partition by b.barcodeid order by photo_priority desc, sp.photo_filename)
	from inv.styles_photos sp
		join inv.styles s on s.parent_styleid=sp.parent_styleid
		join inv.barcodes b on b.styleID=s.styleID
)
select 
	l.barcodeID баркод, 
	br.brand марка,
	case closed when 1 then 'закрыта' end закрыта,
	it.inventorytakeID takeid, t.transactiondate дата, 
	tt.takeType тип,
	d.divisionfullname магазин, p.lfmname сотрудник, 
	c.color цвет, sz.size размер, s.styleID модель, s.article артикул, 
	se.season сезон, 
	ty.inventorytyperus категория ,
	s.cost * r.rate закупка, 
	ph.photo
from inv.barcodes_location_v l
	left join inv.invTake_barcodes b on b.barcodeid=l.barcodeID
	left join inv.inventorytakes it on it.inventorytakeID=b.takeid
	left join inv.invTake_types tt on tt.typeid=it.typeid
	left join inv.transactions t on t.transactionID= it.inventorytakeID
	join org.divisions d on d.divisionID= l.divisionID
	left join org.persons p on p.personID= t.userID
	join inv.barcodes bc on bc.barcodeID=l.barcodeID
	join inv.colors c on c.colorID=bc.colorID
	join inv.sizes sz on sz.sizeID=bc.sizeID
	join inv.styles s on s.styleID=bc.styleID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes ty on ty.inventorytypeID=s.inventorytypeID
	left join inv.seasons se on se.seasonID=s.seasonID
	join cmn.v_currentrates r on r.currencyID=s.currencyID
	left join _bc ph on ph.barcodeid=bc.barcodeID and num = 1

go
select * from inv.inventoryStatus_v
;
