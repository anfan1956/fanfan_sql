USE [fanfan]
GO
/****** Object:  StoredProcedure [inv].[reservation_toggle_p]    Script Date: 24.05.2022 10:22:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [inv].[reservation_toggle_p] @reservationid int, @cancel bit = 'TRUE' as
set nocount on;
if not exists (select r.reservation_stateid from inv.site_reservations r where r.reservationid=@reservationid and r.reservation_stateid is null)
	return 0;

declare 
	@r int, @date datetime = getdate(),
--	hardcoding logstates 'IN-WAREHOUSE', 'SOLD', 'ИП Федоров'
	@logstateid int = iif (@cancel = 'TRUE', 8 , 10),
	@cancellation_typeid int = inv.transactiontype_id('RESERVE CANCELLATION'), 
	@sales_typeid int = inv.logstate_id('ON_SITE SALE'), 
	@userid int = org.user_id('INTERBOT'), @transactionid int;
begin try
begin transaction;
	if @cancel ='TRUE'
		begin
			update r set r.reservation_stateid = inv.reserve_state_id ('cancelled')
			from inv.site_reservations r
			where r.reservationid = @reservationid;
			select @date, @userid, @cancellation_typeid;

			update r set r.order_stateid = inv.site_order_state_id ('cancelled')
			from inv.site_reservation_set r where reservationid=@reservationid;

			insert inv.transactions (transactiondate, userID, transactiontypeID)
				values (@date, @userid, @cancellation_typeid);
			select @transactionid = SCOPE_IDENTITY();
			insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
			select i.clientID, i.logstateID, i.divisionID, @transactionid, i.opersign * (1-2 * @cancel), i.barcodeID 
			from inv.inventory i where i.transactionID =@reservationid


-- if reservation was automaticall cancelled, return 0
			select @r = @transactionid
		end 
	else 
		begin
			update r set r.reservation_stateid = inv.reserve_state_id ('executed')
			from inv.site_reservations r
			where r.reservationid = @reservationid;

			select @r = 1			
		end
	commit transaction
	return @r
end try

begin catch;
	--select ERROR_MESSAGE()
	rollback transaction
end catch
