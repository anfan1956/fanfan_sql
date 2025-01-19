if OBJECT_ID ('acc.SalesFiscalThisMonth_') is not null drop function acc.SalesFiscalThisMonth_
go
create function acc.SalesFiscalThisMonth_(@division varchar(255)) returns money as 
begin 
	declare @sales money;
	select @sales  = sum(sr.amount) 
	from inv.sales s 
		join inv.sales_receipts sr on sr.saleID = s.saleID
		join inv.transactions t on t.transactionID= s.saleID
	where 1 = 1
		and s.divisionID = org.division_id(@division)
		and MONTH(t.transactiondate) = MONTH(GETDATE())
		and YEAR(t.transactiondate)= YEAR (GETDATE())
		and receiptid is not null
	group by s.divisionID
	return @sales
end 


go
declare @division varchar(255)='05 Уикенд'


select acc.SalesFiscalThisMonth_(@division)