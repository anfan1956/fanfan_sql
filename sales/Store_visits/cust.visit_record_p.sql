if OBJECT_ID('cust.visit_record_p') is not null drop proc cust.visit_record_p

go
create proc cust.visit_record_p 
	@user varchar(25)
	, @division varchar(25)
	, @visitortype varchar(25)
	, @action varchar(25)
	, @visittime time = null

as 
begin
	insert into cust.visit (userid, divisionid, visitorTypeid, actionid, visitTime)
	select 
		org.person_id (@user) as userid
		, org.division_id (@division) divisionid
		, (	select vt.id
			from cust.visitorType vt
			where vt.visitorType = @visitortype
		) as visitorTypeid
		, (select a.id
			from cust.visitAction a
			where a. actionName = @action
		) as actionid
		, (select coalesce (@visittime, current_timestamp)) as visittime;
	select '������� ������ '
	+ cast(scope_identity() as varchar) +
	' � ��������� �������� ' 
end

go

exec cust.visit_record_p 
	  '������� �. �.' 
	, '07 ������' 
	, '���'
	, '��������'

