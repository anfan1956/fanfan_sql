use fanfan
go

with s as (
select s.*, ROW_NUMBER() over(partition by s.saleid order by receipttypeid) num
from inv.sales_receipts s
)
select * from s where s.num>1 order by 1 desc;
go
if OBJECT_ID('inv.sales_payment_f') is not null drop function inv.sales_payment_f
go
create function inv.sales_payment_f (@saleid int) returns table as return
	with t as (select s.saleID, s.amount, 
			case when s.receipttypeid in (2, 5) then 'банковская карта' 
				else 'наличные' end оплата
		from inv.sales_receipts s
		where s.saleID=@saleid
	)
	select оплата = stuff(( select  ', ' + CONCAT(оплата, ': ', format (amount, '#,##0.00'))
	from t for xml path ('')), 1,1, '')
go
declare @saleid int = 71410
select * from inv.sales_payment_f (@saleid)
;