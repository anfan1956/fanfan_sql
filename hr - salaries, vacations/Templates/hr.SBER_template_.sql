if OBJECT_ID('hr.SBER_template_') is not null drop function hr.SBER_template_
go
create function hr.SBER_template_ (@date date, @item varchar(max)) returns table  as return

select  u.phone, u.userID, ps.lastname, ps.firstname, ps.middlename, round(p.amount, 2) amount 
from hr.periodCharges p
	join org.users u on u.userID=p.personid
	join org.persons ps on ps.personID=u.userID
	join hr.payrollItems i on i.itemid=p.itemid
where p.periodEndDate = @date and i.item =@item

go

