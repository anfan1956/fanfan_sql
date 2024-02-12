if OBJECT_ID('acc.tAccount_') is not null drop function acc.tAccount_
go

create function acc.tAccount_ (@account varchar(max), @contractor varchar(max), @date datetime ) returns table as return
	with s (transId, transDate, item, amount, document, orderid, showroom, brand, article, category, barcodeid, comment, [register/saleid]) as (
		select 
			0,  @date transdate, 'НАЧАЛЬНЫЕ ОСТАТКИ', 
			isnull(sum(amount), 0) amount, 
			'НО' document, '', '', '', '',  '',  '', 
			'calculated' comment, 'НО' [register/saleid]	
		from acc.consignmentReport_ (@contractor, @account) r
		where r.transdate < @date
		union all
		select transactionid, transdate, item, amount, document, r.orderID, r.showroom, r.brand, r.article, r.category, r.barcodeID, comment, [register/saleid]
		from acc.consignmentReport_ (@contractor, @account) r
		where r.transdate>=@date
	)
select * from s

go

declare @account varchar(max) = 'счета к оплате', @contractor varchar(max) ='E&N suppliers'
select * from acc.consignmentReport_(@contractor, @account)