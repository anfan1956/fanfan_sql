if OBJECT_ID ('web.order_action_json') is not null drop proc web.order_action_json
go
create proc web.order_action_json @json varchar(max) as
set nocount on;
	begin try
		begin transaction;

			declare @pmtStr table (orderid int, paymentid varchar(max), amount money, pmtStatus varchar(max), bank varchar(max))
			declare @stateid int, @userid int, @orderid int, @custid int;
			declare @state varchar(max), @note varchar(max);
			declare @res int, @JobName varchar(max), @transactionid int;
			declare @date datetime = current_timestamp;
			declare @clentid int = org.client_id(org.division_id('FANFAN.STORE'))
			declare @receipttypeid int = fin.receipttype_id('internet')
			declare @registerid int;

			with s  (orderid, paymentid, amount, pmtStatus, bank) as (
				select 
					left( orderid, charindex('-', orderid)-1) orderid, paymentid, amount/100, pmtStatus, bank
				from OPENJSON (@json)
				with (
					orderid varchar(max) '$.OrderId',
					paymentid varchar(max) '$.PaymentId',
					amount int '$.Amount',
					pmtStatus varchar(max) '$.Status', 
					bank varchar(max) '$.Bank'
				) as js
			)
		insert @pmtStr (orderid, paymentid, amount, pmtStatus, bank) 
		select orderid, paymentid, amount, pmtStatus, bank from s;
		select @orderid = orderid from @pmtStr;
		select @custid = custid from inv.site_reservations r where r.reservationid=@orderid;
		select @JobName =  orderid from @pmtStr;
		select @userid  = userid from inv.site_reservations r where r.reservationid=@orderid
		select @registerid = registerid from acc.registers r join org.contractors c on c.contractorID=r.bankid
			join @pmtStr p on p.bank=c.contractor


				-- 0. Проверяем состояние заказа
		select @state = s.reservation_state
		from inv.site_reservations r 
			join @pmtStr p on p.orderid=r.reservationid
			join inv.site_reserve_states s on s.reservation_stateid = r.reservation_stateid

		IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name = @Jobname)
			begin
				exec @res = msdb.dbo.sp_delete_job 
				@job_name =  @JobName,  
				@delete_unused_schedule = 'True';	
			end 
		
		if (@state = 'active') 
			begin
				-- 1. Create new transaction  -  'ON_SITE SALE'
				insert inv.transactions (transactiondate, transactiontypeID, userID)
				values (@date, inv.transactiontype_id('ON_SITE SALE'), @userid);
				select @transactionid = SCOPE_IDENTITY();

				-- 2. create sale transaction
				insert inv.sales(saleID, customerID, divisionID, salepersonID)
				values (@transactionid, @custid, org.division_id('FANFAN.STORE'), @userid)
	
				-- 3` prepare the fiscal string
				declare 
					@salesPers varchar(max) = (select lfmname from org.persons where personID = @userid),
					@saleid int = @transactionid,
					@barcodes dbo.id_money_type,
					@cash money = 0,
					@sale_type varchar(max) = 'sale';
				
				-- 3. create sale_goods
				insert inv.sales_goods( saleID, barcodeID, amount, price, client_discount, barcode_discount )
				output inserted.barcodeID, inserted.amount into @barcodes
				select  @transactionid, rs.barcodeid, rs.amount, rs.price, rs.promo_discount, rs.barcode_discount 
				from inv.site_reservations r 
					join inv.site_reservation_set rs on rs.reservationid=r.reservationid
				where r.reservationid=@orderid and r.reservation_stateid=inv.reservation_state_id('active')
				select @note = fin.fisc_String(	@salesPers, @saleid, @barcodes, @cash, @sale_type) ;


				-- 4. create sales_receipts transaction
				insert inv.sales_receipts (saleID, receipttypeID, amount, registerid)
				select 
					@transactionid, @receipttypeid, r.amount, 
					@registerid
				from @pmtStr r


				declare @rows int
				select @rows= @@ROWCOUNT;


				--5. update site reservations to "executed"
				update r set 
					r.reservation_stateid= inv.reservation_state_id('executed'), 
					r.saleid = @transactionid
				from inv.site_reservations r
				where r.reservationid= @orderid


				--6. return the inventory back from the order transaction with the opposite sign
					insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
					select 
						i.clientID, 
							case i.logstateID
								--when 20 then 10
								when inv.logstate_id('in-warehouse') then inv.logstate_id('sold')
								else i.logstateID
							end , 
						case i.opersign 
							when 1 then i.divisionID
							else org.division_id('FANFAN.STORE') 
						end, 
						@transactionid, 
						-i.opersign, 
						i.barcodeID 
					from inv.inventory i where i.transactionID =@orderid			


--		do I really need it?
				--7. return the payment link to 'executed'
					--update l set l.stateid = web.paymentLinkState_id('executed')
					--from web.payment_links l where l.orderid = @orderid
					select @transactionid new_sale for json path					
			end	;

		else
			begin;
					select @note =(select 0 error for json path)
					select @note;
--				throw 50001, @note, 1
			end 

		commit transaction
	end try

	begin catch
		select error_message() error for json path
		rollback transaction
	end catch
go

declare @json varchar(max)
select @json =
	--{"TerminalKey": "1696935466962", "OrderId": "79118-672", "Success": true, "Status": "CONFIRMED", "PaymentId": 3372975894, "ErrorCode": "0", "Amount": 150, 
	--"CardId": 357089169, "Pan": "528041******0988", "ExpDate": "1029", "Token": "61e701ee18d4aa8078deb46e6b81b87759f9fc117457d613d05aae89a58c5af5", "Bank": "ТИНЬКОФФ"  }
'[
	{
		"TerminalKey": "1696935466962", "OrderId": "79123-675", "Success": true, "Status": "AUTHORIZED", "PaymentId": 3376391662, "ErrorCode": "0", "Amount": 150, 
		"CardId": 357089169, "Pan": "528041******0988", "ExpDate": "1029", "Token": "dbd1e17f2bde43ddcc6b5cf5195a695e0787f2129e841e279e655d8594f3ac25", "Bank": "ТИНЬКОФФ"  
	}

]' ;

---exec web.order_action_json @json
--select * from inv.site_reserve_states

--select * from inv.site_reservations where reservationid =79123

---exec web.order_action_json '[{"TerminalKey": "1696935466962", "OrderId": "79148-691", "Success": true, "Status": "CONFIRMED", "PaymentId": 3377244069, "ErrorCode": "0", "Amount": 110, "CardId": 357089169, "Pan": "528041******0988", "ExpDate": "1029", "Token": "a737701f210db359b894902a06f8ab92d2a497d6d3e9722406507800d28b9506", "Bank": "tinkoff"}]'
