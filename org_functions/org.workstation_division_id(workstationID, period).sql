use fanfan
go

if OBJECT_ID ('org.workstation_division_id') is not null drop function org.workstation_division_id
go

create function org.workstation_division_id (@workstationid int, @period date) returns int 
as
begin
	declare @divisionid int;
		with _div as (
			select wd.divisionID, workstationID, wd.datestart, 
				ROW_NUMBER() over (partition by wd.workstationid order by wd.datestart  desc) num
			from org.workstationsdivisions wd 
			where wd.datestart<@period and wd.workstationID= @workstationID
		)
		select @divisionid = divisionID
		from _div d where num =1 
	return @divisionid;
end
go
select * from org.workstations where workstation = 'SERVER'
DECLARE	 @date date = getdate();

select org.workstation_division_id(16, @date)
