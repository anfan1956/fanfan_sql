use fanfan
go

if OBJECT_ID ('web.order_action_p') is not null drop proc web.order_action_p
go
create proc web.order_action_p 
	@orderid int, 
	@cancel bit, 
	@note varchar(max) output, 
	@pmtStr varchar(max)=null	
as

set nocount on;
begin try
		declare 
			@r int,
			@transactionid int, 
			@reservation_state_id int,
			@customerid int = (select s.custid  from inv.site_reservations s where s.reservationid=@orderid),
			@userid int = (select userid from inv.site_reservations r where r.reservationid=@orderid);
		declare 
			@res int, 
			@JobName varchar(max)= cast(@orderid as varchar(max));
		declare @date datetime = current_timestamp;

		IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name = @Jobname)
			BEGIN
				exec @res = msdb.dbo.sp_delete_job 
					@job_name =  @JobName,  
					@delete_unused_schedule = 'True';	
			END;
	begin transaction		
		-- 0. Проверяем состояние заказа
		select @reservation_state_id = r.reservation_stateid
		from inv.site_reservations r 
		where r.reservationid=@orderid

		if @reservation_state_id>1 
			begin
				select @note = 'Ошибка. Заказ ' + @JobName + ' уже ' + s.reservation_state
				from inv.site_reserve_states s where s.reservation_stateid=@reservation_state_id;
				--'Kill the job'
				throw 50001, @note, 1
			end			
		else if @reservation_state_id is null 
			begin
				select @note = 'the order ' + @JobName + ' does not exist';
				throw 50001, @note, 1;
			end 
				
		if @cancel = 'True'			

			begin
				-- 1. Create new transaction  -  cancellation
				insert inv.transactions (transactiondate, transactiontypeID, userID)
				values (@date, inv.transactiontype_id('RESERVE CANCELLATION'), @userid);
				select @transactionid = SCOPE_IDENTITY();


				--2. update site reservations to "cancelled"
				update r set r.reservation_stateid= inv.reservation_state_id('cancelled')
					from inv.site_reservations r
					where r.reservationid= @orderid

				--3. return the inventory back from the order transaction with the opposite sign
					insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
					select i.clientID, i.logstateID, i.divisionID, @transactionid, -i.opersign , i.barcodeID 
					from inv.inventory i where i.transactionID =@orderid				
				select @note = 'Заказ № ' + cast (@orderid as varchar(max)) + 'удален';
				throw 50001,@note, 1
			end

		else if @cancel = 'False'
			begin
				if @pmtStr is null 
					begin
						select @note = 'Ошибка. Для того, чтобы записать продажу, нужно указать форму оплаты.';
						throw 50001, @note, 1
					end
				else
					begin
						declare @rec_types table (pmtType varchar(15), amount money, contractor varchar (25))
						declare @data table (myData varchar(max));
						declare @cross_table table (pmtType varchar(15), receipttypeID int)

						insert @data select value from string_split (@pmtStr, ',');
						UPDATE @data set myData = trim(myData);

						insert @cross_table (pmtType, receipttypeID) values
						('по карте', 5), 
						('по QR-коду', 7), 
						('по телефону', 8), 
						('наличными', 1), 
						('ссылка сбп', 9)

						insert @rec_types
						select 
							SUBSTRING(myData, 1, charindex(':', myData)-1) pmtType, 
							SUBSTRING(myData, charindex(':', myData)+1, charindex(':', myData, (charindex(':', myData, 1))+1)-charindex(':', myData)-1) amount,
							substring(myData, charindex(':', myData, (charindex(':', myData, 1))+1)+1,15) contractor
						from @data
					end


				-- 1. Create new transaction  -  'ON_SITE SALE'
				insert inv.transactions (transactiondate, transactiontypeID, userID)
				values (@date, inv.transactiontype_id('ON_SITE SALE'), @userid);
				select @transactionid = SCOPE_IDENTITY();
				select @r = @transactionid;


				-- 2. create sale transaction
				insert inv.sales(saleID, customerID, divisionID, salepersonID)
				values (@transactionid, @customerid, org.division_id('FANFAN.STORE'), @userid)

	
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
					@transactionid, rt.receipttypeID, r.amount, 
					case when r.pmtType in ('по телефону', 'ссылка сбп') then 7
					else rg.registerid end
				from @rec_types r
					join @cross_table c on c.pmtType=r.pmtType
					left join fin.receipttypes rt on rt.receipttypeID=c.receipttypeID
					left join org.contractors cn on cn.contractor = r.contractor
					left join acc.registers rg on rg.bankid = cn.contractorID and rg.clientid=org.client_id(org.division_id('FANFAN.STORE'));
				--select * from inv.sales_receipts sr where sr.saleID=@transactionid;

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
				
				select @r =@transactionid
			end		;

		--select @note = cast(@r as varchar(max));
		--throw 50001, @note, 1;
	commit transaction
	return @r;
end try

begin catch
	select @note =  ERROR_MESSAGE() 	
	rollback transaction
	select @r =0
	return @r
	
end catch
go

declare @r int, @cancel bit = 'False', @orderid varchar(max) = '77624', @note varchar(max), @pmtStr varchar(max) = 'по QR-коду:1.0:АЛЬФА-БАНК'; 
if @@TRANCOUNT>0 rollback transaction; 
--exec @r = web.order_action_p	@orderid =@orderid,	@cancel = @cancel, @note = @note output, @pmtStr= @pmtStr; select @r, @note;


--select top 1 * from inv.transactions order by 1 desc
