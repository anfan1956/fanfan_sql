if OBJECT_ID('inv.storage_') is not null drop proc inv.storage_
go
create proc inv.storage_ 
	@date datetime, 
	@userName varchar(255), 
	@proc varchar(255), 
	@boxID int, 
	@info dbo.barcodes_list readonly
as
	begin try
		begin transaction
			declare 
				@transID int
			  , @sign tinyint
			  , @note varchar(255)

			select @sign = case @proc 
								when 'На хранение' then 1
								else -1
							end;

			insert inv.transactions(transactiontypeID, userID)
			select inv.transactiontype_id('movement'), org.person_id(@userName)
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
				, org.division_id('BunkovoStorage')
				, @transID
				, 1
				, i.barcodeID
				from @info i
			
			)
			insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
			select clientID, logstateID, divisionID, transactionID, opersign, barcodeID from seed;

	if @sign = 1 
		begin
			if exists (
					select sb.barcodeID
					from inv.storage_box sb
					where sb.barcodeID in (select i.barcodeID from @info i) 
					group by barcodeID
					having coalesce(sum(opersign), 0) > 0
			)
			begin
				-- Raise an error if the constraint is violated
				;throw 50001, 'The sum of opersign for a barcodeID must be 0.', 1
			end

			insert inv.storage_box (id, transactionid, opersign, barcodeID)
			select @boxID, @transID, @sign, i.barcodeID
			from @info i;
		end
	else 
		begin
			if exists (
					select sb.barcodeID
					from inv.storage_box sb
					where sb.barcodeID in (select i.barcodeID from @info i) 
					group by barcodeID
					having coalesce(sum(opersign), 0) < 1
			)
			begin
				-- Raise an error if the constraint is violated
				;throw 50001, 'The sum of opersign for a barcodeID must be 1.', 1
			end

			insert inv.storage_box (id, transactionid, opersign, barcodeID)
			select @boxID, @transID, @sign, i.barcodeID
			from @info i

		end
		select @note = 'записано баркодов: ' + convert(varchar,  @@ROWCOUNT)  
		select @note note
	--;throw 500001, 'debug', 1
		commit transaction
	end try 
	begin catch
		select ERROR_MESSAGE() error
		rollback transaction
	end catch
go


set nocount on; declare @info dbo.barcodes_list; insert @info values (582714), (582713), (664008); 
--exec inv.storage_ '20250217', 'ФЕДОРОВ А. Н.', 'На хранение', '5', @info;
select * from inv.storage_box

