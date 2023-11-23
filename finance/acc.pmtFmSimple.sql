if OBJECT_ID('acc.pmtFmSimple') is not null drop proc acc.pmtFmSimple
go
create proc acc.pmtFmSimple @info varchar(max) as
set nocount on;
begin try
	begin transaction
		declare @table table (
			transdate datetime,
			client varchar(max), 
			payer varchar(max),
			bank varchar(max),
			contractor varchar(max),
			article varchar(max),
			document varchar(max),
			amount varchar(max), 
			bookkeeper varchar(max)
			);
		declare @transid int, @regid int;


		with s (value, rn) as (
			SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
			FROM STRING_SPLIT(@info, ',')
		)
		insert @table (transdate, client, payer, bank, contractor, article, document, amount, bookkeeper)
		select 
			(select convert(DATE, value, 104) from s where s.rn =1) as date, 
			(select value from s where s.rn =2) as client, 
			(select value from s where s.rn =3) as payer, 
			(select value from s where s.rn =4) as bank, 
			(select value from s where s.rn =5) as contractor, 
			(select value from s where s.rn =6) as article, 
			(select value from s where s.rn =7) as document, 
			(select cast(value as money) from s where s.rn =8) as amount,
			(select value from s where s.rn =9) as bookkeeper ;
--		select * from @table;
		
		insert acc.transactions (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select 
			t.transdate, CURRENT_TIMESTAMP, personID, 643, a.articleid, clientID, t.amount, 'automated',  t.document
		from @table t
			join org.persons p on p.lfmname=bookkeeper
			join acc.articles a on a.article=t.article
			join org.clients cl on cl.clientRus=t.client
		select @transid = SCOPE_IDENTITY();
--		select * from acc.transactions t where t.transactionid=@transid;

		with s as (select  c.contractorID bankid, isnull(cl.clientID, c2.contractorID) clientid, 643 currencyid
		from @table t
			join org.contractors c on c.contractor=t.bank
			left join org.clients cl on cl.clientRus=t.payer
			left join org.contractors c2 on c2.contractor = t.payer
			)
		select @regid = registerid from acc.registers r 
		join s on s.bankid=r.bankid and s.clientid=r.clientid and s.currencyid= r.currencyid		
		

		;with _seed (is_credit, accountid, registerid ) as (
			select 1, acc.account_id('деньги, касса'), @regid
			union all 
			select 0, null, null
		)

		insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
		select 
			@transid , s.is_credit, isnull (s.accountid, a.accountid), 
			case 
				s.is_credit when 1 then null 
				else c.contractorID end contractorid, 
			null,
			case s.is_credit 
				when 1 then s.registerid 
				else null end registerid
		from @table t
			join acc.articles ar on ar.article=t.article
			join acc.accounts a on a.accountid=ar.accountid
			join org.contractors c on c.contractor= t.contractor
			cross apply _seed s;
		
--		select * from acc.entries e where e.transactionid =@transid;

		select 1 result, 'recorded transid: ' +  cast (@transid as varchar(max))  msg

--		;throw 50001, 'debug', 1
	commit transaction
end try
begin catch
	select 0 error, ERROR_MESSAGE() msg;
	rollback transaction
end catch
go







