if OBJECT_ID('inv.webOrders_toShip_v') is not null drop view inv.webOrders_toShip_v
go
create view inv.webOrders_toShip_v as

	with _trans (barcodeid, transactionid, trtypeid, trtype, salesPersonid, receipt_id, fiscal_id) as (
		select distinct 
			i.barcodeid,  i.transactionID, tr.transactiontypeID, tt.transactiontype, 
			s.salepersonID, 
			s.receiptid, 
			iif(s.fiscal_id='', '809343', s.fiscal_id)
		from inv.inventory i 
			join inv.sales_goods sg on sg.barcodeID=i.barcodeID
			join inv.sales s on s.saleID=sg.saleID and s.divisionID = 31
			join inv.transactions tr on i.transactionid=tr.transactionID
			join inv.transactiontypes tt on tt.transactiontypeID=tr.transactiontypeID
		where tr.transactiontypeID in (32, 34)
	)
	, _trNum(barcodeid, transid, salesPersonid, num, receipt_id, fiscal_id) as (
		select  t.barcodeid, transactionid, t.salesPersonid, 
				ROW_NUMBER() over(partition by barcodeid order by transactionid desc),
			receipt_id, fiscal_id
		from _trans t
	)
	, _bc_reserv (barcodeid, transid, salesPersonid, receipt_id, fiscal_id) as (
		select barcodeid, transid, salesPersonid, receipt_id, fiscal_id
		from _trNum where num = 2
	)
	, _all_transactions (barcodeid, salesPersonid, logstateid, divisionid, orderid, receipt_id, fiscal_id) as (
		select distinct b.barcodeid, b.salesPersonid, i.logstateID, i.divisionID, b.transid, receipt_id, fiscal_id
		from _bc_reserv b
			join inv.inventory i on i.barcodeID=b.barcodeid 
				and i.transactionID<b.transid
			group by 
				b.barcodeid, i.logstateID, i.divisionID, 
				b.transid, b.salesPersonid, receipt_id, fiscal_id
		having sum(opersign)>0
	)
	select 
		a.orderid, 
		t.transactiondate [дата заказа], 
		cast(l.phone as bigint) [телефон клиента], 
		u.lfmname консультант,
		s.styleID модель,
		s.article артикул, 
		it.inventorytyperus категория, 
		rs.barcode_discount скидка, 
		rs.promo_discount [промо скидка], 
		a.barcodeid баркод, 
		d.divisionfullname [склад], 
		sz.size размер, 
		c.color цвет,
		rs.price цена, 
		rs.amount оплачено, 
		a.divisionid, 
		r.custid, 
		a.salesPersonid, 
		br.brand бренд, 
		'fw.' + format(getdate(), 'yy.') + format(getdate(), 'MM.')  + format(receipt_id, '0,#') чек, 
		cast(fiscal_id as varchar(max)) ФПД
	from _all_transactions a
		join inv.transactions t on t.transactionID=a.orderid		
		join inv.site_reservations r on r.reservationid=a.orderid
		join inv.site_reservation_set rs on rs.reservationid=a.orderid and rs.barcodeid=a.barcodeid
		join cust.customers_list_v l on l.personID=r.custid
		join org.divisions d on d.divisionID=r.pickupShopid
		join inv.barcodes b on b.barcodeID=a.barcodeid
		join inv.styles s on s.styleID=b.styleID
		join inv.brands br on br.brandID=s.brandID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.sizes sz on b.sizeID=sz.sizeID
		join inv.colors c on c.colorID=b.colorID 
		join org.persons u on u.personID = a.salesPersonid
go	
--select *from inv.webOrders_toShip_v where orderid =0

select 
*
--	orderid, модель, баркод, цена 
from inv.webOrders_toShip_v --where orderid = 77767
