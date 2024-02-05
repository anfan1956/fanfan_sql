if OBJECT_ID('acc.invoicesStatus_') is not null drop function acc.invoicesStatus_
go
create function acc.invoicesStatus_(@vendorid int, @open bit) returns table as return 

	select 
		a.invoiceid, 
		documentNum doc, 
		cr.currencycode currency,
		format(datedue, 'dd.MM.yyyy') datedue, 
		format(periodDate, 'yyyy MMM') [period], 
		t.comment, 
		t.amount, 
		isnull(p.payments, 0) paid, 
		t.transdate 
	from acc.invoices a
		join acc.transactions t on t.transactionid=a.invoiceid
		join org.contractors c on c.contractorID=a.vendorid
		join cmn.currencies cr on cr.currencyID=a.currencyid
		left join (select invoiceid, sum (amount) payments from acc.invoices_payments group by invoiceid) as p on p.invoiceid=a.invoiceid
	where 
		vendorid=@vendorid and t.amount <>case @open when 0 then isnull(p.payments, 0)
		else 0 end
go

declare @vendorid int = 364, @open bit = 'True'
select * from acc.invoicesStatus_(@vendorid, @open) order by transdate desc
select  invoiceid, doc, currency, datedue, period, comment, amount, paid from acc.invoicesStatus_(364, 'True' ) 
order by transdate desc

declare @note varchar(max);
--exec acc.payment_delete_p @note output, 5982; select @note
select  invoiceid, doc, currency, datedue, period, comment, amount, paid from acc.invoicesStatus_(364, 'True' ) order by transdate desc

