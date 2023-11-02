if OBJECT_ID ('inv.invTakeCreate_p') is not null drop proc inv.invTakeCreate_p
go 
create proc inv.invTakeCreate_p @shop varchar(max), @user varchar(max) as
	set nocount on;
begin try
begin transaction
	declare @transid int , @todaysCount int;
		select 
			@todaysCount = count(*) 
		from inv.transactions t 
			join inv.inventorytakes it on it.inventorytakeID=t.transactionID 
				and it.divisionID=org.division_id(@shop) 
				--and cast(t.transactiondate as date)= cast(getdate() as date)
			where it.closed is null
		if @todaysCount = 0 
			begin
				insert  inv.transactions(transactiondate, transactiontypeID, userID)
				select getdate(), inv.transactiontype_id('inventory take'), org.person_id(@user)
				select @transid = SCOPE_IDENTITY()

				insert inv.inventorytakes (inventorytakeID, divisionID)
					select @transid, org.division_id(@shop)

				--select * from inv.transactions t where t.transactionID=@transid;
				--select * from inv.inventorytakes t where t.inventorytakeID =@transid
				declare @mes varchar(max)  = 'создана инвентаризация № ' + cast (@transid as varchar(max))
				select @transid transid, @mes msg
			end
		else
			begin
				select top 1 @transid= t.transactionID
						from inv.transactions t 
			join inv.inventorytakes it on it.inventorytakeID=t.transactionID 
				and it.divisionID=org.division_id(@shop) 
				and cast(t.transactiondate as date)= cast(getdate() as date)
			order by t.transactionID desc
				select @transid transid,   'продолжаем инвентаризацию № ' + cast (@transid as varchar(max)) msg
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
--exec inv.invTakeCreate_p @shop, @user
--exec inv.invTakeCreate_p '07 ФАНФАН', 'Федоров А. Н.'


