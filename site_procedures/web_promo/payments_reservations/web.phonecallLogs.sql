--select * 
--from web.promo_log p
--order by 1 desc

if OBJECT_ID ('web.phonecallLogs') is not null drop table web.phonecallLogs
go
create table web.phonecallLogs (
	logid int not null identity primary key,
	custid int not null foreign key references cust.persons(personid),
	callTime datetime not null default current_timestamp
)


go



if OBJECT_ID('web.call_info_') is not null drop function web.call_info_
go
create function web.call_info_ (@phone char(10)) returns table as return
with s as (
	select top 1 s.styleid, b.brand, p.logtime, p.custid
	from web.promo_log p 
		join inv.styles s on s.styleID=p.styleid
		join inv.brands b on b.brandID=s.brandID
	where p.used = 0 and p.custid=cust.customer_id(@phone)
	order by p.logtime desc
)
select top 
	1 l.custid, 
	@phone [Телефон клиента], 
	logtime [Время звонка], 
	s.brand Бренд, s.styleID Модель, 
	c.price Цена, 
	c.discount Скидка, 
	isnull (a.promo_discount, 0) [Скидка по промокоду]
from web.phonecallLogs l 
	join s on s.custid=l.custid
	join inv.styles_catalog_v c on c.styleid=s.styleID
	left join web.styles_discounts_active_ a on a.styleid=s.styleID

order by callTime desc


go

declare @phone char (10) ='9167834248'
insert web.phonecallLogs(custid) select cust.customer_id(@phone)
select SCOPE_IDENTITY()
select * from web.call_info_(@phone)

select * from web.promo_log where custid= 17448 and used =0 order by 1 desc
select * from web.phonecallLogs


select * from web.call_info_('9167834248')
select * from web.styles_discounts_active_
select * from inv.styles_catalog_v