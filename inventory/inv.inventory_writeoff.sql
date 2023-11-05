if OBJECT_ID('inv.inventory_writeoff') is not null drop procedure inv.inventory_writeoff
go
create procedure inv.inventory_writeoff @info inv.barcode_type readonly, @salesperson varchar (max), @shop varchar(max)
as
begin try
	begin transaction  
		declare @tranid int;

		declare @codes table (barcodeid int);

		insert @codes  
			select i.barcodeid
		from inv.inventory i
			join @info f on f.barcodeid= i.barcodeID
		where  divisionID = org.division_id('НА РУКАХ У КЛИЕНТОВ')
		group by i.barcodeID
		having sum(i.opersign)>0;

		if exists (
		select * from @codes
		)
		begin;	
			insert inv.transactions (transactiondate, transactiontypeID, userID)
			select getdate(), inv.transactiontype_id('INVENTORY WRITEOFF'), org.person_id(@salesperson)
			select @tranid=SCOPE_IDENTITY();
		end

		else
			begin;
				throw 50001, 'Списывать нечего', 1
			end;

		with 
		seed (logstateid, divisionid, opersign) as (
			select 
				null, org.division_id('НА РУКАХ У КЛИЕНТОВ'), 1
			union all 
			select  
			inv.logstate_id('LOST'), null, -1
		)
		, s as (
			select 
				i.clientID, logstateID, i.divisionID, i.transactionID, i.opersign, i.barcodeID,
				ROW_NUMBER() over (partition by i.barcodeid order by transactionid desc, opersign) num
			from inv.inventory i
				join @codes f on f.barcodeid= i.barcodeID
		)
		insert inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select 
			clientID, 
			isnull(sd.logstateID, s.logstateID), 				
			isnull(sd.divisionID, s.divisionID),
			@tranid, 
			s.opersign * sd.opersign, 
			barcodeID 
		from s cross apply seed sd where num=1;

		delete a from cust.on_account a
		join @codes i on i.barcodeid=a.barcodeid;

			select @tranid code, 'товар списан в количестве ' + cast((select count(*) from @codes) as varchar(max))  + ' штук' msg

--	;throw 50001, 'debug', 1
	commit transaction
end try
begin catch	
	select 0 code, ERROR_MESSAGE () msg
	rollback transaction
end catch
go




---set nocount on; declare @info inv.barcode_type; insert @info values (581841), (654808); exec inv.inventory_writeoff @info, 'ФЕДОРОВ А. Н.', '07 ФАНФАН';
;




