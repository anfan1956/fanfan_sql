USE [fanfan]
GO

if OBJECT_ID('inv.web_order_proc') is not null drop proc inv.web_order_proc
go 
create proc inv.web_order_proc

		@customerid int, 
		@goods inv.web_order_type readonly,
		@message varchar(max) output, 
		@wait_minutes int
	as
	set nocount on;
	begin try
		begin transaction

		declare 
			@barcodes inv.barcode_type,
			@r int, @transactionid int, 
			@divisionid int = org.division_id('fanfan.store'), 
			@userid int = org.user_id('INTERBOT'), 
			@date datetime = CURRENT_TIMESTAMP;

			insert @barcodes select barcodeid from inv.site_order_barcodes_f(@goods);
			if (select sum (qty) from @goods) > (select count (barcodeid) from @barcodes)
				begin
					declare @count int = ( select count (barcodeid) from inv.site_order_barcodes_f(@goods))
					select @message = 
						'часть товара стала недоступна. вместо ' + 
						format(sum(g.qty), '#,##0') + ' единиц в наличии:' + format (@count, '#,##0' )
					from @goods g;
					throw 50001, @message, 1
				end 

			insert inv.transactions (transactiondate, transactiontypeID, userID)
			values (@date, inv.transactiontype_id('ON_SITE RESERVATION'), @userid);
			select @transactionid =SCOPE_IDENTITY();

			exec @r = inv.reserve_barcodes_p @userid, @transactionid, @barcodes, @message output;
				if @r = -1
					begin
						select @message =(select  'товар больше не доступен. Обновите корзину' ответ for json path, root);
						throw 50001, @message, 1
					end
				else 
					begin
						insert inv.site_reservations(userid, reservationid) select @customerid, @transactionid;
						--select * from inv.site_reservations;

						with _states (logstateid, opersign) as (
							select inv.logstate_id('IN-WAREHOUSE'), -1 UNION SELECT inv.logstate_id('SITE_RESERVED'), 1
						)
						, s (clientid, divisionid, transactionid, barcodeid, logstateid, opersign) as (
							select r.clientID,  
								case s.opersign when 1 then @divisionid else r.divisionID end, 
								@transactionid, b.barcodeid, s.logstateid, s.opersign  
							from @barcodes b
								join inv.v_remains r on r.barcodeID =b.barcodeid 
								cross apply _states s
							)
							insert inv.inventory (clientid, divisionid, transactionid, barcodeid, logstateid, opersign)
							select clientid, divisionid, transactionid, barcodeid, logstateid, opersign
							from s;

--						select  @transactionid;
						declare @start_date datetime = dateadd(MINUTE, @wait_minutes, @date ) 
						declare @job varchar (max) = @transactionid;
						declare @servername varchar(max) = @@servername;
						declare @job_date  char(8) = format(@start_date, 'yyyyMMdd')
						declare @job_time char(6) = format(@start_date, 'HHmmss');
						declare @tran_string varchar(max)= cast(@transactionid as varchar(max));
						declare @mycommand varchar(max) ='declare @r int, @reservationid int = ' + @tran_string +
							'; exec @r = fanfan.inv.reservation_toggle_p @reservationid;'
						exec msdb.dbo.sp_add_job_quick 
								@job, @mycommand , @servername, 
								@job_date, @job_time; 
					end;
			--;throw 50001, 'debugging', 1;
			commit transaction
		return @transactionid;			
	end try 
	begin catch
			select @message = ERROR_MESSAGE() 
			rollback transaction
			return 0;
	end catch
go

declare 
	@r int,
	@goods inv.web_order_type, 
	@userid int =  17205, @message varchar(max) , 
	@time int = 3;
insert @goods (styleid, size, color, qty) values 
	(19212, 'XS', 'cappuchino', 1), 
	(19212, 'L', 'PENCIL', 1),
	(19314, 'L', '677 mist wi', 0), 
	(19321, 'M', 'CHARCOAL FUME', 1);
--exec @r = inv.web_order_proc 
--	@customerid = @userid,	
--	@goods = @goods,
--	@message = @message output, 
--	@wait_minutes = @time;
--select @r, @message;

select * from inv.site_reservation_set;
select * from inv.site_reservations s join inv.site_reserve_states r on r.reservation_stateid=s.reservation_stateid;
select * from inv.inventory i where i.transactionID = @r;

 
 
 