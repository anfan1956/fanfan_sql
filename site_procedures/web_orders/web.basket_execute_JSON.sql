declare @phone char (10)= '9167834248';


-- this  proc is old is not used. the tables  -  like web.basketLogs - deleted

if OBJECT_ID('web.basket_execute_JSON') is not null drop proc web.basket_execute_JSON
go

create proc web.basket_execute_JSON(@json varchar(max)) as
set nocount on;

begin try
	begin transaction
		declare @r int;
		declare @note varchar(max)

		insert web.basket (uuid, custid)	
		select distinct the_session, cust.customer_id(phone)
			from web.basket_action_fromJSON_(@json) 
		select @r = SCOPE_IDENTITY();

		insert web.basketLogs (
			logid, parent_styleid, color, size, qty)
		select 
			@r, j.styleid, j.color, j.size, j.qty* j.opersign 
		from web.basket_action_fromJSON_(@json)  j

		;

--	select * from web.basketLogs l where l.logid = @r;
	select @note= 'success';
--	select @note success for json path;
	throw 50001, @note , 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE() error for json path
	rollback transaction

end catch
go

declare @json varchar(max) ;
select @json =
--'[
--	{"action": "remove", "phone": "9167834248"},
--	{"styleid": "19628", "color": "blUE NAVY", "size": "XXXL", "qty": "1"}, 
--	{"styleid": "19996", "color": "BLU BLACK 08346", "size": "XXXL", "qty": "1"} 
--]';

'[{"phone": "9167834248", "Session": "c4c841d1-2d31-4323-8795-991ce6e5d390", "action": "remove"}, {"styleid": "13530", "color": "WHITE", "size": "1", "qty": "1"}, {"styleid": "13530", "color": "WHITE", "size": "3", "qty": "4"}]'

exec web.basket_execute_JSON @json