
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
			@date datetime = '2025-06-15'
		, 	@amount money = 50000
		,	@person varchar(max) = 'ИВАНОВА Т. К.'
		,	@doc varchar(max) = 'cash'

	
--exec hr.manualSalary @date, @amount, @person, @doc
