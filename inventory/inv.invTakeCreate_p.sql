if OBJECT_ID ('inv.invTakeCreate_p') is not null drop proc inv.invTakeCreate_p
go 
create proc inv.invTakeCreate_p @shop varchar(max), @user varchar(max),  @global int = 1  as
	set nocount on;
begin try
begin transaction

/*
	инвентаризации делить на два типа: полные (global) и частичные (local)
	в частичные могут сканироваться любые баркоды, в глобальные  - только те, которые не были сделаны
	в последние n дней
	Если параметр global к процедуре не указан, значит она глобальная
*/

	declare @transid int , @todaysCount int;
		select 
			@todaysCount = count(*) 
		from inv.transactions t 
			join inv.inventorytakes it on it.inventorytakeID=t.transactionID 
				and it.divisionID=org.division_id(@shop) 
				--and cast(t.transactiondate as date)= cast(getdate() as date)
			where it.closed is null
		if @todaysCount = 0 or @todaysCount is null
			begin
				insert  inv.transactions(transactiondate, transactiontypeID, userID)
				select getdate(), inv.transactiontype_id('inventory take'), org.person_id(@user)
				select @transid = SCOPE_IDENTITY()

				insert inv.inventorytakes (inventorytakeID, divisionID, invGlobal)
					select @transid, org.division_id(@shop), @global

				--select * from inv.transactions t where t.transactionID=@transid;
				--select * from inv.inventorytakes t where t.inventorytakeID =@transid
				declare @mes varchar(max)  = 'создана инвентаризация № ' + cast (@transid as varchar(max))
				select @transid transid, @mes msg
			end
		else
			begin
				declare @open int;
				select top 1 
					@transid= t.transactionID, @open = it.invGlobal
				from inv.transactions t 
					join inv.inventorytakes it on it.inventorytakeID=t.transactionID 
						and it.divisionID=org.division_id(@shop) 
				order by t.transactionID desc;
				if @open = @global 
					select @transid transid,   'продолжаем инвентаризацию № ' + cast (@transid as varchar(max)) msg
				else
					begin 			
						select @mes = 'Новая инвентаризация - ' + + case @global when 0 then ' частичная' else ' полная' end + '.' +  char(10)
						select @mes  += 'Открыта' + case @open when 0 then ' частичная ' else ' полная' end +  ' инвентаризация № ' + cast (@transid as varchar(max)) + '.'
						select @mes += char(10) + 'Закрыть?';
						select 1, @mes, @transid

					end
			end


		--;throw 50001, 'debug', 1
	commit transaction
end try
begin catch
	select 0 transid,  ERROR_MESSAGE() msg
	rollback transaction
end catch
go

declare @shop varchar(max) = '07 ФАНФАН', @user varchar(max) = 'Федоров А. Н.'
--exec inv.invTakeCreate_p '08 ФАНФАН', 'ФЕДОРОВ А. Н.', @global = 0
declare @takeid int = 79817
select * 
--update i set i.closed= null
from inv.inventorytakes i where i.inventorytakeID= @takeid
--exec inv.transaction_delete 79818