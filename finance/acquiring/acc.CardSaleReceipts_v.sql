/*
	python "Z:\Управление предприятием\accounting\Prop_soft\sale_fiscal.py" "ФЕДОРОВ А. Н." 84848 "'663892','ДЖИНСЫ',30600;'663894','ДЖИНСЫ',30600" 0 "sale"
	python "Z:\Управление предприятием\accounting\Prop_soft\sale_fiscal.py" "ФЕДОРОВ А. Н." 84862 "'663892','ДЖИНСЫ','40800';'663894','ДЖИНСЫ','40800'" 0 "SALE"

*/

if OBJECT_ID ('acc.CardSaleReceipts_v') is not null drop view acc.CardSaleReceipts_v
go 
create view acc.CardSaleReceipts_v as
select 
	LOWER( tt.transactiontype)			as ttype
	, l.transactionId					as transId
	, t.transactiondate					as saleDate
	, p.lfmname							as person
	, rt.r_type_rus						as recType
	, sg.barcodeID						as barcode
	, it.inventorytyperus				as invType
	, sg.amount 
from acc.CardRedirectLog l
	join inv.sales s					on s.saleID = l.transactionId
	join org.persons p					on p.personID =s.salepersonID
	join inv.sales_goods sg				on sg.saleID=s.saleID
	join inv.barcodes b					on b.barcodeID=sg.barcodeID
	join inv.styles st					on st.styleID = b.styleID
	join inv.inventorytypes it			on it.inventorytypeID=st.inventorytypeID	
	join inv.transactions t				on t.transactionID=s.saleID
	join inv.transactiontypes tt		on tt.transactiontypeID=t.transactiontypeID
	join inv.sales_receipts sr			on sr.saleID=s.saleID
	join fin.receipttypes rt			on rt.receipttypeID=sr.receipttypeID
where closedTime is null
go

select transId, saleDate, ttype, recType, person, barcode, invType, amount, sum (amount) over()
from acc.CardSaleReceipts_v 
	order by 1 desc
select * from acc.CardRedirectLog l 
order by closedTime desc
