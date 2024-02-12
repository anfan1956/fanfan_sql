if OBJECT_ID('acc.payments_date_f') is not null drop function  acc.payments_date_f
go 
create function acc.payments_date_f(@date date) returns table as return

with s (id, reg_id, дата, плательщик, статья, [план счетов], получатель, комментарий, документ, банк, [счет/банк], валюта, сумма, оператор) as (

select 
	t.transactionid, 
	e.registerid,
	t.transdate,
	c2.contractor, 
	a.article, 
	ac.account, 
	isnull(c3.contractor, p.lfmname), 
	t.comment, 
	t.document,
	c.contractor, 
	r.account, 
	cr.currencycode, 
	t.amount, 
	p2.lfmname
from acc.transactions t
	join acc.entries e on e.transactionid =t.transactionid and e.is_credit = 'True'
	join acc.registers r on r.registerid= e.registerid
	join cmn.currencies cr on cr.currencyID= r.currencyid
	join org.contractors c on r.bankID=c.contractorID
	join org.contractors c2 on c2.contractorID= r.clientid
	join acc.articles a on a.articleid=t.articleid
	join acc.accounts ac on ac.accountid=a.accountid
	join acc.entries e2 on e2.transactionid =t.transactionid and e2.is_credit = 'False'
	left join org.contractors c3 on c3.contractorID=e2.contractorid
	left join org.persons p on p.personID = e2.personid
	join org.persons p2 on p2.personID= t.bookkeeperid
where cast(t.recorded as date) = isnull(@date, getdate())
) 
select * from s
go

select id, reg_id, дата, статья, [план счетов], получатель, документ, плательщик, банк, [счет/банк], валюта, сумма, оператор from acc.payments_date_f('20221207')
declare @date date = '2022-12-02'
--select * from acc.entries
select * from acc.payments_date_f(@date)
select * from acc.transactions order by 1 desc;
--select * from acc.beg_entries_v

--declare @note varchar(max); exec acc.payment_record_p @note output, '20221215', 'hc05УИКЕНД', 'ФЕДОРОВ А. Н.', 'ВЫДАЧА ПОД ОТЧЕТ', 'ФЕДОРОВ А. Н.', '', '', '23'; select @note;