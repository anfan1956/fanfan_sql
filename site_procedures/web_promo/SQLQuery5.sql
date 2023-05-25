use fanfan
go

declare @brandid int = 303, @saleid int= 76969
select 

t.transactiondate, s.* , p.lfmname, sr.amount, transactiontype, sg.barcodeID

from inv.sales s 
	join org.persons p on p.personID=s.salepersonID
	join inv.sales_receipts sr on sr.saleID=s.saleID
	join inv.sales_goods sg on sg.saleID=s.saleID
	join inv.transactions t on t.transactionID=s.saleID
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	--join inv.sales_goods sg on sg.saleID=s.saleID

where 
	--s.divisionID=18
	--and 
	s.saleID >= @saleid-5
order by 2 desc

--exec inv.transaction_delete @saleid 

set nocount on;                                          
--update s set s.receiptid = 35, s.fiscal_id = '1157768464' from inv.sales s where s.saleID=76958;
select @@ROWCOUNT;
