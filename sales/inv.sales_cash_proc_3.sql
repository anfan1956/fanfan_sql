USE [fanfan]
GO

alter proc [inv].[sales_cash_proc_3] 
/**************************************************
	the following commentary relates to previous proc "inv.sales_cash_proc_2"
	the original procedure is "inv.sales_cash_proc". this procedure is invented to account for the transactionss
	that are not recorded due to a 1C failure, so it has 4 last additional parameters
	
	2024-11-19	updated with AP for consignment sales/returns
	2025-01-18	fiscalLimit	 for a division
				after the limit is reached sale receipt is redirected to Bunkovo
***************************************************/

	@datetime datetime,
	@customerid int, 
	@user varchar(25), 
	@division varchar (25), 
	@customer_discount decimal(4, 3), 
	@info inv.sales_cash_type readonly,
	@emp_id int, 
	@pmtForms as varchar(max), 
-- hardcoding char(4) as promocode is 4 digits string for now
	@promocode CHAR(4)
as 
set nocount on;
-- if the sale is today : record time as datetime value
if cast(@datetime as date)=CAST(getdate() as date) 
	set @datetime = getdate();

--declare @startDate date=dateadd(mm, -1, @datetime)
declare @startDate date='20240101'


declare @note varchar (max);
declare @clientid int, @transactionid int;
declare @divisionID int =(select divisionid from org.divisions where divisionfullname= @division) 
select  @clientID = org.client_id( @divisionID )
declare @transactiontypeid int = (select inv.transactiontype_id('SALE'));
declare @userid int = (select personid from org.persons where lfmname=@user)
declare @receipttypeid int 
DECLARE @sms_id INT;
declare @data table (myData varchar(max));
declare @rec_types table (pmtType varchar(15), amount money, contractor varchar (25))

declare @shopRegisterid int  = (
		select  v.registerid from acc.registerid_divisionid_v v 
			join org.divisions d on d.divisionID=v.divisionID
		where d.divisionfullname= @division
	);

insert @data select value from string_split (@pmtForms, ',');
UPDATE @data set myData = trim(myData);

declare	
	@redirect bit = 'False'
	, @IE_IvanovaRegisterID int = 29 -- stands for Individual Entrepreneur
	, @checkDivision varchar(255) = '05 УИКЕНД' -- division to redirect from 
	, @checkAmount money  ;
select @checkAmount = acc.FiscalLimitCurrent_(@divisionID);


declare @cross_table table (
	pmtType varchar(15), receipttypeID int
)
insert @cross_table (pmtType, receipttypeID) values
('по карте', 5), 
('по QR-коду', 7), 
('по телефону', 8), 
('наличными', 1), 
('hard cash', 3)
--select * from @cross_table;


insert @rec_types
select 
	SUBSTRING(myData, 1, charindex(':', myData)-1) pmtType, 
	SUBSTRING(myData, charindex(':', myData)+1, charindex(':', myData, (charindex(':', myData, 1))+1)-charindex(':', myData)-1) amount,
	substring(myData, charindex(':', myData, (charindex(':', myData, 1))+1)+1,15) contractor
from @data;

-- if payment by credit card in checkDivision  then redirect the fiscal receipt
if exists ( 
		select 1  checking
		from @rec_types t 
		where 1=1
			and pmtType in( 'по карте', 'по QR-коду')
			and @divisionID=org.division_id(@checkDivision)
			and acc.SalesFiscalThisMonth_(@checkDivision) > @checkAmount
	)
set @redirect = 'True';


