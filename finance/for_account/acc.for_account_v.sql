use fanfan
go

if OBJECT_ID('acc.for_account_v') is not null drop view acc.for_account_v
go
create view acc.for_account_v as
	with s (дата, год, месяц, отчетное_лицо, статья, id, reg_id, регистр, банк, сумма, комментарий, документ) as (
		select 
			cast(t.transdate as datetime), 
			DATEPART(YYYY, t.transdate),
			DATEPART(MM, t.transdate),
			p.lfmname, ar.article,
			t.transactionid, 
			cor.registerid, 
			iif(substring(r.account, 2,1) LIKE ('c'), 
				substring(r.account, 3,2) + ' ' + right(r.account, len(r.account) -4), 
				r.account)		
			, 
			c.contractor bank,
			t.amount * (1- 2 * e.is_credit) amount, t.comment, t.document
			--, sum (t.amount * (1- 2 * e.is_credit)) over (partition by e.personid order by t.transdate, t.transactionid)  rt

		from acc.entries e 
			join acc.entries cor on cor.transactionid=e.transactionid and e.is_credit<>cor.is_credit
			join acc.transactions t on t.transactionid=e.transactionid
			join org.persons p on p.personID = e.personid
			join acc.accounts a on a.accountid= e.accountid
			join acc.articles ar on ar.articleid=t.articleid
			left join acc.registers r on r.registerid = cor.registerid
			left join org.contractors c on c.contractorID=r.bankid
		where e.accountid= acc.account_id('подотчет')
	)
	select * from s;
go

select * from acc.for_account_v order by id desc

