/*
	пример запуска процедуры при нажатии на кнопку "Оформить заказ"
*/
declare 
	@r int,
	@goods inv.web_order_type, 
	@userid int =  17205, @message varchar(max) , 
	@time int = 3;
insert @goods (styleid, size, color, qty) values 
	(19212, 'XS', 'cappuchino', 1), 
	(19212, 'L', 'PENCIL', 1),
	(19314, 'L', '677 mist wi', 0), 
	(19321, 'M', 'CHARCOAL FUME', 1);
exec @r = inv.web_order_proc 
	@customerid = @userid,	
	@goods = @goods,
	@message = @message output, 
	@wait_minutes = @time;
select @r;