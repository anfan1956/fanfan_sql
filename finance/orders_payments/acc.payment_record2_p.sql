if OBJECT_ID('acc.payment_record2_p') is not null drop proc acc.payment_record2_p
go
create proc acc.payment_record2_p
	@note varchar(max) output, 
	@invoices dbo.id_money_type readonly, 
	@date date,
	@payer varchar(50), 
	@bank varchar (50), 
	@bank_account varchar (20),
	@document varchar (50), 
	@comment varchar(150), 
	@employee varchar (50)
as
set nocount on;
	begin try
		begin transaction;
			declare 
				@bookkeeperid int = (select personid from org.persons where lfmname = @employee), 
				@vendorid int =(select distinct vendorid from @invoices i join acc.invoices iv on iv.invoiceid= i.id), 
				@currency char(3) = (select distinct c.currencycode from cmn.currencies c join acc.invoices iv on iv.currencyid=c.currencyID
					join @invoices i on i.id= iv.invoiceid);

			declare @transactionid int;

			with s (date, bookeeperid, currencyid, articleid, clientid, amount, comment, document) as (
				select 
					@date,
					@bookkeeperid, iv.currencyid, 
					acc.article_id('ОПЛАТА ИНВОЙСОВ'), 
					org.contractor_id(@payer),
					sum(i.amount), 
					@comment, 
					@document
				from @invoices i
					join acc.invoices iv on iv.invoiceid= i.id
				group by iv.currencyid
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
			select s.date, s.bookeeperid, currencyid, articleid, clientid, amount, comment, document from s;
			select @transactionid = SCOPE_IDENTITY();
--			select * from acc.transactions where transactionid =  @transactionid;
			
			with _seed (is_credit, accountid) as (
				select 'true', acc.account_id('деньги') union all
				select 'false', a.accountid
					from acc.articles a where a.article = 'оплата инвойсов'
			)
			insert acc.entries (transactionid, is_credit, accountid, registerid, contractorid) 
			select @transactionid, s.is_credit, s.accountid,
				case s.is_credit
					when 'True' then r.registerid end registerid, 
				case s.is_credit  
					when 'false' then @vendorid end contractorid
			from acc.registers r 
				cross apply _seed s
			where r.account = @bank_account;
--			select * from acc.entries where transactionid = @transactionid;

			with s (invoiceid, paymentid, amount) as (
				select i.id, @transactionid, i.amount from @invoices i
			)
			insert acc.invoices_payments(invoiceid, paymentid, amount)
			select invoiceid, paymentid, amount from s;
--			select * from acc.invoices_payments where paymentid = @transactionid;

			select @note = 
					'записан платеж №' + format(@transactionid, '#') + ' от "' + @payer +
					'" в оплату инвойсов ' + STRING_AGG(id,',' ) + 
					' на общую сумму ' + format (sum(i.amount), '#,##0.00 ') + @currency
			FROM @invoices i;

---			throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare  @note varchar(max), @invoices dbo.id_money_type; insert @invoices (id, amount) values (1291, 1213), (1292, 12.23); 
--exec acc.payment_record2_p @note output, @invoices, '20221225', 'ИП Федоров', 'ТИНЬКОФФ', '40802810700002267131', 'no', 'частичная оплата', 'ПИКУЛЕВА О. Н.'; select @note;
;
select * from acc.invoices_payments