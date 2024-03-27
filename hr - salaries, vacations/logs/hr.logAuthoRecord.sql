use fanfan
go

if OBJECT_ID ('hr.logAuthoRecord') is not null drop proc hr.logAuthoRecord
go

create proc hr.logAuthoRecord  @userid int, @cashierid int, @articleid int, @amount money
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction
		
		
		declare @code char(5), @logid int;
		update a set a.used = 'True'
		from hr.logAutorizations a 
		where a.userid=@userid;

		select @code = code from cmn.random_5

		insert hr.logAutorizations (userid, cashierid, amount, code, articleid)
		values (@userid, @cashierid, @amount, @code, @articleid)
		select @logid = SCOPE_IDENTITY();

		select @logid;
		



--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go


		
select code from hr.logAutorizations where userid = 66 and used is null
select * from org.users u where u.userID = 66
