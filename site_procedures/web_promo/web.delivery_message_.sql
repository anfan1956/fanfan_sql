select * from inv.site_reservations

if OBJECT_ID('web.delivery_message_') is not null drop function web.delivery_message_
go 
create function web.delivery_message_(@orderid int) returns varchar (max) as 
begin
	declare @message varchar(max), @shopid int
		select @shopid = pickupShopid from inv.site_reservations r where reservationid = @orderid
		if @shopid is not null
			begin
				select @message = 'заказ можно получить в магазние ' + right(d.divisionfullname, len(d.divisionfullname)-3)  + ' в TK ' + 
					d.comment
				from org.divisions d where d.divisionID=@shopid
			end 
		else
			begin
				select @message = 'ждите сообщение о доставке'
			end

	return @message
end
go
declare @orderid int = 77788;
declare @shopid int;

select @shopid = pickupShopid from inv.site_reservations r where reservationid= @orderid
select web.delivery_message_(77788)
select @shopid