USE [fanfan]
GO

if OBJECT_ID ('cust.c1_person_create') is not null drop proc cust.c1_person_create
go
create procedure cust.c1_person_create
	@c1divisionID int,
	@fname varchar( 50 ),
	@mname varchar( 50 ),
	@lname varchar( 50 ),
	@gender char( 1 ) = null,
	@birthdate datetime,
	@phone varchar( 10 ),
	@email varchar( 50 ),
	@password varchar( 25 )
as
begin try 
	begin transaction
	-- идентификация персоны
	-- если при совпадении имени, отчества и фамилии и совпадает дата рождения или телефон - то это она и есть, 
	-- если не указана ни дата рождения, ни телефон - то всегда создаем новую персону

		declare @personID int, @divisionID int;

		set nocount on;

		select @divisionID = dp.divisionID
		from cust.v_divisions_programs dp
		where dp.c1divisionID = @c1divisionID

		if @divisionID is null return -1

		if @email = '' set @email = null;
		if @phone = '' set @phone = null;
		if isdate( @birthdate ) = 0 set @birthdate = null;			
		if @mname ='' set @mname=null;


		select @personID = p.personID
		from cust.persons p
			join cust.connect c on c.personID = p.personID and c.connecttypeID = cust.connecttype_id( 'мобильный телефон' )
		where isnull(p.fname, '') = isnull (@fname, '')
		  and isnull(p.mname, '') = isnull(@mname, '')
		  and isnull (p.lname, 0) =isnull ( @lname, '')
		  and ( ( isnull(p.birthdate, 0) = isnull( @birthdate, 0) ) or ( c.connect = @phone ) );

		-- если клиент еще не зарегистрирован, добавляем его в таблицу cust.persons
		if @personID is null 
		begin
			insert cust.persons( fname, mname, lname, gender, birthdate )
				select	cust.norm_names( @fname ),
						cust.norm_names( @mname ), 
						cust.norm_names( @lname ), 
						isnull( @gender, cust.define_gender( @fname ) ), 
						@birthdate;

			select @personID = scope_identity()
	
			--добавляем в таблицу активаций клиентов, откуда можно узнать дату и время активации, и какой-то код, видимо СМС сервис
			merge cust.persons_activations as trg
			using ( select @personID as personID, @divisionID as divisionID ) as src
			on trg.personID = src.personID
			when not matched then
				insert ( personID, divisionID, activation_date ) values
					( src.personID, src.divisionID, getdate() );

			-- записываем контакты клиента в таблицу
			with
			_s( personID, connecttypeID, connect ) as (
				select @personID, cust.connecttype_id( 'мобильный телефон' ), @phone
				union all
				select @personID, cust.connecttype_id( 'электронная почта' ), @email
			)
			merge cust.connect as trg
			using ( select * from _s where connect is not null ) as src
			on trg.personID = src.personID and trg.connecttypeID = src.connecttypeID
			when matched then
				update set connect = src.connect
			when not matched then
				insert ( personID, connecttypeID, connect ) values
					( src.personID, src.connecttypeID, src.connect );
	
			--теперь неплохо бы записать клиента в какую-то программу
			insert cust.persons_programs
			select @personid, p.programID, 1, 'A', 0, 0, 0, 1
			from cust.programs p
				join org.chains ch on ch.chain=program
				join org.divisions d on d.chainID=ch.chainID
			where d.divisionID=@divisionid
		end
			commit transaction
		return @personid
end try
begin catch
		select ERROR_MESSAGE()
 		rollback transaction

end catch
go


if object_id('cust.cust_registration_tsheets_p') is not null drop proc cust.cust_registration_tsheets_p
go

create proc cust.cust_registration_tsheets_p
		@salesperson varchar (25), 
		@shop varchar (25), 
		@fname varchar (25), 
		@mname varchar (25), 
		@lname varchar (25), 
		@gender varchar (3), 
		@d_of_b char (10), 
		@phone char (20), 
		@mail varchar (50)
as
set nocount on;
	declare @c1divisionid int, @password varchar (25);	
	declare @divisionid int = (select divisionid from org.divisions where divisionfullname=@shop);
	declare @last_customerid int = (select top 1 personid from cust.persons order by 1 desc);

	select @c1divisionid= dw.c1divisionID 
	from c1.divisions_warehouses dw
		join org.divisions d on d.divisionID=dw.divisionID
		where d.divisionfullname=@shop;
	
	if @gender ='жен' set @gender='f'
	if @gender ='муж' set @gender='m'
	if @mname='' set @mname=null;
	if @d_of_b='' set @d_of_b='19000101'
	if @mail='' set @mail=null;

	declare @r int;

	exec @r=cust.c1_person_create 
			@c1divisionID ,
			@fname,
			@mname,
			@lname,
			@gender,
			@d_of_b,
			@phone,
			@mail,
			@password;

		--	select @last_customerid	;
	if @r <= @last_customerid 
		/*
			if person with the same names exist and the phones do not match
			and customer cannot support that it is his old phone, create new customere with new phone
		*/
	begin 
		begin try 
			begin transaction 
					
				insert cust.persons (fname, mname, lname, gender, birthdate)
				select @fname, @mname, @lname, @gender, @d_of_b;
				select @r = SCOPE_IDENTITY(); --@r - equivalent to @personid;

					--create person activation
				insert cust.persons_activations( personID, divisionID, activation_date ) values
					( @r, @divisionid, getdate() );
					
					--insert customer connect (phone)
				
				insert cust.connect(personID, connecttypeID, connect, prim, active)
				values 
					(@r, 1, @phone, 'True', 'True' )

							--теперь неплохо бы записать клиента в какую-то программу
			insert cust.persons_programs
			select @r, p.programID, 1, 'A', 0, 0, 0, 1
			from cust.programs p
				join org.chains ch on ch.chain=program
				join org.divisions d on d.chainID=ch.chainID
			--	join org.chains_clients cc on cc.chainid=ch.chainID
			--	join org.clients cl on cl.clientID=cc.clientid
			--	join org.divisions d on d.clientID=cl.clientID
			--	join c1.divisions_warehouses dw on dw.divisionID=d.divisionID
			--where dw.c1divisionID=@c1divisionID;
			where d.divisionID=@divisionid;

			--Throw 50001, @r, 1; -- just for debugging perposes

			commit transaction
			return @r;
		end try
		begin catch
						
			rollback transaction
			select @r =- 1
			return @r;
		end catch
	end
go
declare @r int = 17316;


--exec cust.person_delete @r





--set nocount on; declare @r int; exec @r = cust.cust_registration_tsheets_p 'КУЛИКОВСКАЯ С. А.', '07 ФАНФАН', 'АЛЕКСАНДР', '', 'КАЛИНИН', 'Муж', '', '9251001228', '' select @r; 