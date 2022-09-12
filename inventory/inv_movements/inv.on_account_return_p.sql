use fanfan
go
if object_id('inv.on_account_return_p') is not null drop proc inv.on_account_return_p
go

create proc inv.on_account_return_p 
	@barcodes inv.barcode_price_discount_type readonly, 
	@date date, 
	@transaction_division varchar(20), 
	@user varchar (50), 
	@note varchar(max) output, 
	@cust_discount money, 
	@receipt_type_id int, 
	@sales bit = 'False'
as 
begin try
	begin transaction;

-- check if return goes to the place barcodes were taken from if @transaction_division is '' then to the same
-- else to @transaction_division
-- create transaction, CUST_CONSMT_RETURN type
-- move inventory barcodes to logstate and division
-- make record in on inv.on_account

		declare @message varchar(max) = 'debuging';
		declare @divisionid int = 
			case @transaction_division 
				when '' then null else 
			(select divisionID from org.divisions where divisionfullname=@transaction_division )
			end;		
--		select @divisionid;
		declare @transactionID int;
		declare @transactiontype_id int = inv.transactiontype_id('CUST_CONSMT_RETURN');
		if @sales = 'True' 
			begin;
				select @transactiontype_id = inv.transactiontype_id('SALE MIXED');

			end 

--		create transaction
		insert inv.transactions (transactiondate, transactiontypeID, userID)
		values (@date, @transactiontype_id, org.person_id(@user));
		select @transactionID = SCOPE_IDENTITY();

--		insert inv.sales, inv.sales_receipts, inv.sales_goods
		if @sales = 'True'
--			для нахождения покупателя по функции объявляем переменную
			begin;
				declare @just_barcodes barcodes_list;
				insert @just_barcodes(barcodeID) select barcodeid from @barcodes;
				declare @customerid int;
				select @customerid= customerid from cust.customer_name_barcodes_f (@just_barcodes);

-- insert inv.sales
				with _s (saleid, divisionid, customerid, salepersonid) as (
					select @transactionID, d.divisionID, @customerid, org.person_id(@user)
					from 
						org.divisions d
					where d.divisionfullname = @transaction_division
				)
				insert inv.sales (saleid, divisionid, customerid, salepersonid)
				select saleid, divisionid, customerid, salepersonid from _s;

-- insert inv.sales_goods
				with _s(saleID, barcodeID, amount, price, client_discount, barcode_discount ) as (
					select 
						@transactionID, b.barcodeid, b.price *(1-b.discount) *(1 -@cust_discount), 
						b.price, @cust_discount, b.discount 
					from @barcodes b
				)
				insert inv.sales_goods 
				select 
					saleID, barcodeID, amount, price, client_discount, barcode_discount
				from _s;
				
				with _s (saleid, receipttypeid, amount) as (
					select @transactionID, @receipt_type_id, sum(b.price *(1-b.discount) *(1 -@cust_discount))
					from @barcodes b
					
				)
				insert inv.sales_receipts (saleID, receipttypeID, amount)
				select saleID, receipttypeID, amount from _s;
				declare @amount money = (
				select sum(amount) from inv.sales_receipts where saleID =  @transactionID);
			end;
			
--		create record in inventory		
		with _tr as (select top 1 i.transactionID  
		from inv.inventory i 
			join @barcodes b on b.barcodeID= i.barcodeID
		order by i.transactionid desc
		)
		, s as (
		select 
			i.clientID, i.logstateID,
			case i.opersign 
				when -1 then isnull(@divisionid, i.divisionid)
				when 1 then i.divisionID 
			end divisionid, 
--			i.divisionID,
			@transactionID transactionid, 
			-i.opersign opersign,
			i.barcodeID 
		from inv.inventory i
			join _tr t on t.transactionID= i.transactionID
			join @barcodes b on b.barcodeID= i.barcodeID
		)
		insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select clientID, logstateID, divisionID, transactionID, opersign, barcodeID
		from s;
--		select * from inv.inventory i where i.transactionID=@transactionID

		select @note = 
			'товар в количестве ' + cast((select count(*) from @barcodes) as varchar (max)) +
			' шт. ' + iif(@sales = 'True', ' на сумму ' + format(@amount, '#,##0;') + ' руб.', '') + 
			iif (@sales = 'True', 'продан', 'принят') + ' в магазине' + 
			case 
				when @divisionid is null then ', где он был выдан '
				else + ' ' + @transaction_division end

--		;throw 50001, @note, 1
	commit transaction
end try
begin catch
	select @note= ERROR_MESSAGE()
	rollback transaction
end catch
go

set nocount on; 
declare 
	@date date = '20220913', 
	@transaction_division varchar(20) =  '05 УИКЕНД', 
	@user varchar(50) =  'БАЛУШКИНА А. А.', 
	@sales bit = 'True', 
	@cust_discount money = 0.2,  
	@receipt_type_id int = 1, 
	@note varchar(max); 
declare @barcodes inv.barcode_price_discount_type; 
insert @barcodes values (658804, 24288, 0.3), (659760, 10560, 0.2); 
--exec inv.on_account_return_p 
--	@barcodes = @barcodes, 
--	@date = @date, 
--	@transaction_division = @transaction_division , 
--	@user = @user , 
--	@sales = @sales, 
--	@cust_discount = @cust_discount,  
--	@receipt_type_id = @receipt_type_id, 
--	@note = @note output; 
--select @note; 