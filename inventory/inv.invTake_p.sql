if OBJECT_ID ('inv.invTake_p') is not null drop proc inv.invTake_p
go 
create proc inv.invTake_p @takeid int, @barcodeid int, @days int as
	set nocount on;
begin try 
	begin transaction

		declare @thiscount int, @rows int =0;

		-- check if this barcode is already in this inventory take
		select @thiscount =  count (*)
		from inv.transactions t 
			join inv.invTake_barcodes i on i.takeid = t.transactionID
		where i.barcodeID = @barcodeid and DATEDIFF(DD, t.transactiondate, getdate())<@days;

		if @thiscount = 0
			begin 			
				insert inv.invTake_barcodes 
				select @takeid, @barcodeid;
				select @rows = @@ROWCOUNT
				select @rows updated_rows, 'баркод учтен сейчас' msg
			end 
		else 
			throw 50001, 'баркод учтен недавно', 1
		commit transaction
end try
begin catch
	select 0 updated_rows,  ERROR_MESSAGE () msg
	rollback transaction	
end catch



go


--exec inv.invTake_p 79739, 652229, 60;
		declare @thiscount int, @rows int =0, 
		@barcodeid int = 652229, @days int = 60

		select @thiscount =  count (*)
		from inv.transactions t 
			join inv.invTake_barcodes i on i.takeid = t.transactionID
		where i.barcodeID = @barcodeid and DATEDIFF(DD, t.transactiondate, getdate())<@days;

select @thiscount