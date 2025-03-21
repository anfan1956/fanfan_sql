if not exists (select 1 from sys.objects s where object_id = OBJECT_ID('inv.storage_box')) 
--if OBJECT_ID('inv.storage_box') is not null drop table inv.storage_box
begin
create table inv.storage_box (
	id int not null identity primary key,
	boxID int not null,
	entryDate datetime default current_timestamp,
	barcodeID int not null references inv.barcodes (barcodeid), 
	opersign int constraint check_opersing check  (opersign in (-1, 1)) 
)
end

--truncate table inv.storage_box
select * 
from inv.storage_box

select sum(b.opersign) qty
from inv.storage_box b
having sum(b.opersign) >0



/*
insert org.divisions (division,divisionfullname, clientID, holdsmoney, holdsinventory, retail, comment,datestart, chainID)
select 'Storage', 'BunkovoStorage',1719, 0, 1, 0, 'For storage in boxes.inv.packing_p_', '2025-02-01', 10
*/
select org.division_id('BunkovoStorage')
--select org.client_id('ÈÏ ÈÂÀÍÎÂÀ')


select org.client_id_clientRUS ('ÈÏ ÈÂÀÍÎÂÀ')

