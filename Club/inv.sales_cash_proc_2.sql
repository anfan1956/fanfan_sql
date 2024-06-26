USE [fanfan]
GO

ALTER proc [inv].[sales_cash_proc_2] 
-- the original procedure is "inv.sales_cash_proc". this procedure is invented to account for the transactionss
-- that are not recorded due to a 1C failure, so it has 4 last additional parameters
	@datetime datetime,
	@customerid int, 
	@user varchar(25), 
	@division varchar (25), 
	@customer_discount decimal(4, 3), 
	@info inv.sales_cash_type readonly,
	@emp_id int, 
	@total money, 
	@card money, 
	@cash money, 
	@hard_cash MONEY, 
-- hardcoding char(4) as promocode is 4 digits string for now
	@promocode CHAR(4)

as 
set nocount on;
-- if the sale is today : record time as datetime value
if cast(@datetime as date)=CAST(getdate() as date) 
	set @datetime = getdate();

declare @clientid int, @transactionid int;
declare @divisionID int =(select divisionid from org.divisions where divisionfullname= @division) 
select @clientID = org.client_id( @divisionID )
declare @transactiontypeid int = (select inv.transactiontype_id('SALE CASH'));
declare @userid int = (select personid from org.persons where lfmname=@user)
declare @receipttypeid int =(select inv.receipttype_id('hard cash'))
DECLARE @sms_id INT;

if @card > 0 or @cash > 0  set @transactiontypeid = inv.transactiontype_id('SALE MIXED');

if @emp_id>0  
	begin
		select @transactiontypeid = inv.transactiontype_id('SALE INTERNAL');
		select @receipttypeid = inv.receipttype_id('company credit');
	end 
else select @total = 0;



	BEGIN TRY
		BEGIN TRANSACTION

		-- if smsid is null no record in sms.sales_promocodes
			SELECT TOP 1 @sms_id= i.smsid
			FROM sms.instances i
				JOIN sms.instances_customers ic ON ic.smsid=i.smsid
			WHERE ic.customerid= @customerid 
				AND	ic.promocode=@promocode
				AND i.expirationDate>=dbo.justdate(GETDATE())
			ORDER BY i.smsid DESC;


			insert inv.transactions ( transactiondate, transactiontypeID, userID )
				select @datetime, @transactiontypeid,  @userID;
			select @transactionid=SCOPE_IDENTITY();

		with _sign (logstateid, opersign) as 
		(
			select inv.logstate_id('IN-WAREHOUSE'), -1 
			union all 
			select inv.logstate_id('SOLD'), 1
		)
		insert inv.inventory
		select r.clientID, s.logstateID, 
			r.divisionID, 
			@transactionid transactionid, s.opersign, r.barcodeid
		from inv.v_remains r
			join @info i on i.barcodeid=r.barcodeid
			cross apply _sign s;

		insert inv.sales( saleID, divisionID, customerID, salepersonID )
			select @transactionID, @divisionID, @customerID, @userid;
		IF @sms_id IS NOT NULL 
		BEGIN
			INSERT sms.sales_promocodes (saleid, smsid)
				VALUES(@transactionID, @sms_id);
		END

		insert inv.sales_goods( saleID, barcodeID, amount, price, client_discount, barcode_discount )
			select @transactionID, i.barcodeID, i.paid, i.price, @customer_discount, i.discount	
			from @info i;


		with _receipts (receipttypeid, amount) as (
			select inv.receipttype_id('TS bank card'), @card union all
			select inv.receipttype_id('cash'), @cash union all
			select inv.receipttype_id('hard cash'), @hard_cash union all
			select inv.receipttype_id('company credit'), @total
			)
		insert inv.sales_receipts (saleID, receipttypeID, amount)
		select @transactionid, r.receipttypeid, amount
		from _receipts r where r.amount<>0;
		
		-- обновить клиентскую скидку после продажи
		exec cust.totals_update;

--		throw 50001, 'inv for account error', 1;
		
		COMMIT TRANSACTION
		return @transactionid
	END TRY
	BEGIN CATCH
		declare @note varchar (max);
		select @note = ERROR_MESSAGE();
		select @note;
		ROLLBACK TRANSACTION
	END CATCH
GO

set nocount on; declare @info inv.sales_cash_type; insert @info values (658171, 13024, 0, 13024, 13024); 
declare @customerid int = 1, @user varchar (25) = 'ГОРИНА И. А.', @division varchar (25) = '05 УИКЕНД', 
@customer_discount decimal (4, 3) = 0, @datetime datetime = '20220819', @r int; 
exec @r = inv.sales_cash_proc_2 @datetime,  @customerid, @user, @division, @customer_discount, @info, 0, 13024, 13024, 0, 0, NULL; select @r;
