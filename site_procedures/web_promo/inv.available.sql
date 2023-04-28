if OBJECT_ID('inv.available') is not null drop function inv.available
go
create function inv.available (@bcodes inv.barcode_type readonly) returns bit as
begin
	declare @avail bit, @count int;
	with s (barcodeid , num) as (
	select 
	i.barcodeID, sum(i.opersign)
	from @bcodes b 
		join inv.inventory i on i.barcodeID =b.barcodeid
		where i.logstateID= inv.logstate_id('in-warehouse')
	group by i.barcodeID
	having sum(i.opersign) =1
	)
	select @count = count(*) from s;
			
	if @count<> (select count(*) from @bcodes) 
		select @avail= 'False'
	else 
		select @avail= 'True'
	return @avail
end 
go

if OBJECT_ID('web.barcodes_missing_f') is not null drop function web.barcodes_missing_f
go
create function web.barcodes_missing_f (@bcodes inv.barcode_type readonly) returns table as return

	with s (barcodeid ) as (
	select 
	i.barcodeID
	from @bcodes b 
		join inv.inventory i on i.barcodeID =b.barcodeid
		where i.logstateID= inv.logstate_id('in-warehouse')
	group by i.barcodeID	
	having  sum(i.opersign) =1
	)
	select * from @bcodes 
	except 
	select * from s;
go


declare @bcodes inv.barcode_type;
insert @bcodes values (6587650), (652306), (6515240);
select * from web.barcodes_missing_f(@bcodes)