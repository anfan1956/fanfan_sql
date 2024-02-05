if OBJECT_ID('inv.styleDelete_') is not null drop proc inv.styleDelete_
go

create proc inv.styleDelete_ @styleid int as 
set nocount on;

	begin try
		begin transaction
		declare @mes varchar (max);

		if not exists(
			select i.* 
			from inv.inventory i
				join inv.barcodes b on b.barcodeID=i.barcodeID
			where b.styleID=@styleid
				and i.logstateID not in (8, 15)
				)
			begin
				--first delete from inventory where are barcodes with styles
				delete i
				from inv.inventory i 
					join inv.barcodes b on b.barcodeID = i.barcodeID
				where b.styleID = @styleid

				--delete from barcodes with styles
				delete b
				from inv.barcodes b 
				where b.styleID = @styleid

				-- from styles where styleid
				delete s
				from inv.styles s
				where s.styleID= @styleid
				select @mes = 'style ' + cast(@styleid as varchar(max)) + ' deleted'
			end
		else
			begin
				select @mes = 'style ' + cast(@styleid as varchar(max)) + ' cannot be deleted'
			end
--		; throw 50001, 'debugging', 1
		select @mes
		commit transaction
	end try

	begin catch
		select ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare @styleid int = 20413
--exec inv.styleDelete_ @styleid;
declare @orderid int = 80037
exec inv.transaction_delete @orderid