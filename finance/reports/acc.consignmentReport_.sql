if OBJECT_ID('acc.consignmentReport_') is not null drop function acc.consignmentReport_
go

create function acc.consignmentReport_ (@vendor varchar(max), @account varchar(max)) returns table as return
	with s (saleid, orderid, brand, article, showroom, category, barcodeid, transtype) as (
		select 
			sg.saleID, 
			s.orderID,
			br.brand, 
			s.article,
			c.contractor showroom, 
			it.inventorytyperus category,
			sg.barcodeid, 
			tt.transactiontype transtype
		from inv.sales_goods sg
			join inv.transactions t on t.transactionID=sg.saleID
			join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
			join inv.barcodes b on b.barcodeID=sg.barcodeID
			join inv.styles s on s.styleID=b.styleID
			join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
			join inv.orders o on o.orderID=s.orderID
			left join org.contractors c on c.contractorid=o.showroomID
			join inv.brands br on br.brandID=s.brandID	
	)
	select 
		t.transactionid, 
		isnull(s.transtype, 'payment') transtype, 
		t.transdate,
		ar.article item, 
		t.amount * (2 * e.is_credit- 1) amount, 
		s.brand, s.category, s.article, 
		s.orderID,
		s.showroom, s.barcodeID,
		t.document, 
		t.comment + '; ' + isnull(isnull(cast(t.saleid as varchar(max)), c.contractor), '') comment, 
		isnull(
		CASE 
			WHEN ISNUMERIC(SUBSTRING(r.account, 1, 1)) = 1 THEN r.account
			ELSE 
			STUFF(right(r.account, len(r.account)-2), 3, 0, ' ') 
		END, 
		cast(t.saleid as varchar(max))) [register/saleid]
	from acc.transactions t 
		join acc.entries e on e.transactionid=t.transactionid
		join acc.accounts a on a.accountid=e.accountid
		join acc.entries e2 on e2.transactionid=t.transactionid and e2.is_credit<>e.is_credit
		join acc.articles ar on ar.articleid=t.articleid
		left join acc.registers r on r.registerid=e2.registerid
		left join org.contractors c on c.contractorID=r.bankid
		left join s on s.saleID= t.saleid and s.barcodeID= t.barcodeid
	where
		a.accountid = acc.account_id(@account)
		and e.contractorid = org.contractor_id(@vendor)
go

declare @date date = '20240101', @account varchar(max) ='счета к оплате', @contractor varchar(max)='E&N suppliers'

select * from acc.salesConsignment_(@date) s 
order by 1 desc


