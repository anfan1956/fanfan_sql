use fanfan
go


if OBJECT_ID('acc.invoicesPost_p') is not null drop proc acc.invoicesPost_p
go 

create proc acc.invoicesPost_p 
	@note varchar(max) output, 
	@date date, 
	@currency char(3), 
	@vendor varchar(50),
	@article varchar (150), 
	@comment varchar (150), 
	@document varchar (50), 
	@client varchar (50), 
	@bookkeeper varchar (50), 
	@amount money
as
set nocount on;
	begin try
		begin transaction
			declare 
				@transactionid int, @articleid int = (select articleid from acc.articles where article= @article),
				@accountid int = (select  accountid from acc.articles where article= @article);
			with _s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment) as (
				select @date, org.person_id(@bookkeeper), cmn.currency_id(@currency), @articleid, org.contractor_id(@client), @amount, @comment
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment)
			select 
				transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment
			from _s;

			select @transactionid = SCOPE_IDENTITY();

		with _seed(is_credit, accountid, contractorid) as (
			select 'True', acc.account_id('счета к оплате'), org.contractor_id(@vendor)
			union
			select 'False', @accountid, org.contractor_id(@vendor)
		)
		insert acc.entries (transactionid, is_credit, accountid, contractorid)
		select @transactionid, is_credit, accountid, contractorid
		from _seed;

		insert acc.invoices (invoiceid, documentNum, vendorid, currencyid)
		select @transactionid, @document, org.contractor_id(@vendor), cmn.currency_id(@currency);
--		select * from acc.invoices;
		

		select @note = 'инвойс № ' + @document + ' ' + ' от ' + @vendor + ' на сумму ' 
			+ format (@amount, '#,##0.00') + ' '  + @currency + ' зарегистрирован';
		---throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go
