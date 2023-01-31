use fanfan
go


if OBJECT_ID('hst.barcodes_read') is not null drop table hst.barcodes_read
if OBJECT_ID('hst.procs') is not null drop table hst.procs
create table hst.procs (
	procid int not null identity primary key,
	procname varchar (25) not null  unique
)
 
create table hst.barcodes_read (
	logid int not null identity primary key,
	barcodeid int not null foreign key references inv.barcodes (barcodeid),
	date_checked datetime default (current_timestamp), 
	procid int not null foreign key references hst.procs (procid), 
	workstationid int not null foreign key references org.workstations (workstationid)
)

insert hst.procs (procname) values ('sale_prep'), ('return_prep'), ('info'), ('movement'), ('inv_take')

select * from hst.procs
if OBJECT_ID('hst.barcode_log_post') is not null drop proc hst.barcode_log_post
go 
create proc hst.barcode_log_post @barcodeid int, @procname varchar(25), @workstation varchar(25)
as 
begin
	insert hst.barcodes_read(barcodeid, procid, workstationid)
	select @barcodeid,   hst.proc_id(@procname), org.workstation_id(@workstation)
end 
go

EXEC hst.barcode_log_post 662892, 'sale_prep', 'SERVER'

if OBJECT_ID('hst.proc_id') is not null drop function hst.proc_id
go
create function hst.proc_id (@procname varchar (25)) returns int as
begin
declare @procid int
	select @procid = procid from hst.procs p where p.procname= @procname
return @procid
end
go
select b.*, v.brandID, br.brand

from hst.barcodes_read b
	join inv.barcode_info_v v on b.barcodeid=v.barcodeID
	join inv.brands br on br.brandID = v.brandID







