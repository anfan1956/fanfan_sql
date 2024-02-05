if OBJECT_ID('acc.pmtFmSimple') is not null drop proc acc.pmtFmSimple
go
create proc acc.pmtFmSimple @info varchar(max) as
set nocount on;
begin try
	begin transaction
		declare @table table (
			transdate datetime,
			pmtType varchar(max), 
			client varchar(max), 
			payer varchar(max),
			bank varchar(max),
			contractor varchar(max),
			article varchar(max),
			document varchar(max),
			amount varchar(max), 
			comment varchar(max),
			bookkeeper varchar(max)
			);
		declare @transid int, @regid int, @accountid int;

		with s (value, rn) as (
			SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
			FROM STRING_SPLIT(@info, ',')
		)
		insert @table (transdate, pmtType, client, payer, bank, contractor, article, document, amount, comment, bookkeeper)
		select 
			(select convert(DATE, value, 104) from s where s.rn =1) as date, 
			(select value from s where s.rn =2) as pmtType, 
			(select value from s where s.rn =3) as client, 
			(select value from s where s.rn =4) as payer, 
			(select value from s where s.rn =5) as bank, 
			(select value from s where s.rn =6) as contractor, 
			(select value from s where s.rn =7) as article, 
			(select value from s where s.rn =8) as document, 
			(select cast(value as money) from s where s.rn =9) as amount,
			(select value from s where s.rn =10) as comment, 
			(select value from s where s.rn =11) as bookkeeper ;
--select * from @table;
		
		select @accountid = case  t.pmtType 
				when 'денежный' then acc.account_id('деньги, касса')
				else acc.account_id('подотчет') end
		from @table t;
--select @accountid accid;

		with s as (select  c.contractorID bankid, isnull(cl.clientID, c2.contractorID) clientid, 643 currencyid
		from @table t
			join org.contractors c on c.contractor=t.bank
			left join org.clients cl on cl.clientRus=t.payer
			left join org.contractors c2 on c2.contractor = t.payer
			)
		select @regid = registerid from acc.registers r 
		join s on s.bankid=r.bankid and s.clientid=r.clientid and s.currencyid= r.currencyid		
--select @regid regid

		insert acc.transactions (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select 
			t.transdate, CURRENT_TIMESTAMP, personID, 643, a.articleid, clientID, t.amount, 
			t.pmtType + ': ' + t.comment ,  t.document
		from @table t
			join org.persons p on p.lfmname=bookkeeper
			join acc.articles a on a.article=t.article
			join org.clients cl on cl.clientRus=t.client
		select @transid = SCOPE_IDENTITY();
--select * from acc.transactions t where t.transactionid=@transid;

		
		if (select article from @table) = 'ВЫПЛАТЫ ПЕРСОНАЛУ'
			begin
				with _seed (is_credit, accountid, registerid, personid) as (
					select 1, @accountid, @regid, 
						case 
							when @regid is null then p.personID end
					from @table t
						left join org.persons p on p.lfmname = t.payer
					union all
					select 0, acc.account_id('зарплата к оплате'), null, p.personID
					from @table t
						left join org.persons p on p.lfmname= t.contractor
				)				
				insert acc.entries(transactionid, is_credit, accountid, personid, registerid)
				select 
					@transid, s.is_credit, isnull(s.accountid, ar.accountid), 
					s.personid, s.registerid
					
				from @table t
					join acc.articles ar on ar.article=t.article						
					join org.persons p on p.lfmname=t.contractor						
				cross apply  _seed s
			end
		else
			begin
				;with _seed (is_credit, accountid, registerid, personid ) as (
					select 1, --is_credit
						case 
							when @regid is null or t.article='ВОЗВРАТ С ПОДОТЧЕТА'  then acc.account_id('подотчет')
							else acc.account_id('деньги, касса') end,													-- accountid
						case when t.article <> 'ВОЗВРАТ С ПОДОТЧЕТА' then @regid end,									-- registerid
						case when @regid is null or t.article= 'ВОЗВРАТ С ПОДОТЧЕТА' then org.person_id(t.payer) end	-- personid
					from @table t
					union all 
					select 
						0, 
						case when t.article='ВОЗВРАТ С ПОДОТЧЕТА' then acc.account_id('деньги, касса') end,
						case when t.article='ВОЗВРАТ С ПОДОТЧЕТА' then @regid end,
						null
					from  @table t
				)
				insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
				select 
					@transid , s.is_credit, isnull (s.accountid, a.accountid), 
					case 
						s.is_credit when 1 then null 
						else c.contractorID end contractorid, 
					s.personid,
					s.registerid 			
				from @table t
					join acc.articles ar on ar.article=t.article
					join acc.accounts a on a.accountid=ar.accountid
					join org.contractors c on c.contractor= t.contractor
					left join org.persons p on p.lfmname = t.payer
					cross apply _seed s;		
			end 
--select * from acc.entries e where e.transactionid =@transid;

		select 1 result, 'recorded transid: ' +  cast (@transid as varchar(max))  msg

--		;throw 50001, 'debug', 1
	commit transaction
end try
begin catch
	select -1 error, ERROR_MESSAGE() msg;
	rollback transaction
end catch
go

--exec acc.pmtFmSimple '12.12.2023,денежный,ИП ФЕДОРОВ,ИП ФЕДОРОВ,ТИНЬКОФФ,ШЕМЯКИНА Е. В.,ВЫПЛАТЫ ПЕРСОНАЛУ,bank,3226.5,Ком 147.40,ФЕДОРОВ А. Н.'
