
set nocount on; 
declare @orderid int = 78182, @bankid int = org.contractor_id('АЛЬФА-БАНК'), 
@duration int = 15, @r int, @note  varchar (max); 
--exec @r = web.link_generate @orderid = @orderid, @bankid = @bankid, @duration = @duration, @note = @note output; select @r, @note;

if OBJECT_ID('web.link_on_site_p') is not null drop proc web.link_on_site_p
go 
create proc web.link_on_site_p @orderid int, @result varchar(max) output as
set nocount on;
begin
	declare 
		@duration int = 15, 
		@r int, 
		@bankid int = org.contractor_id('АЛЬФА-БАНК'),
		@note varchar(max);

	exec @r = web.link_generate @orderid = @orderid, @bankid = @bankid, @duration = @duration, @note = @note output; 
	--select @r, @note;
	select @result = @note;
	return @r	
end
go
set nocount on; 
declare @result varchar(max), @orderid int = 78182, @r int;

exec @r = web.link_on_site_p @orderid, @result output;
select @r, @result;


