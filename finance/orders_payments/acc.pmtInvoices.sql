if OBJECT_ID('acc.pmtInvoices') is not null drop proc acc.pmtInvoices
go
create proc acc.pmtInvoices @info varchar(max), @inv  dbo.id_money_type readonly as
set nocount on;

begin try
	begin transaction
		declare @table table (transdate datetime, pmtType varchar(max), client varchar(max), payer varchar(max),
			bank varchar(max),contractor varchar(max),amount varchar(max), comment varchar(max),bookkeeper varchar(max));

		declare 
			@transid int, 
			@pmtType varchar(max),
			@regid int, 
			@accountid int, 
			@document varchar(max), 
			@article varchar(max), 
			@contractorid int, 
			@personid int, 
			@start datetime;
		select @document = 'invoce payment'
		select @article = 'ОПЛАТА ИНВОЙСОВ';
		select @start = getdate();

		with s (value, rn) as (
			SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
			FROM STRING_SPLIT(@info, ',')
		)
		insert @table (transdate, pmtType, client, payer, bank, contractor, amount, comment, bookkeeper)
		select 
			(select convert(DATE, value, 104) from s where s.rn =1) as date, 
			(select value from s where s.rn =2) as pmtType, 
			(select value from s where s.rn =3) as client, 
			(select value from s where s.rn =4) as payer, 
			(select value from s where s.rn =5) as bank, 
			(select value from s where s.rn =6) as contractor,  
			(select cast(value as money) from s where s.rn =7) as amount,
			(select value from s where s.rn =8) as comment, 
			(select value from s where s.rn =9) as bookkeeper ;
--select * from @table;
--select * from @inv;
		declare @ratedate date;
		select @contractorid = c.contractorID from @table t join org.contractors c on c.contractor=t.contractor
		select @pmtType= t.pmtType from @table t
		select @ratedate = t.transdate from @table t
;		
		with s as (select  c.contractorID bankid, isnull(cl.clientID, c2.contractorID) clientid, 643 currencyid
		from @table t
			join org.contractors c on c.contractor=t.bank
			left join org.clients cl on cl.clientRus=t.payer
			left join org.contractors c2 on c2.contractor = t.payer
			)
		select 
			@regid = registerid from acc.registers r 
			join s on s.bankid=r.bankid 
				and s.clientid=r.clientid and 
				s.currencyid= r.currencyid		
--select @regid regid

		if @pmtType= 'подотчет' 
			begin
				select @personid = personid from org.persons p join @table t on t.payer=p.lfmname
				select @regid = null
--select @personid, @regid;
			end

		insert acc.transactions (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select 
			t.transdate, CURRENT_TIMESTAMP, personID, 643, acc.article_id(@article), clientID, t.amount, 
			t.pmtType + ': ' + t.comment ,  @document
		from @table t
			join org.persons p on p.lfmname=bookkeeper
			join org.clients cl on cl.clientRus=t.client
		select @transid = SCOPE_IDENTITY();
--select * from acc.transactions t where t.transactionid=@transid;

		select @accountid = case  t.pmtType 
				when 'денежный' then acc.account_id('деньги, касса')
				else acc.account_id('подотчет') end
		from @table t;
--select @accountid accid;

		insert acc.invoices_payments(invoiceid, paymentid, amount)
			select i.id, @transid, i.amount/r.rate
			from @inv i
				join acc.invoices v on v.invoiceid=i.id
				join cmn.rateOnDate_(@ratedate) r on r.currencyid=v.currencyid
--select * from acc.invoices_payments p where p.paymentid=@transid
;
		with s (transactionid, is_credit, accountid, contractorid, personid, registerid
			) as (
			select @transid, 1, @accountid, null, @personid, @regid
			union all 
			select @transid, 0, acc.account_id('счета к оплате'), @contractorid, null, null
			from @table t				
		)
		insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
		select transactionid, is_credit, accountid, contractorid, personid, registerid from s;
--select * from acc.entries e where e.transactionid =@transid
--select DATEDIFF(ms, @start, getdate()) ms

		select 1 result, 'recorded transid: ' +  cast (@transid as varchar(max))  msg

--		;throw 50001, 'debug', 1
	commit transaction
end try
begin catch
	select -1 error, ERROR_MESSAGE() msg;
	rollback transaction
end catch
go




set nocount on; declare @info varchar(max)= '20231222,денежный,ПРОЕКТ Ф,Федоров А. Н.,ТИНЬКОФФ,ДРИМ ХАУС. ЗАО,70000,Част оплата,Федоров А. Н.', 
	@inv dbo.id_money_type; 
	insert @inv values (5662, 70000); 
--exec acc.pmtInvoices @info = @info, @inv = @inv;