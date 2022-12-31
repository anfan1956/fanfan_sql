
if OBJECT_ID('acc.register_entries_p') is not null drop proc acc.register_entries_p
go
create proc acc.register_entries_p
	@note varchar(max) output, 
	@info dbo.id_money_type readonly, 
	@bookkeeperid int
as
set nocount on;
	begin try
		begin transaction;
			declare @rows int;
			with s (entrydate, registerid, amount, bookkeeperid, entrytime) as (
				select cast (getdate() as date), i.id, i.amount, @bookkeeperid, CURRENT_TIMESTAMP 
				from @info i
			)
		merge acc.beg_entries as t using s
		on t.registerid = s.registerid 
			and t.entrydate= s.entrydate
		when not matched then 
			insert (entrydate, registerid, amount, bookkeeperid, entrytime)
			values (entrydate, registerid, amount, bookkeeperid, entrytime)
		when matched 
			and t.amount <>s.amount
			or t.bookkeeperid <> s.bookkeeperid
				then update set 
					t.amount= s.amount,
					t.bookkeeperid = s.bookkeeperid,
					t.entrytime = s.entrytime;
		set  @rows = @@ROWCOUNT;
--			select * from acc.beg_entries where entrydate = cast(getdate() as date)		;
					
		select @note = 'обновлено ' + format(@rows, '#,##0', 'ru')  + ' записей';
--		;throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go


set nocount on; declare @note varchar(max), @info dbo.id_money_type; 
insert @info values (23, 1900), (5, 27266.01), (3, 207.9), (8, 21206.49), (24, 1100), (1, 216.08), (17, 11802.49), (18, 300.45), (20, 290.67), (15, 330000), (7, 111899.36); 
--exec acc.register_entries_p @note output, @info, 1; 
select @note;

select * from acc.beg_entries where entrydate = cast(getdate() as date) order by 1 desc;
--select top 1 * from acc.beg_entries;
