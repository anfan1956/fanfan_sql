
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
			@register_debet int, @register_credit int, @transactionid int,@register_buble int, 
			@personid int, @contractorid int;
		declare 
			@account_debet_id int = (select a.accountid from acc.articles a where a.article=@article),
			@account_credit_id int = acc.account_id('Деньги'), 
			@account_bubble_id int, 
			@person_id_debet int, @person_id_credit int;


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
					select @person_id_debet = personID from org.persons where lfmname = @payee;
				else if @article = 'ВОЗВРАТ С ПОДОТЧЕТА' 
					begin 
						select @account_bubble_id =@account_credit_id
						select @account_credit_id=@account_debet_id
						select @account_debet_id=@account_bubble_id
						select @register_buble=@register_credit
						select @register_credit=@register_debet
						select @register_debet=@register_buble
						select @person_id_credit = personID from org.persons where lfmname = @payee;
					end
				else 
					select @contractorid = org.contractor_id(@payee);

		--		table 1: acc.transactions
				with s (currencyid, clientid) as (
					select currencyid, clientid from acc.registers where account = @account
				)		
				insert acc.transactions(transdate, bookkeeperid, currencyid, articleid, clientid, amount, document )
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
					select 'True', @account_credit_id, @person_id_credit, null, @register_credit
						union
					select 'False', @account_debet_id, @person_id_debet, @contractorid, @register_debet
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

--declare @note varchar(max); exec acc.payment_record_p @note output, '20221202', '40817810900014646072', 'ПИКУЛЕВА О. Н.', 'ВОЗВРАТ С ПОДОТЧЕТА', 'ФЕДОРОВ А. Н.', 'без комментария', '65405'; select @note;

if OBJECT_ID('acc.payments_date_f') is not null drop function  acc.payments_date_f
go 
create function acc.payments_date_f(@date date) returns table as return

with s (id, дата, плательщик, статья, [план счетов], получатель, документ, банк, [счет/банк], валюта, сумма, оператор) as (

select 
	t.transactionid, 
	t.transdate,
	c2.contractor, 
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

declare @date date = '2022-12-02'
--select * from acc.entries
select * from acc.payments_date_f(@date)
select * from acc.transactions order by 1 desc;
--select * from acc.beg_entries_v

