use fanfan
go

if OBJECT_ID('hr.BunkovoPlazaSalary_p') is not null drop function hr.BunkovoPlazaSalary_p
go 
create function hr.BunkovoPlazaSalary_p(@periodEnd date) returns table as return
	

select 
	a.personID
	, p.lfmname
	, COUNT(1)/2 daysWorked
	, COUNT(1)/2 * 
				case
					when a.personID in (1, 5) then 4000 
					else 6000 
				end	amount
	, item = 'cash'
	, condition = '/Буньково'
from org.attendance a 
	join org.persons p on p.personID = a.personID
	
	cross apply (select periodStart =case datepart(dd, @periodEnd) 
		when 15 then dateadd (dd, 1, eomonth(@periodEnd, -1))
		else dateadd (dd, 16, eomonth(@periodEnd, -1))
		end 
		) as ps(periodStart)
where 1 = 1
	and a.workstationID =  23
	and cast(checktime as date) between ps.periodStart and @periodEnd
group by a.personID, p.lfmname
HAVING COUNT(CASE WHEN checktype = 1 THEN 1 END) = COUNT(CASE WHEN checktype = 0 THEN 1 END)
go

declare @periodEnd date= '20241130'
select * from hr.BunkovoPlazaSalary_p(@periodEnd)
