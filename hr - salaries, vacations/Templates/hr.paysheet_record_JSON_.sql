 if OBJECT_ID('hr.paysheet_record_JSON_') is not null drop proc hr.paysheet_record_JSON_
 go

create proc hr.paysheet_record_JSON_ @json varchar(max), @json2 varchar(max) as
begin try
	begin transaction
		set	nocount on;

		/*declarations*/
		declare @paysheet table (
			phone varchar(max), 
			lastname varchar(max), 
			firstname varchar(max), 
			middlename varchar(max), 
			amount varchar(max), 
			personid int
			)
		declare @header table (field varchar(max), value varchar(max));
		declare @output table (transactionid int, personid int);

		declare 
			@bankid int,
			@period varchar(max),
			@message varchar(max),
			@transdate date, 
			@bookkeeperid int, 
			@document varchar(max) , 
			@clientid int , --= org.client_id_clientRUS ('ИП ФЕДОРОВ'), 
			@currencyid int = cmn.currency_id('RUR'), 
			@articleid int =acc.article_id('Выплаты персоналу'), 
			@cash_accountid int = acc.account_id('деньги, касса'), 
			@ap_accountid int = acc.account_id('зарплата к оплате'); 
		
		declare @registerid int  ;

		/*extracting data from @json parameters into @tables*/
;		with s (phone, lastname, firstname, middlename, amount)  as 
		(select phone, lastname, firstname, middlename, amount 
			from OPENJSON(@json)
			with (
				phone varchar(max) '$.phone',
				lastname varchar(max) '$.lastname',
				firstname varchar(max) '$.firstname',
				middlename varchar(max) '$.middlename',
				amount varchar(max) '$.amount'
			) as jsonValue	
		)
		insert @paysheet (phone, lastname, firstname, middlename, amount, personid)
		select s.phone, s.lastname, s.firstname, s.middlename, amount, p.personID 
		from s
			join org.persons p on 
				p.lastname = s.lastname and
				p.firstname = s.firstname and 
				p.middlename = s.middlename
			join org.users u on u.userID = p.personID

;		with s (field, value)  as 
		(select field, value 
			from OPENJSON(@json2)
			with (
				field varchar(max) '$.field',
				value varchar(max) '$.value'
			) as jsonValue	
		)
		insert @header (field, value)
		select field, value from s;

		select @transdate = CONVERT(date, h.value, 104)
		from @header h 	where h.field='Дата платежа';

		select @document = h.value
		from @header h 	where h.field='Документ';		
--		select @document;

		select @clientid = c.contractorID
		from @header h 	
			join org.contractors c on c.contractor=h.value
		where h.field='Плательщик';		

		select @bankid = c.contractorID
		from @header h 	
			join org.contractors c on c.contractor=h.value
		where h.field='Банк';				

		select @registerid = (select r.registerid
			from acc.registers r
				join org.contractors c on c.contractorID=r.bankid
				join org.clients cl on cl.clientID=r.clientid
			where bankid = @bankid and r.clientid = @clientid)

		SET LANGUAGE Russian;
		select @period = case  datepart(dd, (CONVERT(date, h.value, 104)))  when  15 then 'аванс, '  else 'баланс, ' end +
			lower( format (CONVERT(date, h.value, 104), 'MMMM yyyy'))
		from @header h 	where h.field='Период';
		SET LANGUAGE us_english;

		select @bookkeeperid = p.personID
		from @header h
			join org.persons p on p.lfmname=h.value
		where h.field='Оператор'
		

		--this merge statement i would have never come up with without chatGPT. Incredible!
		MERGE INTO acc.transactions AS target
		USING (SELECT * FROM @paysheet) AS source
		ON 1 = 0 -- Always false to ensure an insert
		WHEN NOT MATCHED THEN
			INSERT (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
			VALUES (@transdate, CURRENT_TIMESTAMP, @bookkeeperid, @currencyid, 
				acc.article_id('Выплаты персоналу'), @clientid, source.amount, 
				/*
				source.lastname + ', ' + 
				*/
				@period, 
				@document)
		OUTPUT inserted.transactionid, source.personid INTO @output;
		--select * from acc.transactions t join @output o on o.transactionid=t.transactionid

;		with s (accountid, is_credit, registerid) as (
			select @cash_accountid, 'True', @registerid
			union all 
			select @ap_accountid, 'False', null
			)
		insert acc.entries (transactionid, is_credit, accountid, contractorid, personid, registerid)
		select 
			t.transactionid, 
			s.is_credit, 
			s.accountid, 
			null, 
			case is_credit when 'False' then o.personid end, 
			s.registerid
		from acc.transactions t 
			join @output o on o.transactionid=t.transactionid			
			cross apply s
		select @message = 'записана оплата для ' + cast( @@ROWCOUNT/2 as varchar(max)) + ' сотрудников'
		select @message  success for json path;				

--	; throw 500001, 'debuging', 1
		commit transaction
end try
begin catch
	rollback transaction
	select  ERROR_MESSAGE() error for json path
end catch
go
