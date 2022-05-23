use fanfan
go

if OBJECT_ID ('org.active_retail_divisions_f') is not null drop function org.active_retail_divisions_f
go
create function org.active_retail_divisions_f (@date date) returns table as return
select d.divisionID, d.division, clientID, d.divisionfullname 
from org.divisions d
	where 
		isnull(d.datefinish, getdate())>=cast(getdate() as date)
		and retail= 'True'
go

select * from org.active_retail_divisions_f(GETDATE())