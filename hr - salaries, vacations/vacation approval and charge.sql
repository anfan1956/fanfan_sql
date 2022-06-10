/*
hr.vacations_pending_v
hr.vacation_approve2_p
hr.vacations_charge_p
*/
use fanfan
go

if OBJECT_ID('hr.vacations_pending_v') is not null drop view hr.vacations_pending_v
go
create view hr.vacations_pending_v as 
	select 
		v.vacationid [№_отпуска], cast(v.vacation_date as datetime) дата_отпуска, 
		cast (DATEADD(dd, -hr.parameter_value_f('дн/перед/отпуском', null), v.vacation_date) as datetime) charge_date,
		v.num_of_weeks недель, v.vacationyear за_год, p.personID id, p.lfmname сотрудник, p2.lastname авторизовал,
		v.vac_pay_charged
	from hr.vacations v 
		join org.persons p on p.personID = v.personid
		left join org.persons p2 on p2.personID = v.authorityID
	where taken = 'False'
go

if OBJECT_ID('hr.vacation_approve2_p') is not null drop proc hr.vacation_approve2_p
go
create proc hr.vacation_approve2_p 	@vacationid int, @authorityid int, @note varchar(max) output as
	set nocount on;
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

declare @vacationid int = 40, @authorityid int = 1, @note varchar(max);
---exec hr.vacation_approve2_p @vacationid, @authorityid, @note output; select @note

--update v set v.approval_date = null, authorityID = null from hr.vacations v where vacationid = 40



if OBJECT_ID('hr.vacations_charge_p')  is not null drop proc hr.vacations_charge_p
go 
create proc hr.vacations_charge_p as 
	set nocount on;
	declare @message varchar(max);
	if exists (select * from hr.vacations_pending_v v 
				where getdate() > = v.charge_date 
				and vac_pay_charged is null 
				and авторизовал is not null
			)
		begin
			begin try
				begin transaction
					
					select @message = 'succeded';
					throw 50001, 'debuging', 1
				commit transaction
			end try
			begin catch
				select @message = ERROR_MESSAGE()
				rollback transaction
			end catch		
			insert hr.vacation_charges_log (log_code) values (@message)
		end
	else 
		insert hr.vacation_charges_log (log_code) values ('no authorised vacations pending')

go 

--exec hr.vacations_charge_p

select  *  from  hr.vacation_charges_log
--truncate table  hr.vacation_charges_log

select * from hr.vacations_pending_v;
select * from hr.vacations v 
where DATEADD(dd, -10,  v.vacation_date)< getdate() 
	and taken = 'false'
