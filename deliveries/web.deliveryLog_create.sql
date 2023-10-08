--set nocount on; 
--declare @r int, @note varchar(max); if @@TRANCOUNT > 0 rollback transaction;  declare @info web.reservation_type; 
--insert @info values (662593, 14131, 0, 0, 0, 47, 14131 );  
----exec @r = web.reservation_create 'FANFAN.STORE', 'INTERBOT F. ', '9167834248', @info , @note output, 15, 0; select @note note, @r orderid;


if OBJECT_ID('web.deliveryLog_create') is not null drop proc web.deliveryLog_create
go
create proc web.deliveryLog_create @spotid int, @pickupShopid int as
set nocount on; 
	declare @r int;

	insert web.delivery_logs (spotid, pickupDivId, code)
	select 0, 0, 0
	
	--insert web.deliveryLogs(empid, divisionid, addressid, custid, recipient, recipient_phone) 
	--select 
	--	org.person_id('INTERBOT F.'), 
	--	org.division_id('FANFAN.STORE'), 
	--	cs.addressid, 
	--	custid, 
	--	rp.fio, 
	--	rp.phone
	--from web.customer_spots cs
	--	cross apply web.receiver_phones rp
	--	where cs.spotid= @spotid and rp.phoneid=cs.receiver_phoneid
	--select @r = SCOPE_IDENTITY()
	--select @r = isnull (@r, 0)
	--select @r;
go



select * from web.deliveryLogs order by 1 desc
select * from web.delivery_logs
declare @phone char (10) = '9167834248'
select * from web.customer_spots
select web.delivery_addr_js_('9167834248')


