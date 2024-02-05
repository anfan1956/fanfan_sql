
if OBJECT_ID('acc.transactionsWithSaleid_delete') is not null drop proc acc.transactionsWithSaleid_delete
go
create proc acc.transactionsWithSaleid_delete @saleid int as

begin try 
	begin transaction
		set nocount on;
		-- Declare a table variable
		DECLARE @TransactionTable TABLE (
			ID INT IDENTITY(1,1),
			TransactionID INT
		)

		-- Insert the transaction IDs into the table variable
		INSERT INTO @TransactionTable (TransactionID)
		SELECT t.transactionid FROM acc.transactions t WHERE t.saleid = @saleid

		-- Declare a variable to hold the current transaction ID
		DECLARE @CurrentTransactionID INT

		-- Declare a variable to hold the current row number
		DECLARE @CurrentRow INT = 1

		-- Declare a variable to hold the total number of rows
		DECLARE @TotalRows INT = (SELECT COUNT(*) FROM @TransactionTable)

		-- Start the loop
		WHILE @CurrentRow <= @TotalRows
		BEGIN
			-- Get the current transaction ID
			SELECT @CurrentTransactionID = TransactionID FROM @TransactionTable WHERE ID = @CurrentRow

			declare @note varchar(max)
			-- Execute the stored procedure
			EXEC acc.payment_delete_p @paymentid = @CurrentTransactionID, @note= @note output;

			-- Increment the current row number
			SET @CurrentRow = @CurrentRow + 1
		END
		exec inv.transaction_delete @saleid
	commit
end try
begin catch
	select ERROR_MESSAGE()
	if @@TRANCOUNT>0
		rollback

end catch
go


if @@TRANCOUNT >0 
	rollback
declare @saleid int =81062
exec acc.transactionsWithSaleid_delete @saleid