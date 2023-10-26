if OBJECT_ID ('hr.phones_authorised_json') is not null drop function hr.phones_authorised_json
go
create function hr.phones_authorised_json () returns varchar(max) as 
begin
	declare @phones varchar(max);
	select distinct @phones = (select s.personid,  phone
	from hr.schedule_21 s
		join org.persons p on p.personID = s.personid
		join org.users u on u.userID =p.personID
	where date_finish is null and phone is not null 
	for json path)
	return @phones
end 
go
select hr.phones_authorised_json()


