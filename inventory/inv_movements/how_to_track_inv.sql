use fanfan
go

--SELECT * FROM inv.logstates l
/*
barcodes
divisionid
customerid
userid
date
price consigned to customer
settlement date
transactionid

	in order to maintain need to create table, cust.on_account
*/


if OBJECT_ID('cust.on_account')is not null drop table cust.on_account 

create table cust.on_account(                --fill in the constraints
	customerid int not null ,
	transactionid INT NOT NULL, 
	deadline date not null,
	barcodeid INT NOT NULL, 
	price MONEY NOT null,
	discount DECIMAL(4,3)
)

if OBJECT_ID ('inv.customer_on_account_p') is not null drop proc inv.customer_on_account_p
if type_id('inv.barcode_price_discount_type') is not null drop type inv.barcode_price_discount_type
GO
CREATE type inv.barcode_price_discount_type as table (barcodeid int, price money, discount dec(4,3))
go
create PROC inv.customer_on_account_p  
	@barcodes inv.barcode_price_discount_type READONLY,
	@userid INT, 
	@customerid INT,
	@date date,
	@credit BIT,
	@note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin TRANSACTION

		DECLARE @transactionid INT, @transactiontypeid int;

-- select type of transaction if the merch is given to customer or taken back from him
		SELECT @transactiontypeid= CASE @credit 
				WHEN 'TRUE' THEN inv.transactiontype_id('CUSTOMER CONSIGNMENT')
				ELSE inv.transactiontype_id('CUSOTMER CONSIGNMENT RETURN') END

		DECLARE @opersign INT = 1- 2 * @credit;

-- create new transaction of the above type
		INSERT INV.transactions(transactiontypeID, userID)
		SELECT @transactiontypeid, @userid	
		SELECT @transactionid =  SCOPE_IDENTITY();

-- move inventory to/from the customer account
		WITH _seed (opersign, divisionid) AS 
		(
			SELECT @opersign, NULL UNION ALL
			SELECT -@opersign, org.division_id('НА РУКАХ У КЛИЕНТОВ')
		)
		, fin AS (
		SELECT b.barcodeID, v.logstateID, 
			v.clientID, @transactionid transactionid, 
			s.opersign, ISNULL(s.divisionid, v.divisionID) divisionid
		FROM @barcodes b
		JOIN inv.v_r_inwarehouse v ON v.barcodeID=b.barcodeID
			CROSS APPLY _seed s
		)
		INSERT inv.inventory (barcodeID, logstateID, clientID, transactionid, opersign, divisionid)
		SELECT f.barcodeID, f.logstateID, f.clientID, f.transactionid, f.opersign, f.divisionid
		FROM fin f;

		WITH _prices (barcodeid, price, discount) AS (
				SELECT 
					b.barcodeID, b.price, b.discount
				from @barcodes b	
			)
		INSERT cust.on_account (customerid, transactionid, deadline, barcodeid, price, discount)
		SELECT 
			@customerid, @transactionid, @date, p.barcodeid, p.price, p.discount 		
		FROM _prices p;
--		SELECT * FROM cust.on_account oa;

	set @note = 'Записано в транзакции №' + cast(@transactionid as varchar(max)) + ' до '  
		+ format (@date, 'dd.MM.yyyy');
	--throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
		
set nocount on; 
declare @note varchar (max); 
DECLARE @userid INT = 37, @customerid INT = 17365,  @deadline date = '20220902'; 
DECLARE @barcodes inv.barcode_price_discount_type; 
INSERT @barcodes VALUES (658746, 22880, 0.3), (662599, 12320, 0); 
--EXEC inv.customer_on_account_p 
--	@barcodes=@barcodes, 
--	@userid=@userid, 
--	@credit ='True', 
--	@date = @deadline, 
--	@note = @note OUTPUT, 
--	@customerid = @customerid ; 
--select @note


