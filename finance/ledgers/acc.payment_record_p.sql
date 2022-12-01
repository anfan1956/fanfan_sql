
if OBJECT_ID('acc.payment_record_p') is not null drop proc acc.payment_record_p
go
create proc acc.payment_record_p
	@note varchar(max) output,
	@date date,
	@account char(20), 
	@bookkеeper varchar(50),
	@article varchar (150), 
	@payee varchar (150),
	@comment varchar (max), 
	@amount money 
as
set nocount on;
begin try
	begin transaction;
		declare 
			@register_debet int, @register_credit int, @transactionid int, 
			@personid int, @contractorid int;

		if @payee = 'ОТСУТСТВУЕТ'
			begin 
				declare @registerid int = (select registerid from acc.registers where account = @account);
				
				with s (entrydate, registerid, amount) as (select @date, @registerid, @amount)
				merge acc.beg_entries as t using s
				on t.registerid = s.registerid and t.entrydate=s.entrydate
				when matched and t.amount<>s.amount 
					then update set t.amount = s.amount
				when not matched 
					then insert (entrydate, registerid, amount)
					values (entrydate, registerid, amount);
				if @@ROWCOUNT >0 select @note = 'начальный остаток регистра обновлен' else select @note = 'остаток регистра уже записан'
			end
		else
			begin
				if (select left(@payee, 14)) = 'номер регистра'
					select @register_debet = cast(replace (@payee, (left (@payee, 17)), '') as int);
				select @register_credit = registerid from acc.registers where account = @account;
		
				if @article = 'ВЫПЛАТЫ ПЕРСОНАЛУ' 
					select @personid = personID from org.persons where lfmname = @payee;
				else 
					select @contractorid = org.contractor_id(@payee);

		--		table 1: acc.transactions
				with s (currencyid, clientid) as (
					select currencyid, clientid from acc.registers where account = @account
				)		
				insert acc.transactions(transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment )
				select 
					@date, 
					org.person_id(@bookkеeper), 
					s.currencyid, 
					a.articleid, 
					s.clientid, 
					@amount, 
					@comment
				from acc.articles a
					cross apply s
				where a.article= @article;
		
				select @transactionid = SCOPE_IDENTITY();

		--		table 2: acc.entries
				with _seed (is_credit, accountid, personid, contractorid, registerid) as(
					select 'True', acc.account_id('Деньги'), null, null, @register_credit
						union
					select 'False', accountid, @personid, @contractorid, @register_debet
					from acc.articles a
					where a.article= @article
					)
				insert acc.entries(transactionid, is_credit, accountid, registerid, personid, contractorid)
				select @transactionid, s.is_credit, s.accountid,  s.registerid, s.personid, s.contractorid			
				from _seed s;


		
				select @note= 'получатель: ' + @payee + ', сумма: '  + FORMAT(@amount, '#,##0.00') + ' ' 
					+ (select c.currencycode  from acc.registers r join cmn.currencies c on 
					c.currencyID= r.currencyid where r.account= @account)
			end 
		--throw 50001, @note, 1
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
go

--declare @note varchar(max); exec acc.payment_record_p @note output, '20221129', '40817810900014646072', 'ФЕДОРОВ А. Н.', 'ОПЛАТА ПО СЧЕТУ', 'ДРИМ ХАУС. ЗАО', 'счет за май', '45245'; select @note;
--go
--declare @note varchar(max); exec acc.payment_record_p @note output, '20221128', '40817810900014646072', 'ФЕДОРОВ А. Н.', 'ВЫПЛАТЫ ПЕРСОНАЛУ', 'БАЛУШКИНА А. А.', 'перевод по карте', '10.258'; select @note;
--go
--declare @note varchar(max); exec acc.payment_record_p @note output, '20221128', '40817810900014646072', 'ФЕДОРОВ А. Н.', 'ВЫПЛАТЫ ПЕРСОНАЛУ', 'ГОРЛОВА А. Р.', 'перевод по карте', '5600'; select @note;
--declare @note varchar(max); exec acc.payment_record_p @note output, '20221201', '40817810900014646072', 'ФЕДОРОВ А. Н.', 'НАЧАЛЬНЫЕ ОСТАТКИ', 'ОТСУТСТВУЕТ', 'коррекция', '4561.23'; select @note;
declare @note varchar(max); exec acc.payment_record_p @note output, '20221201', '40817810900014646072', 'ФЕДОРОВ А. Н.', 'НАЧАЛЬНЫЕ ОСТАТКИ', 'ОТСУТСТВУЕТ', 'коррекция', '13289.25'; select @note;


if OBJECT_ID('acc.payments_date_f') is not null drop function  acc.payments_date_f
go 
create function acc.payments_date_f(@date date) returns table as return

with s (id, плательщик, статья, [план счетов], получатель, документ, банк, [счет/банк], валюта, сумма, оператор) as (

select 
	t.transactionid, c2.contractor, 
	a.article, ac.account, 
	isnull(c3.contractor, p.lfmname), 
	t.comment, c.contractor, 
	r.account, cr.currencycode, 
	t.amount, p2.lfmname
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

declare @date date = '2022-11-29'
--select * from acc.entries
select * from acc.payments_date_f(default)
select * from acc.transactions
select * from acc.beg_entries_v
