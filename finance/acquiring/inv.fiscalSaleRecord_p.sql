if OBJECT_ID ('inv.fiscalSaleRecord_p') is not null drop proc inv.fiscalSaleRecord_p
go 
create proc inv.fiscalSaleRecord_p @receiptId varchar (50), @fiscalId varchar(50), @saleID int 
as
set nocount on;
set transaction isolation level read committed;
begin try
	begin transaction 
		declare @msg varchar (max);

		update s set 
			s.receiptid = @receiptId, 
			fiscal_id = @fiscalId
		from inv.sales s 
		where s.saleID =@saleid;

		update l set 
			l.closedTime = CURRENT_TIMESTAMP

		from acc.CardRedirectLog l where l.transactionId = @saleID;
/*
		select * from inv.sales s where s.saleID =@saleID
		select * from acc.CardRedirectLog
*/

		select @msg = cast(@@ROWCOUNT as varchar)
		select @msg rowsAffected
--;		throw 500001, @msg, 1
	commit transaction
end try
begin catch
	set @msg = ERROR_MESSAGE() 
	select @msg errorMsg
	rollback transaction
end catch
go 

/*
declare 
	@receiptId varchar (50) = '3403'
	, @fiscalId varchar(50) = 'jkfjdd8'
	, @saleID int  = 84862

exec inv.fiscalSaleRecord_p 
				@receiptId = @receiptId, 
				@fiscalID = @fiscalId, 
				@saleID  = @saleID;
*/