use fanfan
go

if OBJECT_ID ('acc.consignment_record') is not null drop proc acc.consignment_record
go

create proc acc.consignment_record  @date datetime
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction;

		declare @transactions table (transid int, clientid int, articleid int, pmtForm varchar(25));
--		Select @date startDate;

--		select *, 'checking' from  acc.salesConsignment_(@date);

		with _seed(articleid, amount, saleid, barcodeid, pmtForm)  as (
			select acc.article_id ('закупочная стоимость'), s.себ_ст, saleid, barcodeid, s.форма_опл
			from acc.salesConsignment_(@date) s
				union 
			select acc.article_id('доля в прибыли'), s.доля_пр, saleid, barcodeid, s.форма_опл
			from acc.salesConsignment_(@date) s
			)
		, s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, saleid, barcodeid, pmtForm) as (
			select
				t.transactiondate, org.user_id('interbot'), cmn.currency_id('RUR'),
				se.articleid, d.clientID, se.amount, d.divisionfullname, 
				se.saleid, se.barcodeid, se.pmtForm
			from _seed se 
				join inv.transactions t on t.transactionID=se.saleid
				join inv.sales s on s.saleID = se.saleid
				join org.divisions d on d.divisionID=s.divisionID
		)	
--select * from _seed;
		merge acc.transactions as t using s
		on  s.saleid = t.saleid and s.barcodeid= t.barcodeid and s.articleid=t.articleid
		when matched and t.amount<>s.amount or t.comment<>s.comment or t.document<>s.pmtForm
		then update set 
			t.amount =s.amount,
			t.comment=s.comment, 
			t.document = s.pmtForm
		when not matched then
			insert  (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, saleid, barcodeid, document)
			values (s.transdate, s.bookkeeperid, s.currencyid, s.articleid, s.clientid, s.amount, s.comment, s.saleid, s.barcodeid, s.pmtForm)
			output inserted.transactionid, inserted.clientid, inserted.articleid, s.pmtForm into @transactions;
;
--	select t.* from acc.transactions t join @transactions tr on tr.transid=t.transactionid;


		declare @entries table (entryid int);

		with _seed (is_credit, accountid, contractorid) as (
			select 'True', acc.account_id ('счета к оплате'), org.contractor_id('E&N suppliers') 
			union
			select 'false', null, null
		)
		, _entries (transactionid, is_credit, accountid, contractorid) as (
		select t.transid, s.is_credit, isnull(s.accountid, a.accountid), isnull(s.contractorid, t.clientid)
		from _seed s
			cross apply @transactions t 
			join acc.articles a on a.articleid=t.articleid
		)
		merge acc.entries as t using _entries s
		on t.transactionid = s.transactionid
		when not matched then 
		insert (transactionid, is_credit, accountid, contractorid)
		values(transactionid, is_credit, accountid, contractorid)
		output inserted.entryid into @entries;
		--select e.* from acc.entries e join @entries en on en.entryid=e.entryid


--;		throw 50001, @message, 1
	
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go

declare @date datetime = '20240101';
--exec acc.consignment_record @date 

--select * from acc.salesConsignment_(@date)
