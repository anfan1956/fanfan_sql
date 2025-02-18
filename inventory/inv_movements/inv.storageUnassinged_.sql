if OBJECT_ID('inv.storageUnassinged_') is not null drop view inv.storageUnassinged_
go
create view inv.storageUnassinged_ as
	select i.barcodeID, d.division, d.divisionfullname
	from  inv.inventory i
		join org.divisions d on d.divisionID = i.divisionID
		left join inv.storage_box sb on sb.barcodeID = i.barcodeID
	where 1=1
		and i.opersign =1
		and d.divisionfullname like '%stora%'
	group by i.barcodeID, d.division, d.divisionfullname
	having sum (sb.opersign) =0