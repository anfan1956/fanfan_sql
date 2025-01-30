select * from acc.CardRedirectLog
if not exists
	(select 1 
		from sys.objects s 
		where object_id = object_id('acc.CardRedirectLog')
		)
	create table acc.CardRedirectLog (
		ID int not null identity Primary key, 
		logtTme smalldatetime default current_timestamp,
		transactionId int not null foreign key references inv.sales (saleid), 
		closedTime smalldatetime null, 
		receiptID int null, 
		fiscalId varchar(255) null
	)

if not exists (select 1
	from sys.columns c
	where 1=1
		and object_id = object_id('acc.CardRedirectLog')
		and c.name = 'redirectTo'
		)
alter table acc.CardRedirectLog
add  redirectTo int null foreign key references org.divisions (divisionID)




select c.*, s.divisionID, s.fiscal_id, sr.amount
	, sum (sr.amount) over(partition by divisionID)

from acc.CardRedirectLog c
	join inv.sales s on s.saleID=c.transactionId 
	join inv.sales_receipts sr on sr.saleID=s.saleID
order by 1 desc

