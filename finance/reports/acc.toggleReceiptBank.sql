use fanfan
go
declare @saleid int = 82469

if OBJECT_ID ('acc.toggleReceiptBank') is not null drop proc acc.toggleReceiptBank
go
create proc acc.toggleReceiptBank @saleid int, @userid  int as

begin try;
	set nocount on;
	begin transaction;
		declare @note varchar(max)
		if exists (select * from acc.transactions t where t.saleid =@saleid and articleid = acc.article_id ('ðàñ÷åòû ïî êîíñèãíàöèè'))
		begin 
			select @note = 'ïåðåâîä íà E&N suppliers óæå ñäåëàí';
			throw 50001, @note, 1;
		end ;


		with _saleAmt (amount, shop) as (
			select sum(amount),  d.divisionfullname
			from inv.sales_receipts sr
				join inv.sales s on s.saleID =sr.saleID
				join org.divisions d on d.divisionID=s.divisionID
			where s.saleID=@saleid
			group by d.divisionfullname
		)
		insert acc.transactions(transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid)
		select 
			GETDATE(), @userid, 643, 
			acc.article_id('ÐÀÑ×ÅÒÛ ÏÎ ÊÎÍÑÈÃÍÀÖÈÈ'), 
			org.client_id_byname('ÈÏ Ôåäîðîâ'), amount,
			s.shop + ' â ÅÀÔ ïî òåëåôîíó', 'cash', @saleid
		from _saleAmt s;
		declare @transid int = scope_identity();

		--select * from acc.transactions t where t.transactionid = @transid;

		with _seed (is_credit, accountid, contractorid, personid)  as (
			select 'true', acc.account_id('ïîäîò÷åò'), null, org.person_id('ÔÅÄÎÐÎÂ À. Í.')
			union all 
			select 'false', acc.account_id('Ñ×ÅÒÀ Ê ÎÏËÀÒÅ'), org.contractor_id('E&N suppliers'), null
		)
		insert acc.entries (transactionid, is_credit, accountid, contractorid, personid)
		select @transid, s.is_credit, s.accountid, s.contractorid, s.personid
		from _seed s;

		--select * from acc.entries e where e.transactionid = @transid;		

		select @note  = 'transaction ' + cast(@transid as varchar(max))  + ' recorded'
	select @note;
--	throw 50001, @note, 1

	commit transaction
end try

begin catch
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		--DECLARE @ErrorMessage NVARCHAR(4000);

        SELECT  ERROR_MESSAGE()
		--select @ErrorMessage error;	
end catch
go

--set nocount on; exec acc.toggleReceiptBank 82472, 1


