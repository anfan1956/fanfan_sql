USE [fanfan]
GO

ALTER view inv.sales_rectypes_v as

with _sr (saleid, saledate, rtype, receipttype, amount) as (
	select 
		sr.saleID, 
		t.transactiondate date,
		r.r_type_rus, 
		r.receipttype, 		
		sum(sr.amount) * iif(t.transactiontypeID= inv.transactiontype_id('RETURN'), -1, 1)		 
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID= sr.saleID
		join fin.receipttypes r on r.receipttypeID= sr.receipttypeID

	group by 
		sr.saleID, 
		t.transactiondate , 
		r.r_type_rus, 
		r.receipttype,
		t.transactiontypeID		
) 
, f (
		saleid
		, fiscal_id
		, receiptid
		--, barcodeid
		, день, мес€ц, год, дата, магазин, покупатель, 
		продавец, телефон, сумма, форма_оплаты, saledate, rType
	) as (
select 
	s.saleID, 
	s.fiscal_id, 
	s.receiptid, 
	--sg.barcodeID,
	DATEPART(DD, sr.saledate), 
	DATEPART(MM, sr.saledate), 
	DATEPART(YYYY, sr.saledate), 
	EOMONTH(sr.saledate, 0),
	d.divisionfullname,
	isnull(p.lfmname, 'NA'), 
	u.lfmname,
	c.connect, 
	sr.amount, 
	sr.receipttype, 

	sr.saledate, 
	sr.rtype

from _sr sr
	join inv.sales s on s.saleID= sr.saleid
	--join inv.sales_goods sg on sg.saleID= s.saleID 
	join org.divisions d on d.divisionID=s.divisionID
	left join cust.persons p on p.personID= s.customerID
	join org.persons u on u.personID=s.salepersonID
	left join cust.connect c on c.personID=p.personID and c.connecttypeID =1 and c.prim= 'True'
)
select * from f
GO




select top 10 * from inv.sales_rectypes_v order by 1 desc
--exec inv.transaction_delete 87295
