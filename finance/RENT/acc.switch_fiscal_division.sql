select *
from org.retail_active_v


if OBJECT_ID ('acc.rent_fiscal_limits') is not null drop table acc.rent_fiscal_limits

create table acc.rent_fiscal_limits (
	divisionid INT not null foreign key references org.divisions (divisionid), 
	dateStart date not null,
	amount money,
	constraint PK_rent_fiscal_limits primary key (divisionid, dateStart)
)

declare @date date  = '20240701'
insert acc.rent_fiscal_limits(divisionid, dateStart, amount)
values 
(18, @date, 0)
,( 27, @date, 250000)
,( 27, eomonth(@date, 1), 226000)
, (35, @date, null)

if OBJECT_ID('acc.switch_fsc_division_') is not null drop function acc.switch_fsc_division_
go 
create function acc.switch_fsc_division_ (@amount money, @shopId int )returns bit as 
begin
	declare @switch bit

if  @amount > ( 
	select top 1 amount
	from acc.rent_fiscal_limits 
	where 
		divisionid = @shopid
		and dateStart <getdate()
	order by dateStart desc
	) 

select @switch = 'True'
else 
select @switch = 'False';
return @switch;
end 
go

declare @amount money = 227000, @shopid int  =35
select acc.switch_fsc_division_(@amount, @shopid)