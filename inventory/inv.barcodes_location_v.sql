if OBJECT_ID ('inv.barcodes_location_v') is not null drop view inv.barcodes_location_v
go 
create view inv.barcodes_location_v as

select 
	b.barcodeID, i.divisionID, i.logstateID, 
	sum (i.opersign) opersing
from inv.barcodes b 
	join inv.inventory i on i.barcodeID=b.barcodeID
where 
	i.logstateID=inv.logstate_id('in-warehouse')
group by 
	b.barcodeID, i.divisionID, i.logstateID
having sum (i.opersign)>0

go


select *
from inv.barcodes_location_v b
where b.barcodeID in (663776, 663783)

