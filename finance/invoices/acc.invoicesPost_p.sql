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
				@accountid int = (select  accountid from acc.accounts where account= @account_debet);
			with _s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment) as (
				select @date, org.person_id(@bookkeeper), cmn.currency_id(@currency), @articleid, org.contractor_id(@client), @amount, @comment
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment)
			select 
				transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment
			from _s;

			select @transactionid = SCOPE_IDENTITY();

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
--		throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go
declare @note varchar(max); 
	--exec acc.invoicesPost_p @note output, 'счета к оплате', 'аренда', '20221224', 'RUR', 'КРОКУС СИТИ МОЛЛ', 'АРЕНДА: СЧЕТА', 'да', '20221101', '20221205', 'одлоыв', 'за ноябрь', 'ИП ФЕДОРОВ', 'ФЕДОРОВ А. Н.', '124'; 
select @note;
select * from acc.invoices;