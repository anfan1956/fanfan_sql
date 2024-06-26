USE [fanfan]
GO
/****** Object:  StoredProcedure [cust].[cust_registration_tsheets_p]    Script Date: 28.08.2022 14:38:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [cust].[cust_registration_tsheets_p]
		@salesperson varchar (25), 
		@shop varchar (25), 
		@fname varchar (25), 
		@mname varchar (25), 
		@lname varchar (25), 
		@gender varchar (3), 
		@d_of_b char (10), 
		@phone char (10), 
		@mail varchar (50), 
		@note VARCHAR(max) output
as
set nocount on;
	declare @divisionid int = (select divisionid from org.divisions where divisionfullname=@shop);
	declare @userid int = (select userid from org.users u join org.persons p on p.personID = u.userID where lfmname = @salesperson)
	
	if @gender ='жен' set @gender='f'
	if @gender ='муж' set @gender='m'
	if @mname='' set @mname=null;
	if @d_of_b='' set @d_of_b='19000101'
	if @mail='' set @mail=null;

declare @r int;

begin 
	begin try 
		begin transaction 

		IF EXISTS (SELECT c.personID FROM cust.connect c
			WHERE c.connect= @phone) 
		BEGIN
			SELECT @note = 'Клиент с этим номером телефона уже зарегистрирован'
			SELECT @r = 0
			COMMIT TRANSACTION
			RETURN @r;
		END 

				--create person	
			insert cust.persons (fname, mname, lname, gender, birthdate)
			select @fname, @mname, @lname, @gender, @d_of_b;
			select @r = SCOPE_IDENTITY();

				--create person activation
			insert cust.persons_activations( personID, divisionID, activation_date, userid ) values
				( @r, @divisionid, getdate(), @userid );
					
				--insert customer connect (phone)				
			insert cust.connect(personID, connecttypeID, connect, prim, active)
				values (@r, 1, @phone, 'True', 'True' )
			if @mail is not null insert cust.connect(personID, connecttypeID, connect, prim, active)
				values (@r, 4, @mail, 'True', 'True' )
				
				--insert sms.phone
			insert sms.phones (customerid, phone, countryid) values(@r,  '7' + @phone, '643') 			

			--теперь неплохо бы записать клиента в какую-то программу
		insert cust.persons_programs
		select @r, 3, 1, 'A', 0, 0, 0, 1

		SELECT @note = 'Покупатель зарегистрирован'
--			Throw 50001, @r, 1; -- just for debugging perposes
		commit transaction
		return @r;
	end try

	begin CATCH
		SELECT @note = ERROR_MESSAGE()
		rollback transaction
		select @r =- 1
		return @r;
	end catch
end
GO

SELECT 
	TOP 3 p.*
FROM CUST.persons p ORDER BY 1 DESC
---EXEC cust.person_delete @personID = 17362

set nocount on; declare @r INT, @note VARCHAR(max); 
--exec @r = cust.cust_registration_tsheets_p 'ФЕДОРОВ А. Н.', '07 ФАНФАН', 'fan', 'fan', 'Fanfan', 'Муж', '', '999 999 5544', '', @note OUTPUT;
select @note note, @r customerid; 

