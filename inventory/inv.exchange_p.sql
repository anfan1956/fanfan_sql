if OBJECT_ID ('inv.exchange_p') is not null drop proc inv.exchange_p
go 
create proc inv.exchange_p @soldid int, @exchangedid int, @user varchar(max) as
set nocount on ;

begin try 
	begin transaction 
		declare 
			@logstateid int, 
			@exchangeid int, 
			@divisionid int, 
			@clientid int

		select @logstateid = i.logstateid		
		from inv.inventory i
			where i.barcodeID=@soldid
		group by i.logstateID, i.barcodeID
		having sum(i.opersign)>0
		--select @logstateid

		if (@logstateid = inv.logstate_id('SOLD')) 
			begin 
				select top 1 @clientid = clientid, @divisionid=i.divisionID 
				from inv.inventory i
				where i.barcodeID = @soldid
				order by i.transactionID desc
				

				insert inv.transactions  (transactiondate, transactiontypeID, userID)
				select getdate(), inv.transactiontype_id('EXCHANGE'), org.person_id(@user)
				select @exchangeid = SCOPE_IDENTITY();
				--select @exchangeid;

				with _barcodes ( barcodeid, opersign) as (
					select @soldid, 1
					union all select @exchangedid, -1
				)
				, _states (logstateid, opersing) as
				(
					select inv.logstate_id('in-warehouse'), 1
					union 
					select inv.logstate_id('SOLD'), -1
				)
				insert inventory  (clientID, logstateID, divisionID, transactionID, barcodeID, opersign)
				select 
						@clientid clientid, 
						s.logstateid, 
						@divisionid, @exchangeid, 
						b.barcodeid, 
						b.opersign * 
						s.opersing opersign 
				from _barcodes b
					cross apply _states s
				join inv.logstates l on l.logstateID=s.logstateid

				--select * from inv.inventory i where i.transactionID= @exchangeid

				--select @logstateid = i.logstateid		
				--from inv.inventory i
				--	where i.barcodeID=@soldid
				--group by i.logstateID, i.barcodeID
				--having sum(i.opersign)>0
				--select @logstateid


				if @@ROWCOUNT>0
				select 'Операция обмена записана'

			end
		else
			begin
				select 
					'Обмен невозможен. текущее состояние товара: ' + l.logstate
				from inv.logstates l where l.logstateID =@logstateid
			end ;
--			throw 50001, 'debug', 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch

go




declare @soldid int = 663776, @exchangedid int =  663783,	@user varchar(max)= 'ФЕДОРОВ А. Н.'
--exec inv.exchange_p @soldid, @exchangedid, @user
