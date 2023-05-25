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
		@wait_minutes int
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


			insert inv.transactions (transactiondate, transactiontypeID, userID)
			values (@date, inv.transactiontype_id('ON_SITE RESERVATION'), @userid);
			select @reservationid =SCOPE_IDENTITY();


			insert inv.site_reservation_set(reservationid, barcodeid, price, barcode_discount, promo_discount, amount  )
			select @reservationid, i.barcodeid, i.price, i.discount, i.promo_discount, i.to_pay
			from @info i
			
			insert inv.site_reservations(reservationid, custid,reservation_stateid, expiration, userid)
			select @reservationid, @custid, inv.reservation_state_id('active'), @expiration, @userid;


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

