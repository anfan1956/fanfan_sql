USE [fanfan]
GO

	if OBJECT_ID('web.reservation_create') is not null drop proc web.reservation_create
	if TYPE_ID('web.reservation_type') is not null drop type web.reservation_type
	go

	create type web.reservation_type as table (
		barcodeid int,
		price money,
		discount money,
		promo_discount money, 
		selfdeliv_discount money, 
		logid int, 
		to_pay money
	)
	go

	create proc web.reservation_create
	/*
		клиентская скидка не работает
	*/
		@shop varchar(max), 
		@user varchar (max),
		@phone char(10),
		@info web.reservation_type readonly,
		@note varchar(max) output, 
		@wait_minutes int, 
		@pickupShopid int
	as
	set nocount on;
	begin try
		begin transaction

		declare	@barcodes inv.barcode_type;
		insert @barcodes select barcodeid from @info;

		if inv.available(@barcodes) = 'False'
			throw 50001, 'некоторые единицы товара сейчас недоступны', 1


		declare 
			@r int, 
			@reservationid int, 
			@userid int = (select personid from org.persons p where p.lfmname =@user),
			@divisionid int = org.division_id('fanfan.store'),
			@custid int =cust.customer_id(@phone), 
			@date datetime = CURRENT_TIMESTAMP;
		declare
			@expiration datetime = dateadd(MINUTE, @wait_minutes, @date) ;
			if @pickupShopid = 0 select @pickupShopid = null;

			--create new transaction - ON-SITE-RESERVATION
			insert inv.transactions (transactiondate, transactiontypeID, userID)
			values (@date, inv.transactiontype_id('ON_SITE RESERVATION'), @userid);
			select @reservationid =SCOPE_IDENTITY();

			--create new reservation with the just created transaction number - @reservationid
			insert inv.site_reservation_set(reservationid, barcodeid, price, barcode_discount, promo_discount, amount  )
			select @reservationid, i.barcodeid, i.price, i.discount, i.promo_discount, i.to_pay
			from @info i
			
			insert inv.site_reservations(reservationid, custid,reservation_stateid, expiration, userid, pickupShopid)
			select @reservationid, @custid, inv.reservation_state_id('active'), @expiration, @userid, @pickupShopid;


				with _states (logstateid, opersign) as (
					select inv.logstate_id('IN-WAREHOUSE'), -1 UNION SELECT inv.logstate_id('SITE_RESERVED'), 1
				)
				, s (clientid, divisionid, transactionid, barcodeid, logstateid, opersign) as (
					select r.clientID,  
						case s.opersign when 1 then @divisionid else r.divisionID end, 
						@reservationid, b.barcodeid, s.logstateid, s.opersign  
					from @info b
						join inv.v_remains r on r.barcodeID =b.barcodeid 
						cross apply _states s
					)
					insert inv.inventory (clientid, divisionid, transactionid, barcodeid, logstateid, opersign)
					select clientid, divisionid, transactionid, barcodeid, logstateid, opersign
					from s;

--						fill in delivery parcells
--						when the payment is done then update web.deleveryLogs with delivered
					update l set l.orderid = @reservationid
					from @info i 
						join web.deliveryLogs l on l.logid= i.logid

					--no delivery parcel is going to be created if logid is null or 0
					--the null is for standard and 0 for one click procs
					if (select logid from @info)is not null and (select logid from @info) not in (0)
					insert web.delivery_parcels (logid, barcodeid)

					select i.logid, barcodeid  from @info i


--						select  @transactionid;
				declare @start_date datetime = dateadd(MINUTE, @wait_minutes, @date ) 
				declare @job varchar (max) = @reservationid;
				declare @servername varchar(max) = @@servername;
				declare @job_date  char(8) = format(@start_date, 'yyyyMMdd')
				declare @job_time char(6) = format(@start_date, 'HHmmss');
				declare @tran_string varchar(max)= cast(@reservationid as varchar(max));
				declare @mycommand varchar(max) ='declare @r int, @reservationid int = ' + @tran_string +
					'; exec @r = fanfan.inv.reservation_toggle_p @reservationid;'
				exec @r= msdb.dbo.sp_add_job_quick 
						@job, @mycommand , @servername, 
						@job_date, @job_time; 
				if  @r = 0
					select @note = 'создан новый заказ ' + cast(@reservationid as varchar(max))  
			--;throw 50001, 'debugging', 1;
			commit transaction
		return @reservationid;			
		--return 1
	end try 
	begin catch
			select @note = ERROR_MESSAGE() 
			rollback transaction
			return 0;
	end catch
go

set nocount on; 
declare @info web.reservation_type; 
insert @info values 
	(658777, 19872, 0, 0.37, 0, 6, 12519.36), 
	(658789, 19872, 0, 0.37, Null, 7, 12519.36); 
declare 
	@shop varchar(max) = '08 ФАНФАН', @r int, @user varchar (max) = 'ИВАНОВА Т. К.', @phone char(10) = '9167834248', 
	@note varchar(max), @wait_minutes int = 120, @pickupShopid int = 0; 
--exec @r = web.reservation_create @shop=@shop, @user=@user, @phone=@phone, @info = @info, @note = @note output, @wait_minutes = @wait_minutes, @pickupShopid = @pickupShopid; select @note note, @r orderid;

select * from web.deliveryLogs order by 1 desc
select * from web.delivery_logs
--select * from web.delivery_parcels
--select * from web.deliveryAddresses
--select web.order_paid_(77866)