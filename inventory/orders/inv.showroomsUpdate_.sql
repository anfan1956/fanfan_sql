

if OBJECT_ID('inv.showroomsUpdate_') is not null drop proc inv.showroomsUpdate_
go
create proc inv.showroomsUpdate_ @showrm varchar(max) as
set nocount on;
begin try
	begin transaction
		declare @showroomid int;
		;with s (contractor) as (select @showrm)
		merge org.contractors as t using s
		on t.contractor=s.contractor
		when not matched then insert (contractor) values (contractor);
		select @showroomid=contractorid from org.contractors where contractor=@showrm;

	with s (showroomid) as (select @showroomid)
	merge org.showrooms as t using s 
	on t.showroomid = s.showroomid
	when not matched then insert (showroomid) values (showroomid);
	select @@ROWCOUNT;
--	throw 50001, 'bugging', 1;
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go

declare @showrm varchar(max) = 'Testing'
--exec inv.showroomsUpdate_ @showrm;
select * from org.contractors order by 1 desc
delete from org.contractors where contractorID = 1706


