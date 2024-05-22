use fanfan
go

if OBJECT_ID ('hr.employee_create_p') is not null drop proc hr.employee_create_p
go

create proc hr.employee_create_p
	-- for this procedure there is a file in github
	@companies dbo.var_type readonly,
	@fname varchar( 25 ),
	@mname varchar( 25 ),
	@lname varchar( 25 ),
	@birthdate date,
	@gender char( 3 ),
	@inn varchar( 25 ),
	@position varchar (25),
	@has_MW bit,
	@datestart date,
	@note varchar( max ) output
as 
set nocount on;
	declare @message varchar (max)= 'Just debugging'
	declare @pcount int, @r int;
	declare @personID int, @personID_af int, @changeID int;
	declare @contractor table (contractor varchar(50), personid_ff int, is_employee bit, is_vault bit)

begin try
		select @pcount = count( personID ) from org.persons p where p.firstname = @fname
														and p.middlename = @mname
														and p.lastname = @lname
														and p.birthdate = @birthdate
														and p.gender = iif( @gender = 'ЖЕН', 'f', 'm' );
-- persons
		if @pcount > 1 begin
			select @r = 1
			select @note = 'Найдено больше одного человека с указанными параметрами'
			return 1
		end;
		select @personID = p.personID from org.persons p where p.firstname = @fname
														and p.middlename = @mname
														and p.lastname = @lname
														and p.birthdate = @birthdate
														and p.gender = iif( @gender = 'ЖЕН', 'f', 'm' );

	begin transaction

--	1. create person in table org.persons
		if @personID is null begin
			insert org.persons( firstname, middlename, lastname, birthdate, gender, inn ) values
				(	dbo.properstring( upper( @fname ) ), dbo.properstring( upper( @mname ) ), dbo.properstring( upper( @lname ) ), 
					@birthdate, iif( @gender = 'ЖЕН', 'f', 'm' ), @inn );
			select @personID = scope_identity();

--	2. create contractor in anfan_release.org.contractors
			insert anfan_release.org.contractors (contractor, is_employee, personid_ff, is_vault)
			select top 1 p.lfmname, 'true', p.personID, 'true' from org.persons p order by p.personid desc;
			select @personID_af = scope_identity();
			
-- 3. create employee in anfan_release.org.employees
			with s (employeeid, employerid, accountid, is_oncomission) as 
				(
					select @personID_af, cl.clientid, anfan_release.acc.accountid_func('комиссионные', 'RUR'), 'true'
					from anfan_release.org.clients cl
						join @companies c on c.var1=cl.client
				)
			insert anfan_release.org.employees (employeeid, employerid, accountid, is_oncommission) 
			select employeeid, employerid, accountid, is_oncomission from s;

--	4. insert into hr.schedule_21 position in all working 
			with s (personid, positionid, date_start, has_MW) as 
				(
					select distinct  @personID, p.positionid, @datestart, @has_MW
					from org.chains ch
					join org.divisions d on d.chainID=ch.chainID
					join org.clients cl on cl.clientID=d.clientID
					join anfan_release.org.clients c on c.clientid_ff=cl.clientID 
					join @companies co on co.var1=c.client
					join hr.positions_21 p on p.chainid=ch.chainID and p.position=@position
						and p.clientid=cl.clientID
					where d.datefinish is null
				)
			insert hr.schedule_21(personid, positionid, date_start, has_MW)
			select personid, positionid, date_start, has_MW from s;

--	5. create user			
			with _code(code) as (select code from cmn.random_5)
			, s (userID, username, password, roleID)  as 
				(
					select p.personID,  p.lfmname,  cast(c.code as char(5)), 5
					from org.persons p 
						cross apply _code c
					where p.personID=@personID
				)
			insert org.users (userID, username, password, roleID)
			select userID, username, password, roleID from s;

-- 6. insert hr.employees for inn
			insert hr.employees(empid, inn)
			values (@personID, @inn);

--7. insert org.contractors
			with s (contractor, inn) as 
				(
					select lfmname, inn
					from org.persons p where p.personID=@personID
				)
			insert org.contractors(contractor, inn)
				select contractor, inn  from s;
--8. insert beginnig entries
		;
		with _stype(salarytypeid) as (select 1 union select 2)
		insert hr.salary_BegEntries (employeeid, entrydate, salarytypeid, amount, clientid)
		select  distinct
			@personID, @datestart, t.salarytypeid, 0, p.clientid
		from hr.schedule_21 s
			join hr.positions_21 p on p.positionid=s.positionid
			cross apply _stype t
			where s.personid = @personID

	


		end;

	set @note = 'Зарегистрирован новый сотрудник ' + (select p.lfmname from org.persons p where personID=@personID)
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
			

set nocount on; declare 
	@fname varchar( 25 )='Вера',
	@mname varchar( 25 )='Владимировна',
	@lname varchar( 25 )='Юрова',
	@birthdate date='19861205',
	@gender char( 3 )='жен',
	@inn varchar( 25 )='000000',
	@position varchar (25)='консультант', 
	@has_MW bit='False',
	@datestart date='20240510',
	@note varchar( max );
declare @companies dbo.var_type;
insert @companies values ('Проект Ф')

	--exec hr.employee_create_p
	--	@companies, 
	--	@fname,
	--	@mname,
	--	@lname,
	--	@birthdate,
	--	@gender,
	--	@inn,
	--	@position, 
	--	@has_MW, 
	--	@datestart,
	--	@note output;
	--select @note


