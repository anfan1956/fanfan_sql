
-- ***************************************---
if OBJECT_ID ('hr.manualSalary') is not null drop proc hr.manualSalary
go

create proc  hr.manualSalary 
			@date datetime
		, 	@amount money 
		,	@person varchar(max) 
		,	@doc varchar(max)
as 

set nocount on;
set transaction isolation level read committed;
declare @msg varchar (max)
begin try  
	begin transaction
	declare @transid int ;
	insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document )
	select @date, 1070, 643, 13, 619, @amount, @person, @doc
	select @transid = SCOPE_IDENTITY();
	with _seed (is_credit, accountid) as (
		select 1, 8 
		union all 
		select 0, 15
	)
	insert acc.entries (transactionid, is_credit, accountid, personid)
	select 
		@transid, s.is_credit, s.accountid, org.person_id(@person)
	from _seed s;
	declare @mes varchar(max);
	select @mes = 'Записана транзакция № ' + cast (@transid as varchar)
	select @mes msg
--	;throw 50001, 'debuging' , 1 
	select @msg = null
	commit transaction
end try
begin catch
	select @msg = ERROR_MESSAGE()
	select @msg
	rollback transaction
end catch
go 

declare 
			@date datetime = '2025-01-15'
		, 	@amount money = 50000
		,	@person varchar(max) = 'ИВАНОВА Т. К.'
		,	@doc varchar(max) = 'cash'

	
--exec hr.manualSalary @date, @amount, @person, @doc

select top 10 t.*
	, p.lfmname
	, a.article 
from acc.transactions t 
	join acc.entries e on e.transactionid = t.transactionid 
		and e.is_credit = 'True'
		and t.articleid =2055
	join org.persons p on p.personID =e.personid and p.personID =5
	join acc.articles a on a.articleid = t.articleid
order by 1 desc
select t.*
--update t set t.amount = t.amount/6*4
from acc.transactions t 
where t.transactionid in (16920,16892,16740)