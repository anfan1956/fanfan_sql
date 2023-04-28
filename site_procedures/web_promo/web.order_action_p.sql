if OBJECT_ID ('web.order_action_p') is not null drop proc web.order_action_p
go
create proc web.order_action_p 
	@orderid int, 
	@cancel bit, 
	@note varchar(max) output, 
	@pmtStr varchar(max)=null
	
as

set nocount on;
declare 
	@r int,
	@transactionid int, 
	@customerid int = (select s.custid  from inv.site_reservations s where s.reservationid=@orderid);
begin try
	begin transaction		
		declare @date datetime = current_timestamp;

		if @cancel = 'True'	
			begin
				-- 1. Create new transaction  -  cancellation
				insert inv.transactions (transactiondate, transactiontypeID, userID)
				values (@date, inv.transactiontype_id('RESERVE CANCELLATION'), org.user_id('interbot'));
				select @transactionid = SCOPE_IDENTITY();

				--2. update site reservations to "cancelled"
				update r set r.reservation_stateid= inv.reservation_state_id('cancelled')
					from inv.site_reservations r
					where r.reservationid= @orderid

				--3. return the inventory back from the order transaction with the opposite sign
					insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
					select i.clientID, i.logstateID, i.divisionID, @transactionid, -i.opersign , i.barcodeID 
					from inv.inventory i where i.transactionID =@orderid				
				select @r =@transactionid
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
				values (@date, inv.transactiontype_id('ON_SITE SALE'), org.user_id('interbot'));
				select @transactionid = SCOPE_IDENTITY();
				--select 1, * from inv.transactions where transactionID>=@transactionid

				-- 2. create sale transaction
				insert inv.sales(saleID, customerID, divisionID, salepersonID)
				values (@transactionid, @customerid, org.division_id('FANFAN.STORE'), org.user_id('interbot'))
				--select 2,  * from inv.transactions where transactionID>=@transactionid
				
				-- 3. create sale_goods
				insert inv.sales_goods( saleID, barcodeID, amount, price, client_discount, barcode_discount )
				select  @transactionid, rs.barcodeid, rs.amount, rs.price, rs.promo_discount, rs.barcode_discount 
				from inv.site_reservations r 
					join inv.site_reservation_set rs on rs.reservationid=r.reservationid
				where r.reservationid=@orderid and r.reservation_stateid=inv.reservation_state_id('active')
			--select @transactionID, i.barcodeID, i.paid, i.price, @customer_discount, i.discount	
			--from @info i;

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
				--select 3, * from inv.transactions where transactionID>=@transactionid


				--4. return the inventory back from the order transaction with the opposite sign
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
				--select 4, * from inv.transactions where transactionID>=@transactionid


				select @r =@transactionid
			end
		
	--'Kill the job'
		declare 
			@res int, 
			@name varchar(max)= cast(@orderid as varchar(max));

		exec @res = msdb.dbo.sp_delete_job 
			@job_name =  @name,  
			@delete_unused_schedule = 'True'  ;
		
		if @res = 1 
			begin
				select @note ='there was a problem deleting the job ' + @name;
				throw 50001,  @note, 1
			end

		select @note = cast(@r as varchar(max));
		--throw 50001, @note, 1;
	commit transaction
end try

begin catch
	select @note =  ERROR_MESSAGE() 
	rollback transaction
end catch
go

declare 
	@cancel bit = 'False',
	@orderid varchar(max) = '77301', 
	@note varchar(max), 
	@pmtStr varchar(max) = 'ссылка сбп:89778:ТИНЬКОФФ';

--exec web.order_action_p 
--	@orderid =@orderid, 
--	@cancel = @cancel,
--	@note = @note output, 
--	@pmtStr= @pmtStr
--	;
--select @note;

select i.*, l.logstate
from inv.inventory i 
	join inv.logstates l on l.logstateID=i.logstateID
where i.transactionID in ( 77259, 77260, 77261)

select * from inv.site_reservations order by 1 desc