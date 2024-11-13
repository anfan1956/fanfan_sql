if OBJECT_ID('acc.divisionCashFlow_') is not null drop function acc.divisionCashFlow_
go
create function acc.divisionCashFlow_(@date date, @shop varchar(max))
	returns table as return

	with _date (startDate) as (
		select 
		   CASE 
			WHEN DATEADD(MM, -1, @date) > f.entrydate THEN DATEADD(MM, -1, @date)
			ELSE f.entrydate 
			end startDate
	from acc.beg_entries_around_date_f (@date) f
	where f.registerid=acc.shopRegister_id(@shop)

	)
	select 
		0 transid, startDate transdate, 
		sum(amount) amount,
		acc.shopRegister_id(@shop) registerid,
		@shop shop, 
		'начальный остаток' transtype,
		u.userID personid,
		u.username person,
		'НО на начало периода' comment
	from acc.divisions_cash_f(@date) c  
		cross apply (select * from org.users where userID = org.user_id('INTERBOT')) u
		cross apply _date d
	where c.shop= @shop and c.transdate<d.startDate
	group by u.userID, u.username, d.startDate

		union all
	
	select c.*
	from acc.divisions_cash_f(@date) c  
		cross apply _date d
	where c.shop= @shop and c.transdate>=d.startDate
go


declare 
	@date date = '20241101',
	@shop varchar(max)= '07 Уикенд';
select d.*, sum(amount)  over()
from acc.divisionCashFlow_(@date, @shop) d
order by d.transdate
select * from org.users u where u.userID = org.user_id('INTERBOT')

select * from acc.beg_entries e order by 1 desc
--insert acc.beg_entries(entrydate, registerid, amount, bookkeeperid) select '20241101', 31, 0, 1


