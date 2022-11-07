USE [fanfan]
GO

ALTER proc [inv].[cash_to_rep_p] (@saleid int, @receipttype_id int ) as

SET NOCOUNT ON;
declare @count int = (select count(*) from inv.sales_receipts sr where sr.saleID= @saleid);

if @count <>1 return -1
else 
	update s set s.receipttypeID= @receipttype_id
	from inv.sales_receipts s
	where s.saleID=@saleid 
	return @receipttype_id;

go 
declare @saleid int = 67853;
select count(*)
from inv.sales_receipts sr
where sr.saleID= @saleid