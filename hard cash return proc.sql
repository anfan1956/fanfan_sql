USE [fanfan]
GO
/****** Object:  StoredProcedure [inv].[hardcash_return_proc]    Script Date: 15.05.2022 12:44:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [inv].[hardcash_return_proc] @info dbo.id_money_type readonly, @saleid int, @date datetime, @userid int, @division varchar(25),
	@note varchar(max) output as
	set nocount on;
	--   receipttypeid references fin.receipttypes table

	--1. проверить то, что баркоды из @info были в @saleid в данный момент находятся в logstate "sold"
			--for that the function RAISERROR is use with the severity of 16 then it transfers to 'Begin catch' 
	--2. создать новую транзакцию
	--3. переместить товар в таблице inv.inventory
	--4. insert into inv.sales
	--5. inv.sales_goods
	--6. inv.sales_receipts
	begin try
		begin transaction
			declare @trandtypeid int = (select inv.transactiontype_id('RETURN'));
			declare @stateid int = inv.logstate_id('SOLD');
			declare @count int=(select distinct count(i.id) from @info i);
			declare @divisionid int =(select divisionid from org.divisions where divisionfullname=@division)
			declare @customerid int =(select customerID from inv.sales where saleID=@saleid);
			declare @receipttypeid int  --=inv.receipttype_id('hard cash');
--			select @receipttypeid = (select receipttypeID from inv.sales_receipts where saleID = @saleid)
			declare @amount table (amount money);
			declare @returnid int;


			if @count<> (select count (*) from inv.v_remains r join @info i on i.id=r.barcodeID 
							where  r.logstateID=@stateid and r.divisionID=@divisionid)
				begin
					RAISERROR ( 'Товар не был продан в этом магазине. Обратитесь к администратору',16,1);
					rollback transaction;			
				end
			insert inv.transactions (transactiondate, transactiontypeID, userID)
			values (@date, @trandtypeid, @userid)
			select @returnid=SCOPE_IDENTITY();


			with _sign (logstateid, opersign) as 
			(
				select inv.logstate_id('SOLD'), -1 
				union all 
				select inv.logstate_id('IN-WAREHOUSE'), 1
			)
			insert inv.inventory
			select distinct r.clientID, s.logstateID, 
				r.divisionID, 
				@returnid transactionid, s.opersign, r.barcodeid
			from inv.v_remains r
				join @info i on i.id=r.barcodeid
				cross apply _sign s;			
			


			insert inv.sales( saleID, divisionID, customerID, salepersonID )
			select @returnid, @divisionID, @customerID, @userid;

			insert inv.sales_goods(saleID, barcodeID, amount, price, client_discount, barcode_discount)
			output -inserted.amount into @amount
			select distinct @returnid, s.barcodeID, -s.amount, s.price, s.client_discount, s.barcode_discount 
			from inv.sales_goods s join @info i on i.id=s.barcodeID where s.saleID=@saleid			;
	
			
			--inserted abs on the 29.08.2021

			with s as (
				select saleID, receipttypeID, amount 
				from inv.sales_receipts sr where sr.saleID=@saleid
			), 
			_amount (saleid, amount, receipttypeid) as ( 
			select s.saleID, 
				case when  s.receipttypeID in (2, 5)
					then case when s.amount > a.amount then a.amount
						else s.amount end
				 when s.receipttypeID not in (2, 5)
					then case when s.amount > a.amount then 0
						else s.amount end					
				end 
				, s.receipttypeID
			from s 
				cross apply @amount  a
		)				
			insert inv.sales_receipts (saleID, receipttypeID, amount)
			select @returnid, a.receipttypeid, a.amount 
			from _amount a;

			exec cust.totals_update;
			
			set @note = (select 'Операция прошла успешно. К возврату - ' +
				cast (SUM (s.amount) as varchar(max)) + '' 
			from @amount s); 

		--set @note = 'Сумма к возврату   ' + Cast (-@amount as varchar (max))
--		;throw 50001, @note, 1
		commit transaction
	end try
	Begin catch
		set @note =  ERROR_MESSAGE()
		rollback transaction
	end catch
go

--set nocount on; declare @info dbo.id_money_type, @saleid int= 72147, @date datetime = '20220515', @note varchar(max), @userid int =1, 
--	@division varchar (25) = '07 ФАНФАН'; 
--insert @info values (658212, 3838), (658212, 10000); 
----exec inv.hardcash_return_proc @info, @saleid, @date, @userid, @division, @note output; select @note;

