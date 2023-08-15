if OBJECT_ID('inv.barcode_sortid_') is not null drop function inv.barcode_sortid_
go
create function inv.barcode_sortid_ (@styleid int, @color varchar(max), @size varchar(max)) returns int as
	begin
		
		declare @sortid int
			select @sortid = b.sort_barcodeID 
				from inv.barcodes b
					join inv.styles s on s.styleID=b.styleID
					join inv.sizes sz on sz.sizeid=b.sizeID
					join inv.colors c on c.colorID=b.colorID
				where REPLACE(c.color, ' ','') =REPLACE(@color, ' ', '') and sz.size=@size and s.parent_styleID=@styleid
		return @sortid
	end
go

declare 

	@styleid int = 19998, 
	@color varchar(max) = 'BLU BLACK  08346',
	@size varchar(max)='XXL'

select inv.barcode_sortid_(@styleid, @color, @size)

if OBJECT_ID('inv.bc_sortid_qtys') is not null drop function inv.bc_sortid_qtys
go
create function inv.bc_sortid_qtys (@bc_sortid int) returns table as 
return
	select g.barcodeID, r.divisionID, @bc_sortid sortCodeid , 
	ROW_NUMBER() over( order by divisionid desc) shipOrder 
from inv.v_goods g 
	join inv.v_remains r on r.barcodeID = g.barcodeID

where  
	g.sort_barcodeID= @bc_sortid and r.logstateID= inv.logstate_id('IN-WAREHOUSE')
go

declare @bc_sortid int = 344792;
select * from inv.bc_sortid_qtys (@bc_sortid)