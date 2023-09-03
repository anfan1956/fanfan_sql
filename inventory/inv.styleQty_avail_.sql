if OBJECT_ID('inv.styleQty_avail_') is not null drop function inv.styleQty_avail_
go
create function inv.styleQty_avail_(@json varchar(max)) returns int as
begin
declare @qty int;
		with s (styleid, color, size ) as (
			select styleid, color, size from openjson(@json)
			with (
				styleid int '$.styleid', 
				color varchar(max) '$.color',
				size varchar(max) '$.size'
			)
			where styleid is not null
		)
		select @qty = sum(i.opersign) 
	
		from s	
			join inv.styles st on st.parent_styleid = s.styleid
			join inv.barcodes b on b.styleID=st.styleID
			join inv.inventory i on i.barcodeID =b.barcodeID
			join inv.colors c on c.colorID=b.colorID
			join inv.sizes sz on sz.sizeID=b.sizeID
		where 
			i.logstateID in (8)
			and cmn.norm_(c.color)=cmn.norm_(s.color)
			and sz.size = s.size
		having sum (i.opersign)>0;
	return @qty
end
go
