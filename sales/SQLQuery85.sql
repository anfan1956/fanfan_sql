use fanfan
go

select t.*, tt.transactiontype 
from inv.transactions t 
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
order by 1 desc
select * from inv.inventory i where i.transactionID= 72253