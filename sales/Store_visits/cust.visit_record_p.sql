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

		declare @thiscount int = (
			select count(1) 
			from cust.visit v 
			where 1=1	
				and cast(visitTime as date) = cast (getdate() as date)
				and divisionid =  org.division_id(@division)
		), @totalCount int = (
			select count(1) 
			from cust.visit v 
			where 1=1	
				and cast(visitTime as date) = cast (getdate() as date)
		)


	select 'сделана запись №'
	+ cast(@thiscount as varchar) + ' из ' + cast (@totalCount as varchar) +
	' о посещении магазина ' as msg
end

go

/*
exec cust.visit_record_p 
	  'Федоров А. Н.' 
	, '07 УИКЕНД' 
	, 'ЖЕН'
	, 'ПРИМЕРКА'

*/
declare @shop varchar(25) = '07 УИКЕНД'; 
declare @thiscount int = (
	select count(1) 
	from cust.visit v 
	where 1=1	
		and cast(visitTime as date) = cast (getdate() as date)
		and divisionid =  org.division_id(@shop)
), @totalCount int = (
	select count(1) 
	from cust.visit v 
	where 1=1	
		and cast(visitTime as date) = cast (getdate() as date)
)

select @thiscount, @totalCount