if OBJECT_ID('acc.begEntries_update') is not null drop proc acc.begEntries_update
go
create proc acc.begEntries_update @cutdate date as
	-- this proc take the latest fixed beg entry, calculates the rt since last date
	-- and records new beg entry at @cutdate
set nocount on; 
declare @date date = getdate()

;with s (entrydate, registerid, amount, bookkeeperid, entrytime) as(
	select 
		@cutDate entrydate, 
		acc.shopRegister_id(d.shop) registerid, 
		sum (amount) amount,
		org.user_id('interbot') bookkeeperid, 
		current_timestamp entrytime
	from acc.divisions_cash_f(@date) d
	where transdate<@cutDate
	group by d.shop
)
merge acc.beg_entries as t using s 
on 
	t.entrydate=s.entrydate and 
	t.registerid =s.registerid
when not matched then
insert (entrydate, registerid, amount, bookkeeperid, entrytime)
values (entrydate, registerid, amount, bookkeeperid, entrytime);
go


select * from acc.beg_entries
declare @date date = getdate(), @cutDate date = '20240101'
--exec acc.begEntries_update @cutDate

select * from acc.beg_entries