if @emp_id>0  
	begin
		select @transactiontypeid = inv.transactiontype_id('SALE INTERNAL');
		select @receipttypeid = inv.receipttype_id('company credit');
	end 


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

	-- and now a big block of code to parse the payment information
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


		if (select  count (*)  from @rec_types r where r.pmtType<>'наличными') > 
				(select  count (*)  from @rec_types r where contractor <>'' and r.pmtType<>'наличными')
		throw 500001, 'операция не может быть записана. Не все регистры указаны' , 1
		

		insert inv.sales_receipts (saleID, receipttypeID, amount, registerid)
		select 
			@transactionid, rt.receipttypeID, r.amount, 
				case 
					when r.pmtType in ('наличными', 'по телефону', 'hard cash') then @shopRegisterid
				else 
					case @redirect 
						when  'False' then rg.registerid 
						when 'True' then @IE_IvanovaRegisterID
					end
				end					
		from @rec_types r
			join @cross_table c on c.pmtType=r.pmtType
			left join fin.receipttypes rt on rt.receipttypeID=c.receipttypeID
			left join org.contractors cn on cn.contractor = r.contractor
			left join acc.registers rg on rg.bankid = cn.contractorID and rg.clientid=@clientid;

		declare @rows int;
		select @rows= @@ROWCOUNT;

		--	insert into CardsLog if payment by credit card			
		if @redirect = 'True' 
		insert acc.CardRedirectLog (transactionId) values (@transactionid);
		--select top 1 * from acc.CardRedirectLog order by 1 desc;
/*
		При наличии формы оплаты "перевод по телефону" записываем ее как продажу наличными, но сразу выдаем в подотчет
		След if  нужен только для того, чтобы выдать под отчет. или заплатить счета к оплате if @contractor = 'ЕАФ'
		Все осатльное через acc.consignment_record
*/
		if (select amount from @rec_types where pmtType= 'по телефону') > 0 
			begin
				declare @bank varchar(25) = (select contractor from @rec_types where pmtType= 'по телефону');
				insert acc.transactions(transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid)
				select 
					cast (getdate() as date) transdate, 
					CURRENT_TIMESTAMP recorded, 
					@userid bookkeeperid, 
					643 currencyid, 
					--case @bank when 'ЕАФ' then acc.article_id('РАСЧЕТЫ ПО КОНСИГНАЦИИ')
					--else acc.article_id('ВЫДАЧА ПОД ОТЧЕТ') end articleid, 
					acc.article_id('ВЫДАЧА ПОД ОТЧЕТ'), 
					619 clientid, 
					r.amount,
					@division + ' в ' + @bank + ' ' + r.pmtType comment, 'cash' document, 
					@transactionid
				from @rec_types r where r.pmtType = 'по телефону';
				declare @transid int = scope_identity ();

				with _seed (is_credit, accountid, personid, registerid, contractorid) as (
					select 
						'True', 
						acc.account_id('деньги'), 
						null, @Shopregisterid, 
						null
					union all
					select 'False', 
						acc.account_id('подотчет') , 
						org.person_id('Федоров А. Н.') , 
						null, 
						null
				)
				insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
				select @transid transactionid, cast (is_credit as bit) is_credit, accountid, contractorid, personid, registerid 
				from _seed;
			end 
			
			declare @n int;
			exec @n = acc.consignment_record  @startdate;

			--exec acc.ConsignmentSalesAPs	

		select @note = 'number of rows inserted into inv.sales_receipts: ' + format(@rows, '#,##0', 'ru');

;--throw 50001, @note, 1;
		
		COMMIT TRANSACTION
		return @transactionid
	END TRY
	BEGIN CATCH

		select @note = ERROR_MESSAGE() ;
		select @note debug;
		ROLLBACK TRANSACTION
	END CATCH
go

set nocount on; declare @info inv.sales_cash_type; insert @info values (582711, 1500, 0, 1500, 1500); declare @customerid int = 1, 
@user varchar (25) = 'ФЕДОРОВ А. Н.', @division varchar (25) = '05 УИКЕНД', @customer_discount decimal (4, 3) = 0, @datetime datetime = '20250131', @r int; 
--exec @r = inv.sales_cash_proc_3 @datetime,  @customerid, @user, @division, @customer_discount, @info, 0, 'наличными:1500:Касса', NULL; select @r;