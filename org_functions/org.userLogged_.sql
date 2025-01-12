
if OBJECT_ID('org.userIdLogged_') is not null drop function org.userLogged_
go
create function org.userLogged_(@userName varchar(max), @pass varchar(max))
returns int as
begin
declare @userid int;

select  top 1 @userid = isnull (ca.userID, 0)
from org.users u
outer apply (
	select u.userID from org.users u 
	where u.username = @userName 
	and password = @pass ) ca;
return @userID
end
go

