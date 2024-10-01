select top 1 * from inv.sales s  join inv.sales_receipts r on r.saleID = s.saleID order by 1 desc
/*
	python "Z:\Управление предприятием\accounting\Prop_soft\sale_fiscal.py" "ФЕДОРОВ А. Н." 84848 "'663892','ДЖИНСЫ',30600;'663894','ДЖИНСЫ',30600" 0 "sale"
*/

if OBJECT_ID ('acc.CardSaleReceipts_v') is not null drop view acc.CardSaleReceipts_v
go 
create view acc.CardSaleReceipts_v as
select 
	tt.transactiontype ttype
	, l.transactionId transId
	, p.lfmname person
	, sg.barcodeID barcode
	, it.inventorytyperus invType
	, sg.amount 
from acc.CardRedirectLog l
	join inv.sales s on s.saleID = l.transactionId
	join org.persons p on p.personID =s.salepersonID
	join inv.sales_goods sg on sg.saleID=s.saleID
	join inv.barcodes b on b.barcodeID=sg.barcodeID
	join inv.styles st on st.styleID = b.styleID
	join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID	
	join inv.transactions t on t.transactionID=s.saleID
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
where closedTime is null
go
select transId, ttype, person, barcode, invType, amount from acc.CardSaleReceipts_v


