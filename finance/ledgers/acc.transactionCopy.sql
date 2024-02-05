
if OBJECT_ID('acc.transactionCopy') is not null drop proc acc.transactionCopy
go
create proc acc.transactionCopy (@refid as int) as

BEGIN TRY
    BEGIN TRANSACTION
		declare @transid int ;

		set nocount on;
    -- Insert statement
	INSERT INTO acc.transactions(transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
	select 
		transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document
	from acc.transactions t where t.transactionid = @refid
	select @transid = SCOPE_IDENTITY();
--	select @transid;

	insert acc.entries (transactionid, is_credit, accountid, contractorid,	personid, registerid)
    select  
		@transid, is_credit, accountid, contractorid,	personid, registerid
	from acc.entries e		
	where e.transactionid =  @refid
---	select * from acc.entries e where e.transactionid = @transid
	select 'transaction ' + str(@transid) + ' copied'

--;	throw 50001, 'debug', 1
    COMMIT TRANSACTION

END TRY
BEGIN CATCH
	select  ERROR_MESSAGE() msg
    -- Rollback the transaction if an error occurs
    ROLLBACK TRANSACTION

    -- Handle or log the error as needed
    PRINT ERROR_MESSAGE()
END CATCH

go

--exec acc.transactionCopy 5790

