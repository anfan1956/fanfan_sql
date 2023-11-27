if OBJECT_ID('acc.pmtInPeriod') is not null drop function acc.pmtInPeriod
go
create function acc.pmtInPeriod (@period char(2), @num int ) returns table as return
	select 
		t.transactionid TRANSID, 
		cast(t.transdate as datetime) ДАТА, 
		isnull(clt.clientRus, 'ИП ФЕДОРОВ') [Юр. лицо], 
		a.article СТАТЬЯ, 
		isnull(c.contractor, p2.lfmname) К_АГЕНТ, 
		isnull(isnull(cn.contractor, cl.clientRus), p2.lfmname) ПЛАТЕЛЬЩИК, 
		t.amount СУММА, 
		ac.account ДЕБЕТ, 
		ac2.account КРЕДИТ, 
		t.document ДОКУМЕНТ, 
		p.lfmname ОПЕРАТОР, 
		con.contractor БАНК_КАССА, 
		org.shopSplit( r.account)  register,
		t.comment

	from acc.transactions t
		join acc.entries e on e.transactionid=t.transactionid and e.is_credit='False'
		join acc.entries e2 on e2.transactionid=t.transactionid and e2.is_credit='True'
		join org.persons p on p.personID = t.bookkeeperid
		join acc.articles a on a.articleid=t.articleid
		left join org.contractors c on c.contractorID=e.contractorid
		left join acc.accounts ac on ac.accountid=e.accountid
		join acc.accounts ac2 on ac2.accountid=e2.accountid
		left join org.clients clt on clt.clientID=t.clientid 
		left join acc.registers r on r.registerid=isnull(e2.registerid, e.registerid)
		left join org.contractors cn on cn.contractorID=r.clientid
		left join org.clients cl on cl.clientID=r.clientid
		left join org.contractors con on con.contractorID=r.bankid
		left join org.persons p2 on p2.personid = isnull(e2.personid, e.personid)
		
	
	where cast(
		case @num 
			when 0 then t.recorded 
			else t.transdate
			end
		as date) between 
	Case @period 
		when 'DD' then
			dateadd(DD, -@num,   cast (getdate() as date)) 
		when 'MM' then 
			dateadd(MM, -@num,   cast (getdate() as date)) 
		end
	and cast (getdate() as date)
go

declare @note varchar(max);
select  * from acc.pmtInPeriod('MM', 1) order by 1 desc
select * 
from acc.transactions t
	join acc.entries e on e.transactionid=t.transactionid
where t.transactionid = 5574