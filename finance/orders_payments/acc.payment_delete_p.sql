use fanfan 
go
select * from acc.transactions t
order by 1 desc

if OBJECT_ID('acc.payment_delete_p') is not null drop proc acc.payment_delete_p
go
create proc acc.payment_delete_p
	@note varchar(max) output, 
	@paymentid int 
as
set nocount on;
	begin try
		begin transaction
			declare @payments_deleted int;
			
			delete acc.invoices where invoiceid = @paymentid
			delete acc.entries where transactionid = @paymentid;
			delete acc.transactions  where transactionid = @paymentid;
			select @payments_deleted= @@ROWCOUNT;

			if @payments_deleted >0 
				select @note = 'transaction # '  + cast (@paymentid as varchar(max)) + ' deleted'
			else 
				select @note = 'transaction # '  + cast (@paymentid as varchar(max)) + '  did not exist'
			
--		select @note = 'debuggin';
--		throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare @note varchar(max), @paymentid int = 1101; exec acc.payment_delete_p @note output,	@paymentid; select @note;

