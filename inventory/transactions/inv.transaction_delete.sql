USE [fanfan]
GO
/****** Object:  StoredProcedure [inv].[transaction_delete]    Script Date: 03.02.2024 22:52:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure inv.transaction_delete
	@transactionID int
as
begin

	set nocount on;

	begin transaction;

	begin TRY		
		if exists (select * from inv.transactions t where t.transactionID=@transactionID )
			begin
				delete c from inv.storage_box c where c.transactionId =@transactionID
				delete c from acc.CardRedirectLog c where c.transactionId =@transactionID
				delete s from inv.invTake_barcodes s where s.takeid=@transactionID
				delete s from web.delivery_logs s where s.orderid =@transactionID
				delete s from web.sales_log s where s.saleid= @transactionID		
				delete p from web.payment_links p where p.orderid=@transactionID
				DELETE cust.on_account WHERE transactionid = @transactionID
				DELETE sms.sales_promocodes WHERE saleid =  @transactionID
				delete inv.site_reservation_set where reservationid= @transactionID
				delete inv.site_reservations where reservationid= @transactionID
				delete c1.queue where  operationID=@transactionID
				delete bud.ordersdebts where  transactionID=@transactionID
				delete inv.inventorytakes where inventorytakeID = @transactionID
				delete inv.orders where orderID = @transactionID
				delete inv.confirmations where confirmationID = @transactionID
				delete inv.deliverynotes where deliverynoteID = @transactionID
				delete inv.pickups where pickupID = @transactionID
				delete inv.shipmentdetails where shipmentID = @transactionID
				delete inv.shipments where shipmentID = @transactionID
				delete inv.customsclearances where customsclearanceID = @transactionID
				delete inv.customsdeliveries where customsdeliveryID = @transactionID
				delete inv.whclearances where whclearanceID = @transactionID
				delete inv.waybills where waybillID = @transactionID

				delete c1.imported_transactions where transactionID = @transactionID
				delete inv.sales_goods where saleID = @transactionID
				delete inv.sales_receipts where saleID = @transactionID
				delete inv.sales where saleID = @transactionID

				delete inv.inventory where transactionID = @transactionID

				delete inv.prices where pricesetID in ( select pricesetID from inv.pricesets where transactionID = @transactionID )
				delete inv.pricesets where transactionID = @transactionID


				delete inv.pricesets_divisions where barcodeID in (
						select barcodeID from inv.barcodes 
						where colorID in ( select colorID from inv.colors where orderID = @transactionID )
						)
				delete hst.barcodes_read where barcodeID in (
						select barcodeID from inv.barcodes 
						where colorID in ( select colorID from inv.colors where orderID = @transactionID )
						)
						
				delete inv.barcodes where colorID in ( select colorID from inv.colors where orderID = @transactionID )
				delete inv.colors where orderID = @transactionID
				delete inv.prices where styleID in ( select styleID from inv.styles where orderID = @transactionID )
				delete inv.styles where orderID = @transactionID
				delete s from inv.compositionscontent s where s.orderID=@transactionID
				delete s from inv.compositions s where s.orderID=@transactionID

				delete inv.transactions where transactionID = @transactionID

				print 'transaction ' + cast( @transactionID as varchar ) + ' deleted'
			end
		else 
			begin
				--commit transaction
				print 'transaction ' + cast( @transactionID as varchar ) + ' does not exist'
			end

				if @@trancount > 0
					commit transaction
	end try
	begin catch
		if @@trancount > 0
			rollback --transaction
		select cmn.errormessage()
		return -1
	end catch

	return 0
end
