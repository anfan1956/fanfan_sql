if OBJECT_ID ('web.reservation_json') is not null drop proc web.reservation_json
go 
create proc web.reservation_json @json varchar(max) as
set nocount on; 
begin try
	begin transaction

/*
	0. parse @json, declare parameters
		
		
	1. Check if inventory from is available
		z. the procedure is not working with barcodes
		a. if not - return error message
		b. else  - continue
	2. Create transaction
	3. Create site reservation_set - inv. set, mayb simultaneously with 1
	4. Create site reservation  - add to inv.reservations table
	5. insert resrvation set into inv.inventory
*/
-- 0.
		declare 
			
			@r int, 
			@wait_minutes int = 15,
			@reservationid int, 
			@spotid int,  
			@user varchar(max)='INTERBOT ',
			@userid int, 
			@phone char(10),
			@divisionid int = org.division_id('fanfan.store'), 
			@pickupid int,
			@custid int, 
			@procName varchar(max),
			@date datetime = CURRENT_TIMESTAMP;
		declare @expiration datetime = dateadd(MINUTE, @wait_minutes, @date);
		declare @data table (
				phone char(10), uuid varchar(max), procName varchar(max), styleid varchar(max), color varchar(max), size varchar(max), 
				qty varchar(max), discount varchar(max), price varchar(max), promo varchar(max), pickupid varchar(max), spotid varchar (max))


		;with s (phone, uuid, procName, styleid, color, size, qty, discount, price, promo, pickupid, spotid) as (
			select phone, uuid, procName, styleid, color, size, qty, discount, price, promo, pickupid, spotid
			from OPENJSON(@json)
			with 
				( 
					phone char(10) '$.phone',
					uuid char(36) '$.uuid',
					procName varchar(max) '$.procName',
					pickupid varchar(max) '$.pickupid',
					spotid varchar(max) '$.spotid',
					styleid varchar(max) '$.styleid',
					color varchar(max) '$.color',
					size varchar(max) '$.size',
					discount varchar(max) '$.discount',
					price varchar(max) '$.price',
					promo varchar(max) '$.promo',
					qty varchar(max) '$.qty'
				) as json_values
		)
		, trData as (
			select phone, uuid, procName, pickupid, spotid
			from s where styleid is null) 
		, inv as (
			select  t.phone, t.uuid, t.procName, t.pickupid, styleid,  color, size, qty, discount, price, promo, t.spotid
			from s
			cross apply trData t
			where s.phone is null
			)
		insert @data 
		select phone, uuid, procName, styleid, color, size, qty, discount, price, promo, pickupid, spotid
		from inv;					
		
		select distinct @pickupid = pickupid from @data d;				
		select distinct @procName = procName from @data d;				
		select distinct @spotid = spotid from @data d;				
		if @pickupid = 0 select @pickupid = null;
		if @spotid = 0 select @spotid = null;
		select distinct @phone = phone from @data d;		
		
		select @userid = org.user_id('INTERBOT')	
		select @custid = cust.customer_id(@phone);


		insert inv.transactions (transactiondate, transactiontypeID, userID)
		values (@date, inv.transactiontype_id(@procName), @userid);
		select @reservationid =SCOPE_IDENTITY();
