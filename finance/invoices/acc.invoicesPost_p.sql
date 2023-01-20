use fanfan
go


if OBJECT_ID('acc.invoicesPost_p') is not null drop proc acc.invoicesPost_p
go 

create proc acc.invoicesPost_p 
	@note varchar(max) output, 
	@payable_account varchar (50),
	@account_debet varchar (50),
	@date date, 
	@currency char(3), 
	@vendor varchar(50),
	@article varchar (150), 
	@peirocic varchar(3), 
	@period date,
	@datedue char(8), 
	@document char(8), 
	@comment varchar (150), 
	@client varchar (50), 
	@bookkeeper varchar (50), 
	@amount money
as
set nocount on;
	begin try
		begin transaction
			

			declare 
				@transactionid int, 
				@articleid int = (select articleid from acc.articles where article= @article),
				@accountid int = (select  accountid from acc.accounts where account= @account_debet), 
				@payroll bit;

			if @payable_account = 'зарплата к оплате'
				select @payroll = 'True'
			else 
				select @payroll='False';


			with _s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document) as (
				select @date, org.person_id(@bookkeeper), cmn.currency_id(@currency), @articleid, org.contractor_id(@client), @amount, @comment, @document
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
			select 
				transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document
			from _s;

			select @transactionid = SCOPE_IDENTITY();

		if @payroll = 'False'
			begin
				with _seed(is_credit, accountid, contractorid) as (
					select 'True', acc.account_id(@payable_account), org.contractor_id(@vendor)
					union
					select 'False', @accountid, org.contractor_id(@vendor)
				)
				insert acc.entries (transactionid, is_credit, accountid, contractorid)
				select @transactionid, is_credit, accountid, contractorid
				from _seed;

			
				insert acc.invoices (invoiceid, documentNum, vendorid, currencyid, datedue, periodDate)
				select 
					@transactionid, 
					@document, 
					org.contractor_id(@vendor), 
					cmn.currency_id(@currency), 
					iif(@datedue= '', null, @datedue), 
					iif(@period= '', null, eomonth(@period, 0)) 
					;

				select @note = 'инвойс № ' + @document  + ' от ' + @vendor + ' на сумму ' 
					+ format (@amount, '#,##0.00') + ' '  + @currency + ' зарегистрирован';
			end

		if @payroll = 'True'
			begin
				with _seed(is_credit, accountid, personid) as (
					select 'True', acc.account_id(@payable_account), org.person_id(@vendor)
					union
					select 'False', @accountid, org.person_id(@vendor)
				)
				insert acc.entries (transactionid, is_credit, accountid, personid)
				select @transactionid, is_credit, accountid, personid
				from _seed;				
					select @note = 'начисление: ' + @document  + ' сотрудник: ' + @vendor + ' на сумму ' 
						+ format (@amount, '#,##0.00') + ' '  + @currency + ' сделано ' + format(@date, 'dd.MM.yyyy', 'ru');
			end

--		throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go
declare @note varchar(max); 
/*
exec acc.invoicesPost_p 
	@note output, 
	'зарплата к оплате', 
	'зарплата', 
	'20221226', 
	'RUR', 
	'БЕЗЗУБЦЕВА Е. В.', 
	'НАЧИСЛЕНИЕ ОТПУСКНЫХ', 
	'', '', '', 
	'cash', 
	'тест', 
	'Проект Ф', 
	'ПИКУЛЕВА О. Н.', 
	'12222'; 
select @note;
*/
select t.*, e.*
from acc.transactions t
	join acc.entries e on e.transactionid = t.transactionid
order by 1 desc

--exec acc.payment_delete_p @note output, 1331

