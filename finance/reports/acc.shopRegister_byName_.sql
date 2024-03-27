if OBJECT_id ('acc.shopRegister_byName_') is not null drop function acc.shopRegister_byName_
go
create function acc.shopRegister_byName_(@shop varchar(max)) returns int as 
begin
	declare @regid int;

	SELECT @regid = registerid 
	from acc.registers f
	where 
		RIGHT(f.account, LEN(account) - 4)  =
		right(replace(@shop, ' ', ''), len(replace(@shop, ' ', ''))-2)
	return  @regid
end
go
declare @shop varchar(max) = '08 ФАНФАН'

select acc.shopRegister_byName_(@shop)