--		select @reservationid;


		with s (parent_styleid, barcodeid, qty, price, discount, promo, num) as (
		select	
			st.parent_styleid, 
			b.barcodeID, 
			d.qty, 
			price * 1, 
			discount, 
			promo,
			ROW_NUMBER() over(
				partition by st.parent_styleid, cmn.norm_(c.color), sz.size 
				order by b.barcodeid
			) num 
		from inv.styles st 
			join inv.barcodes b on b.styleID=st.styleID
			join inv.colors c on c.colorID=b.colorID
			join inv.sizes sz on sz.sizeID=b.sizeID
			join @data d on d.styleid= st.parent_styleid
				and cmn.norm_(c.color) = cmn.norm_(d.color)
				and sz.size=d.size
			join inv.inventory i on i.barcodeID=b.barcodeID
		where 
			i.logstateID in (8) 
			and i.divisionID in (0,14,18, 25, 27) 
		group by 
			b.barcodeID, st.parent_styleid, price, discount, 
			cmn.norm_(c.color), sz.size, d.qty, promo
		having sum (i.opersign)>0
		)
		insert inv.site_reservation_set(reservationid, barcodeid, price, barcode_discount, promo_discount, amount  )
		select 
			@reservationid, barcodeID,  price, 
			discount, promo, 
			price * (1- isnull(cast(discount as dec(4,3)), 0)) *  (1- isnull(cast(promo as dec(4,3)), 0))				
		from s
		where num<=s.qty;
		
		insert inv.site_reservations(reservationid, custid,reservation_stateid, expiration, userid, pickupShopid)
		select @reservationid, @custid, inv.reservation_state_id('active'), @expiration, @userid, @pickupid;
--		select * from inv.site_reservations where reservationid= @reservationid;--------------------------------------------------------------------


		;with _info (barcodeid) as (
			select r.barcodeid from inv.site_reservation_set r where r.reservationid = @reservationid	
		)
		, _states (logstateid, opersign) as (
			select inv.logstate_id('IN-WAREHOUSE'), -1 UNION SELECT inv.logstate_id('SITE_RESERVED'), 1
		)
		, s (clientid, divisionid, transactionid, barcodeid, logstateid, opersign) as (
			select r.clientID,  
				case s.opersign when 1 then @divisionid else r.divisionID end, 
				@reservationid, b.barcodeid, s.logstateid, s.opersign  
			from _info b
				join inv.v_remains r on r.barcodeID =b.barcodeid 
				cross apply _states s
		)
		insert inv.inventory (clientid, divisionid, transactionid, barcodeid, logstateid, opersign)
		select clientid, divisionid, transactionid, barcodeid, logstateid, opersign
		from s;
--		select * from inv.inventory i where i.transactionID = @reservationid order by opersign, divisionID ---------------------------------------------;

--		select * from web.delivery_logs
		declare @code varchar(6) = (select r.code from cmn.random_6 r) 
		insert web.delivery_logs(orderid, spotid, pickupDivId, code)
		select @reservationid, @spotid, @pickupid, @code;

		/*
		!!!!!!!!!!! this to finish when dealing with deliveries !!!!
		*/
		--if (@spotid <> 0)
		--insert web.delivery_parcels (logid, barcodeid)
		--select i.logid, barcodeid
	--from @data i
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
				select  cast(@reservationid as varchar(max)) + ', '  + cast(@wait_minutes*60 as varchar(max)) pmtPars for json path 


--;throw 50001, 'debuggin', 1
	commit transaction;
end try
begin catch
	select ERROR_MESSAGE() error for json path
	rollback transaction
end catch

go
declare @json varchar(max);
select @json=
--'[{"phone": "9167834248", "Session": "00f8ec9f-38c1-4ae1-9b8c-8909984e6bd5", "spotid": "0", "procName": "ON_SITE RESERVATION"}, 
--	{"styleid": "13530", "color": "AMBER", "size": "2", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "1"}, 
--	{"styleid": "13530", "color": "WHITE", "size": "3", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "2"}
--]'
'[
	{"phone": "9637633465", "Session": "00a9f275-fd1e-4b65-a861-10842faca605", "spotid": 0, "pickupid": "27", "orderTotal": 35904, "procName": "ONE_CLICK"}, 
	{"styleid": 16752, "color": "UMBO", "size": "27", "price": 40800, "discount": 0, "promo": 0.12, "qty": "1", "total": 35904}
]'


--exec web.reservation_json @json



select * from web.delivery_logs
select top 6 t.*, tt.transactiontype 
	from inv.transactions t 
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
order by 1 desc
--select web.pmt_str_params_('False', 78987, 900, next value for web.ordersSequence)