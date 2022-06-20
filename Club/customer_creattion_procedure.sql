USE [fanfan]
GO

ALTER proc [cust].[cust_registration_tsheets_p]
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
	--select 	@c1divisionID ,
	--		@fname fname,
	--		@mname mname,
	--		@lname lname,
	--		@gender gender,
	--		@d_of_b d_of_b,
	--		@phone phone,
	--		@mail mail,
	--		@password pass;

	exec @r=cust.c1_person_create 
			@c1divisionID ,
			@fname,
			@mname,
			@lname,
			@gender,
			@d_of_b,
			@phone ,
			@mail ,
			@password ;
	return @r;
