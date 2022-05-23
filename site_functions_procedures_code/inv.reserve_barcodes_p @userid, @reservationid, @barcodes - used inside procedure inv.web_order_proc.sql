USE [fanfan]
GO

ALTER proc [inv].[reserve_barcodes_p] 
		@userid int, 
		@reservationid int,
		@barcodes inv.barcode_type readonly, 
		@message varchar(max) output as 

set nocount on;
	begin try
		begin transaction;
			with s (reservationid, barcodeid, price, barcode_discount, customer_discount, order_stateid) as (
			select  	
				@reservationid, b.barcodeid, p.price, isnull(p.discount, 0), club.cust_discount_f(@userid),
				inv.site_order_state_id ('reserved')
			from @barcodes b
				cross apply  inv.prices_barcodeid_f(b.barcodeid) p
			)
			insert inv.site_reservation_set (reservationid, barcodeid, price, barcode_discount, customer_discount, order_stateid)
			select reservationid, barcodeid, price, barcode_discount, customer_discount, order_stateid from s;
			--select * from inv.site_reservation_set s where s.reservationid = @reservationid;

			commit transaction;
		return 1
	end try
	begin catch
		select @message =  ERROR_MESSAGE()
		rollback transaction
		return -1
	end catch
	go

	declare @date datetime = current_timestamp, @userid int =17205, @transactionid int = 72225;
	declare @goods inv.web_order_type, @message varchar (max), @r int; 
	insert @goods (styleid, size, color, qty) values 
		(19212, 'XS', 'cappuchino', 1), 
		(19212, 'L', 'PENCIL', 2),
		(19314, 'L', '677 mist wi', 1), 
		(19321, 'M', 'CHARCOAL FUME', 1);
	declare @barcodes inv.barcode_type;
	insert @barcodes select barcodeid from inv.site_order_barcodes_f(@goods);

--exec @r  = inv.reserve_barcodes_p 
--	@userid  = @userid,
--	@reservationid = @transactionid,
--	@barcodes = @barcodes, 
--	@message = @message  output;
--select @r, @message;
select * from inv.site_reservations
select * from inv.site_reservation_set
--truncate table inv.site_reservation_set






