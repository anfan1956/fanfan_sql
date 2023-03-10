use fanfan
go

if OBJECT_ID('cmn.split_ordered_recursiveCTE') is not null drop function cmn.split_ordered_recursiveCTE
go 
create function cmn.split_ordered_recursiveCTE 
	(
		@List      varchar(4000),
		@Delimiter char(1)
	)
returns table as return

	WITH a(f,t) AS  
		(
		  SELECT 1, CHARINDEX(@Delimiter, @List + @Delimiter)
		  UNION ALL
		  SELECT t + 1, CHARINDEX(@Delimiter, @List + @Delimiter, t + 1) 
		  FROM a  WHERE CHARINDEX(@Delimiter, @List + @Delimiter, t + 1) > 0
		)
		SELECT seq   = ROW_NUMBER() OVER (ORDER BY t), 
			   value = SUBSTRING(@List, f, t - f) FROM a

go

if OBJECT_ID('acc.account_for_account_p') is not null drop proc acc.account_for_account_p
go
create proc acc.account_for_account_p 
	@accountable varchar(max), 
	@note varchar(max) output
as
set nocount on;
begin transaction 
	begin try;
		declare @transid int;
		declare @data table (id int, myData varchar(max));
		insert @data (id, myData)
		select seq, value from cmn.split_ordered_recursiveCTE (@accountable, ',');
		
--		select 	id, d.myData from @data d

		declare 
			@date date = (select myData from @data where id = 1),
			@bookkeeper varchar(25) = (select myData from @data where id = 2),
			@person varchar(25) = (select myData from @data where id = 3), 
			@currency char(3) = (select myData from @data where id =4),
			@article varchar(150) = (select myData from @data where id = 5),
			@contractor varchar(50) = (select myData from @data where id = 6), 
			@document varchar(50) = (select myData from @data where id = 7), 
			@comment varchar(150) = (select myData from @data where id = 8),
			@amount money = (select myData from @data where id = 9);

		declare 
			@personid int = (select personID from org.persons p where p.lfmname = @person),
			@currencyid int = (select currencyID from cmn.currencies where currencycode= @currency),
			@contractorid int = (select contractorID from org.contractors where contractor = @contractor);

		with s(transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document) as (
			select @date, CURRENT_TIMESTAMP, personID, 643, a.articleid, 269, @amount, @comment, @document 
				from org.persons p 
					cross apply (select articleid from acc.articles where article = @article) a
				where p.lfmname=@bookkeeper	
		)
		insert acc.transactions (transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document)
		select transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document from s;
		select @transid = SCOPE_IDENTITY();
		--select * from acc.transactions t where t.transactionid = @transid;

		with _seed (is_credit, accountid  ) as (
			select 'True', acc.account_id('подотчет') 
			union all 
			select 'False', null
		)
		insert acc.entries(transactionid, is_credit, accountid, personid, contractorid)
		select 
			@transid, s.is_credit, 
			isnull(s.accountid, a.accountid), 
			case s.is_credit
				when 'True' then @personid end,
			case s.is_credit
				when 'False' then @contractorid end
		from acc.articles a 			
			cross apply _seed s
		where a.article= @article;
--		select * from acc.entries e where e.transactionid = @transid;

		select @note = 'success, transactionid: ' + cast(@transid as varchar(max));
--		throw 50001, @note, 1;
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch

go

declare @note varchar (max);
declare @accountable varchar(max) = '20230310,ПИКУЛЕВА О. Н.,ФЕДОРОВ А. Н.,RUR,КУРЬЕР,НЕТ/КА,бд,за перевозку джинсов из 08,650';
--select * from acc.transactions
--exec acc.account_for_account_p @accountable,  @note output; select @note;
declare @transid int = 2042; 
select * from acc.transactions t order by 1 desc;
--exec acc.payment_delete_p  @note output, @transid;
