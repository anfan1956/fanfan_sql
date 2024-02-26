declare @saleid int = 81160
--select * from inv.sales_receipts s order by 1 desc

--exec inv.transaction_delete @saleid

--exec acc.transactionsWithSaleid_delete @saleid
if OBJECT_ID ('rep.saleConsignment') is not null drop function rep.saleConsignment
go
create function rep.saleConsignment (@saleid int) returns table as return

select 
	t.transactiontypeID,
	sum(sg.amount) amount, rt.r_type_rus, sl.fiscal_id 
from inv.sales_goods sg
	join inv.sales_receipts sr on sr.saleID=sg.saleID
	join inv.sales sl on sl.saleID=sg.saleID
	join inv.transactions t on t.transactionID = sl.saleID	
	join inv.barcodes b on b.barcodeID= sg.barcodeID
	join inv.styles s on s.styleID=b.styleID
	join inv.orders o on o.orderID=s.orderID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
where sg.saleID = @saleid and o.vendorID = org.contractor_id('E&N suppliers')
group by rt.r_type_rus, sl.fiscal_id, t.transactiontypeID


go
if OBJECT_ID('rep.salesConsMessage') is not null drop function rep.salesConsMessage
go
create function rep.salesConsMessage (@saleid int) returns varchar(max) as
begin 
	declare @message varchar(max);
	if exists (select * from rep.saleConsignment(@saleid)) 
	select @message = CONCAT(
		case transactiontypeID when inv.transactiontype_id('RETURN') THEN 'return: ' 
		else 'sale: ' end, 
		'amount: ', amount, '\npmt: ', r_type_rus, '\nfiscal_id: ', ISNULL(fiscal_id, 'no FD')) from rep.saleConsignment(@saleid) 
	else select @message = '0'
	return @message;
end
go

declare @saleid int = 81151;
select * from rep.saleConsignment (@saleid);
select rep.salesConsMessage (@saleid)

select * from acc.transactions t order by 1 desc

--exec acc.transactionsWithSaleid_delete @saleid