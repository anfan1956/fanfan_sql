if OBJECT_ID('acc.payment_record_p') is not null drop proc acc.payment_record_p
go
create proc acc.payment_record_p
	@note varchar(max) output,
	@date date,
	@account char(20), 
	@bookkеeper varchar(50),
	@article varchar (150), 
	@payee varchar (150),
	@document varchar(50),
	@comment varchar (150), 
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
				
				with s (entrydate, registerid, amount, bookkeeperid) as (
					select @date, @registerid, @amount, p.personID
					from org.persons p 
					where p.lfmname = @bookkеeper
				)
				merge acc.beg_entries as t using s
				on t.registerid = s.registerid and t.entrydate=s.entrydate
				when matched and t.amount<>s.amount 
					then update set 
						t.amount = s.amount, 
						t.bookkeeperid = s.bookkeeperid
				when not matched 
					then insert (entrydate, registerid, amount, bookkeeperid)
					values (entrydate, registerid, amount, bookkeeperid);
				if @@ROWCOUNT >0 select @note = 'начальный остаток регистра обновлен' else select @note = 'остаток регистра уже записан'
			end
		else
			begin
				if (select left(@payee, 14)) = 'номер регистра'
					select @register_debet = cast(replace (@payee, (left (@payee, 17)), '') as int);
				select @register_credit = registerid from acc.registers where account = @account;
		
				if @article in ('ВЫПЛАТЫ ПЕРСОНАЛУ', 'ВЫДАЧА ПОД ОТЧЕТ') 
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
				--else if @article = 'ВЫДАЧА ПОД ОТЧЕТ'
				--	select @person_id_debet = personID from org.persons where lfmname = @payee;
				else 
					select @contractorid = org.contractor_id(@payee);

		--		table 1: acc.transactions
				with s (currencyid, clientid) as (
					select currencyid, clientid from acc.registers where account = @account
				)		
				insert acc.transactions(transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document )
				select 
					@date, 
					org.person_id(@bookkеeper), 
					s.currencyid, 
					a.articleid, 
					s.clientid, 
					iif(@amount<0, -@amount, @amount),
					@comment, 
					@document
					--case when @article <> 'ВЫПЛАТЫ ПЕРСОНАЛУ' then @comment end, 
					--case when @article = 'ВЫПЛАТЫ ПЕРСОНАЛУ' then @comment end
				from acc.articles a
					cross apply s
				where a.article= @article;
				
						
				select @transactionid = SCOPE_IDENTITY();

		--		table 2: acc.entries
				with _seed (is_credit, accountid, personid, contractorid, registerid) as(
					select 1, @account_credit_id, @person_id_credit, null, @register_credit
						union
					select 0, @account_debet_id, @person_id_debet, @contractorid, @register_debet
					from acc.articles a
					where a.article= @article
					)
				insert acc.entries(transactionid, is_credit, accountid, registerid, personid, contractorid)
				select 
					@transactionid, 
					case 
						when @amount>0 then s.is_credit
						else 1-s.is_credit end is_credit, 
					s.accountid, s.registerid, s.personid, s.contractorid
				from _seed s
--				join acc.accounts a on a.accountid=s.accountid
				;

		
				select @note= 
					case 
						when @amount>0 then 'получатель: ' 
						else 'плательщик: ' end 
					+ @payee + ', сумма: '  + FORMAT(abs(@amount), '#,##0.00') + ' ' 
					+ (select c.currencycode  from acc.registers r join cmn.currencies c on 
					c.currencyID= r.currencyid where r.account= @account)
			end 
--		;throw 50001, @note, 1
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
declare @transid int = 7858
--declare @note varchar(max); exec acc.payment_record_p @note output, '20240212', 'hc05УИКЕНД', 'ЛАЗАРЕВА Н. В.', 'РАСЧЕТЫ ПО КОНСИГНАЦИИ', 'E&N suppliers', 'cash', '05 УИКЕНД', '-80800'; select @note;
--exec acc.payment_delete_p @transid
select * from acc.transactions t order by 1 desc

--exec acc.transactionsWithSaleid_delete 81183