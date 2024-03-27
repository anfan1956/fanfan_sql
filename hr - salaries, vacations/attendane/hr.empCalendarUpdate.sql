use fanfan
go

if OBJECT_ID ('hr.empCalendarUpdate') is not null drop proc hr.empCalendarUpdate
go

create proc [hr].[empCalendarUpdate]  @user varchar(max), @shop varchar(max), @datein date, @dateout date output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction;
		declare @mes int
		if @dateout is not null 
			begin 
				delete w 
				from hr.workingCalendar w
				where w.attendanceDate = @dateout and w.empid = org.person_id(@user)
				select @mes = @@ROWCOUNT
--				select @mes mes
			end;
		if @datein is not null
			begin
				with s  (empid, divisionid, attendanceDate) as (
					select org.person_id(@user), org.division_id(@shop), @datein			
				)
				insert hr.workingCalendar (empid, divisionid, attendancedate) select
				s.empid,s.divisionid, s.attendanceDate
				from  s;
				select @mes = @@ROWCOUNT;
			end 
			--if @mes = 0	
			select @mes
	--;throw 50001, @message, 1
	commit transaction
end try
begin catch
	
	select 'дублирование даты. Запись не сделана'
	rollback transaction
end catch
GO
--set nocount on; exec hr.empCalendarUpdate 'МИТИНА Ю. В.', '07 ФАНФАН', '20240602', Null

set nocount on; exec hr.empCalendarUpdate 'МИТИНА Ю. В.', '07 ФАНФАН', Null, '20240601'
--set nocount on; exec hr.empCalendarUpdate 'БАЛУШКИНА А. А.', '08 ФАНФАН', Null, '20240601'