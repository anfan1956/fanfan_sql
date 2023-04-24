
if OBJECT_ID ('cust.phone_update') is not null drop proc cust.phone_update
go 
create proc cust.phone_update @customerid int, @phone char(10) as
set nocount on;
declare @r int;
begin try
	begin transaction

		update c set c.connect = @phone
		from cust.connect c
		where c.personID = @customerid 
		and c.connecttypeID = 1;

		update s
		set s.phone = '7' + @phone  
		from sms.phones s where s.customerid= @customerid
	commit transaction
end try
begin catch
	rollback transaction
	select @r= -1
	return @r
end catch
go

