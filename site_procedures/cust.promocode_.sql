if OBJECT_ID('cust.promocode_') is not null drop function cust.promocode_
go
create function cust.promocode_(@phone char(10)) returns varchar(max) as
	begin 
		declare @promocode varchar(max);
		select @promocode = isnull((select promocode
		from web.promo_log l
			join web.promo_events e on e.eventid = l.eventid
		where 
			custid= cust.customer_id(@phone) 
			and e.eventClosed='False'
			and cast (getdate() as date) between e.datestart and e.datefinish
			and used = 'False'), 0)
		return @promocode
	end
go

declare @phone varchar(max) = '9167834248'
select cust.promocode_(@phone)

