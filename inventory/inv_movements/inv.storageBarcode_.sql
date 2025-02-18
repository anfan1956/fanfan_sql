if OBJECT_ID('inv.storageBarcode_') is not null drop proc inv.storageBarcode_
go
create proc inv.storageBarcode_ @bcID int , @BoxID int, @WH varchar(255), @userName varchar(255)
as
	begin try
		begin transaction
			declare @opersing int, @transID int;
			declare @info table (barcodeid int);
			insert @info select @bcID;

			-- Проверка, находится ли данный баркод на складе. 
			-- Если нет, то осуществляем транзакцию по перемещению товара на склад
			if org.division_id(@WH)<> (
						select top 1 i.divisionID
						from inv.inventory i 
						where 1=1
							and i.barcodeID = @bcID
							and i.opersign  = 1
						order by i.transactionID desc
						)
			begin	
				insert inv.transactions(transactiontypeID, userID)
				select inv.transactiontype_id('STORAGE'), org.person_id(@userName)
				select @transID = SCOPE_IDENTITY();				

				with seed (clientid, logstateID, divisionID, transactionid, opersign, barcodeid) as (
				select iv.clientID, iv.logstateID, iv.divisionID, iv.transactionID, iv.opersign, iv.barcodeID
				from @info inf
					outer apply (select top 1  
						clientID, logstateID, divisionID, @transID transactionID, -1 opersign, i.barcodeID					
						from inventory i
						where 1=1 
							and i.barcodeID = inf.barcodeID	
							and i.opersign > 0
						order by i.transactionID desc
					) as iv
				union all
				select 
					org.client_id_clientRUS ('ИП ИВАНОВА')
					, inv.logstate_id('IN-WAREHOUSE')
					, org.division_id(@WH)
					, @transID
					, 1
					, i.barcodeID
					from @info i			
				)
				insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
				select clientID, logstateID, divisionID, transactionID, opersign, barcodeID from seed;
			END		

			if (
				select 
					coalesce(sum(opersign), 0)
				from inv.storage_box sb
				where 
					sb.boxID = @BoxID
					and sb.barcodeID =@bcID
				) = 0
			select @opersing = 1;
			else 
			select @opersing = -1

			insert inv.storage_box (boxID, barcodeID, opersign)
			select @BoxID, @bcID, @opersing
		commit transaction
	end try
	begin catch
		select ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare @bcID int = 505996, @boxID int  = 5, @transID int  = 87333,  @WH varchar(255) = 'BunkovoStorage'; 
--exec inv.storageBarcode_ @bcID, @boxID, @transID, @WH; 
select * from inv.storage_box


