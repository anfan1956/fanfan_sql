if OBJECT_ID ('acc.rentRate') is not null drop table acc.rentRate
go

create table acc.rentRate (
	rateId int not null identity primary key,
	divisionid int not null foreign key references org.divisions (divisionid),
	rate numeric (4,3) not null,
	dateStart date not null, 
	constraint uq unique (divisionid, dateStart)
)

insert acc.rentRate (divisionid, rate, dateStart)
values 
(18, .15, '20240101'), 
(25, .13, '20240101'), 
(27, .13, '20240101') 

if OBJECT_ID  ('acc.rentRateDate_') is not null drop function acc.rentRateDate_
go
create function acc.rentRateDate_(@divisionid int, @date date) returns numeric(4,3) as 
begin
	declare @rate numeric (4,3);
		with s (rate, num, VAT) as (
		select 
			r.rate, 
			ROW_NUMBER () over (partition by divisionid order by datestart desc), 
			1.2
		from acc.rentRate r
		where 
			r.divisionid = @divisionid 
			and r.dateStart <= @date 
		)
	select @rate = s.rate * s.VAT
	from s where num = 1;

	return @rate

end
go


select acc.rentRateDate_(18, getdate())