USE [fanfan]
GO

ALTER proc [inv].[cash_to_rep_p] (@saleid int ) as

--проверка
SET NOCOUNT ON;
declare @a money;
select @a = sum (amount) from inv.sales_receipts s where s.receipttypeID = inv.receipttype_id('hard cash') and s.saleID=@saleid;
if @a  is null return -1
else 
	update s set s.receipttypeID= inv.receipttype_id('hard cash to rep')
	from inv.sales_receipts s
	where s.saleID=@saleid and s.receipttypeID = inv.receipttype_id('hard cash') 
	return @a;
