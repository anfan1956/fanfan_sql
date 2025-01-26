if OBJECT_ID ('acc.SalesFiscalThisMonth_') is not null drop function acc.SalesFiscalThisMonth_
go
create function acc.SalesFiscalThisMonth_(@division varchar(255)) returns money as 
begin 
	declare @sales money;

with ref as (
	select s.saleID 
	from acc.CardRedirectLog l 
		join inv.sales s on s.saleID=l.transactionId
	where s.divisionID = org.division_id(@division)
)
	select @sales  = sum(sr.amount) 
from inv.sales s 
	join inv.sales_receipts sr on sr.saleID = s.saleID
	join inv.transactions t on t.transactionID= s.saleID
where 1 = 1
	and s.divisionID = org.division_id(@division)
	and MONTH(t.transactiondate) = MONTH(GETDATE())
	and YEAR(t.transactiondate)= YEAR (GETDATE())
	and isnull(receiptid, 0) <> 0
	and s.saleID not in (select saleID from ref)
		
	return @sales
end 


go
declare @division varchar(255)='05 Уикенд'


select acc.SalesFiscalThisMonth_(@division)