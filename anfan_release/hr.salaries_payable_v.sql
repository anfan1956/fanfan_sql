use	anfan_release
go

USE [anfan_release]
GO

/****** Object:  View [hr].[salaries_payable_v]    Script Date: 29.08.2022 02:13:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [hr].[salaries_payable_v] as
	with _startdate (startdate) as (select '20210416')	
	, s (сотрудник, [форма оплаты]/*, работодатель*/, [дата зачисления], операция, сумма/*, id*/) as (
		select 
			c.contractor, 
			isnull(ps.split, iif(g.journalid = acc.journalid_func('hard cash'), 'cash', null)),
--			cl.client, 
			dbo.justdate(t.transactiondate), 
			td.details, 
			sum (g.amount* (2*g.is_credit-1))
--			g.transactionid
		from acc.generalledger g
			join acc.fin_transactions t on t.transactionid=g.transactionid
			join org.contractors c on c.contractorid=g.contractorid
			join acc.transactiondetails td on td.detailsid=t.detailsid
			left join acc.payroll_split ps on isnull(ps.splitid, 0)=isnull(t.splitid, 0)
			join org.clients cl on cl.clientid=t.clientid
			join _startdate sd on t.transactiondate> sd.startdate
		where g.accountid=acc.accountid_func('зарплата к оплате', 'RUR')
		group by c.contractor, ps.split, g.journalid, dbo.justdate(t.transactiondate), td.details
		)
	select * from s;
;
GO



select [сотрудник], [форма оплаты], [работодатель], [дата зачисления], [операция], [сумма], [id] from hr.salaries_payable_v 