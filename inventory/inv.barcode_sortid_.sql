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
				where REPLACE(c.color, ' ','') =REPLACE(@color, ' ', '') and sz.size=@size and s.styleID=@styleid
		return @sortid
	end
go

declare 
	@styleid int = 19996, 
	@color varchar(max) = 'BLU BLACK 08346',
	@size varchar(max)='XXL'

select inv.barcode_sortid_(@styleid, @color, @size)
