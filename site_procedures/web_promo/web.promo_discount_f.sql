USE [fanfan]
GO
/****** Object:  UserDefinedFunction [web].[promo_discount_f]    Script Date: 25.04.2023 19:21:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [web].[promo_discount_f] (@phone char(10), @styleid int, @code varchar(10)) returns varchar(max) as
begin
 
	declare @note varchar(max) ;
	declare @custid int=cust.customer_id(@phone);
	declare @result table (used bit, eventClosed bit, datefinish date)
	

	insert @result (used, eventClosed, datefinish) 
	select p.used, e.eventClosed, datefinish
	from web.promo_log p 
		join web.promo_events e on e.eventid=p.eventid
	where 
		p.custid=cust.customer_id(@phone) 	and p.promocode = @code
		and used = 'False' 	and e.datefinish>= cast(getdate() as date)


	if (select count (*)  from @result) = 0 
		begin 
			select @note = 'неверный промокод'
		end
	else if  (select count (*)  from @result where used = 'True' or eventClosed = 'True' or datefinish<cast(getdate()as date)) > 0 
		begin 
			select @note ='Этот промокод больше не действителен'
		end 
	else 
		select @note =  
			cast(sd.discount as varchar(max))
		from web.promo_events e
		join web.promo_styles_discounts sd on sd.eventid=e.eventid 
		join web.promo_log l on l.eventid=sd.eventid --and sd.styleid=l.styleid
		where 
			e.eventClosed='False' 
			and l.used='False' 
			and l.custid= @custid
			and sd.styleid=@styleid
	return @note
end
go
declare @phone varchar(max) ='9167834248', 
	@promo varchar(max) ='905570',
	@styleid int = 20294, 
	@note varchar(max);


select  web.promo_discount_f(@phone, @styleid, @promo )
select p.used, e.eventClosed, datefinish
from web.promo_log p 
	join web.promo_events e on e.eventid=p.eventid
where 
	p.custid=cust.customer_id(@phone) 	and p.promocode = @promo
	and used = 'False' 	and e.datefinish>= cast(getdate() as date)

		select @note =  
			cast(sd.discount as varchar(max))
		from web.promo_events e
		join web.promo_styles_discounts sd on sd.eventid=e.eventid 
		join web.promo_log l on l.eventid=sd.eventid --and sd.styleid=l.styleid
		where 
			e.eventClosed='False' 
			and l.used='False' 
			and l.custid= cust.customer_id(@phone)
			and sd.styleid=@styleid
select @note