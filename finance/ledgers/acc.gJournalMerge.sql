use fanfan
go

if OBJECT_ID ('acc.gJournalMerge') is not null drop proc acc.gJournalMerge
go

create proc acc.gJournalMerge  @json varchar (max), @entries varchar(max)
as 
set nocount on;
declare @message varchar (max)= 'Just debugging', @tranid int;
begin try

	declare @transaction table (
		transdate date, 
		recorded datetime,
		bookkeeperid int, 
		clientid int, 
		currencyid int, 
		articleid int, 
		amount money, 
		comment varchar(max), 
		document varchar(max))

	begin transaction;
		with s as (
		select * from OPENJSON (@json)	
		with (
			transdate date '$.date', 
			person varchar(max) '$.bookkeeper', 
			client varchar(max) '$.client', 
			currency varchar(max) '$.currency', 
			article varchar(max) '$.article', 
			amount money '$.amount', 
			comment varchar(max) '$.comment', 
			document varchar(max) '$.document'
		) 
		)
		insert @transaction  (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select
			s.transdate,
			CURRENT_TIMESTAMP , 
			p.personID, currencyID, articleid, clientid, s.amount, s.comment, s.document
		from s
			join org.persons p on p.lfmname = s.person
			join cmn.currencies cr on cr.currencycode=s.currency
			join acc.articles a on a.article = s.article
			join org.clients cl on cl.clientRus=s.client;

		insert acc.transactions (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document from @transaction
		select @tranid = SCOPE_IDENTITY();
--		select * from acc.transactions t where t.transactionid = @tranid;

		declare @s table (item varchar (max), is_credit bit, value varchar(max));
		WITH SourceData AS (
			SELECT item, debet, credit
			FROM OPENJSON(@entries)
			WITH (
				Item NVARCHAR(255) '$.item',
				Debet NVARCHAR(255) '$.debet',
				Credit NVARCHAR(255) '$.credit'
			)
		),
		UnpivotedData AS (
			SELECT item, entry, value
			FROM SourceData
			UNPIVOT (
				value FOR entry IN (debet, credit)
			) AS up
			WHERE value <> '' -- Filter out empty strings
		)
		, s as (
		SELECT item, 
			   CASE 
				   WHEN entry = 'debet' THEN 'False'
				   WHEN entry = 'credit' THEN 'True'
			   END AS is_credit, 
			   value
		FROM UnpivotedData)
		insert @s select * from s;
--select * from @s;

		declare @seed table (is_credit bit, accid int, perid int, bankid int)
		declare 
			@accCredit int = (select a.accountid from @s s join acc.accounts a on a.account=s.value cross apply @transaction t 		
				where item = 'account' and is_credit='True' and a.currencyid =t.currencyid), 				
			@accDebet int = (select a.accountid from @s s join acc.accounts a on a.account=s.value cross apply @transaction t 		
				where item = 'account' and is_credit='False' and a.currencyid =t.currencyid), 
			@contrCredit int =(select  c.contractorID from @s s join org.contractors c on c.contractor =s.value where s.item = 'contractor' and is_credit ='True') , 
			@contrDebet int =(select  c.contractorID from @s s join org.contractors c on c.contractor =s.value where s.item = 'contractor' and is_credit ='False'),
			@perCredit int  =(select  c.personid from @s s join org.persons c on c.lfmname =s.value where s.item = 'person' and is_credit ='True') ,
			@perDebet int  =(select  c.personid from @s s join org.persons c on c.lfmname =s.value where s.item = 'person' and is_credit ='False'),
			@bankCredit varchar(max)  =(select  s.value from @s s where s.item = 'bank' and is_credit ='True') ,
			@bankDebet varchar(max)  =(select  s.value from @s s where s.item = 'bank' and is_credit ='False') 
--	select @bankDebet  bd, @bankCredit bc;		

	declare @regidDebet int, @regidCredit int;
	declare @date date = (select t.transdate from @transaction t);
	if @bankDebet in (select a.division from  org.active_divisions_f(@date) a ) select @regidDebet=acc.shopRegister_byName_(@bankDebet)
	if @bankCredit in (select a.division from  org.active_divisions_f(@date) a ) select @regidCredit=acc.shopRegister_byName_(@bankCredit)

		;with _seed (is_credit, accountid, contractorid, personid, registerid) as (
			select 'True', @accCredit, @contrCredit, @perCredit, @regidCredit
			union
			select 'False', @accDebet, @contrDebet, @perDebet, @regidDebet
		)
		insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
		select @tranid,  s.*  
		from _seed s
			join acc.accounts a on a.accountid=s.accountid and a.currencyid=643;
--select * from acc.entries e where e.transactionid = @tranid;
		
		select @message = 'added transaction  ' + cast (@tranid as varchar(max));
		select @message msgOk

--		;throw 50001, @message, 1

	commit transaction
end try
begin catch
	select ERROR_MESSAGE() error
	rollback transaction
end catch
go
		

set nocount on; declare 
	@json varchar(max) = 
		'{"date":"20240309","bookkeeper":"Федоров А. Н.","client":"ИП ФЕДОРОВ","currency":"RUR","article":"РАСЧЕТЫ ПО КОНСИГНАЦИИ",
		"amount":"100000","comment":"взнос в кассу ","document":"бд","transid":""}', 
	@entries varchar(max) = 
		'[
			{"item":"account","debet":"деньги","credit":"счета к оплате"},
			{"item":"contractor","debet":"","credit":"E&N suppliers"},
			{"item":"person","debet":"","credit":""},
			{"item":"bank","debet":"05 УИКЕНД","credit":""}
		] '; 
--exec acc.gJournalMerge @json, @entries; 
select top 1 * from acc.transactions order by 1 desc


