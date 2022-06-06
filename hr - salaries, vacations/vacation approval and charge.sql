use fanfan
go
if OBJECT_ID('hr.vacation_approve2_p') is not null drop proc hr.vacation_approve2_p
go
create proc hr.vacation_approve2_p 	@vacationid int, @authorityid int, @note varchar(max) output as
	declare @approval table (autorityid int, approval_date datetime);

	begin try 
		begin transaction
			if (select count(*) from org.users where userid =@authorityid and roleID in (2, 3)) = 0
				begin 
					select @note = 'нет прав для авторизации';
					throw 50001, @note, 1
				end 
			update v set v.authorityID=@authorityid, v.approval_date= CURRENT_TIMESTAMP
			output inserted.authorityid, inserted.approval_date into @approval
			from hr.vacations v		
			where v.vacationid=@vacationid
			select @note = p.lfmname + ': ' + 'согласовано '  + format(a.approval_date, 'dd.MM.yy  HH:mm') 
			from @approval a
				join org.persons p on p.personID=a.autorityid
					
--			;throw 50001, @note, 1
			commit transaction
		end try
	begin catch
		select @note = ERROR_MESSAGE()
		rollback transaction
	end catch
		

go
declare @vacationid int = 40, @authorityid int = 1, @note varchar(max)
exec hr.vacation_approve2_p @vacationid, @authorityid, @note output; select @note
select * from hr.vacations where vacationid=@vacationid
