if OBJECT_ID('web.basketAction_p') is not null drop proc web.basketAction_p
go 
create proc web.basketAction_p 
	@json varchar (max), 
	@note varchar(max) output as

	set nocount on ;
	begin try
		begin transaction

			declare		
				@logid int, 
				@proc varchar (max),
				@phone varchar (max),
				@uuid varchar (max), 
				@max int, 
				@this int, 
				@this_total int, 
				@total int;
--				@note varchar(max)

			-- declare table for json data to convert to 
			declare @inv table (
					styleid int, 
					color varchar(max), 
					size varchar(max), 
					qty int, 
					procName varchar(max), 
					phone char(10), 
					uuid char(36)
				);

				--dump json data into @inv table
				with s (styleid	, color, size, qty, procName, phone, uuid )
					as ( 
					select styleid, color, size, qty, procName, phone, uuid 
					from OPENJSON(@json)
					with (
						styleid int '$.styleid',
						color varchar(max) '$.color',
						size varchar(max) '$.size',
						qty int '$.qty',
						procName varchar(max) '$.procName',
						phone char(10) '$.phone',
						uuid char(36) '$.uuid'
					) as jsonValue)
				, t (procName, phone, uuid) as (
					select procName, phone, uuid
					from s
					where phone is not null
				)
				, f (styleid, color, size, qty, procName, phone, uuid) as (
					select 
						s.styleid, s.color, s.size, qty, t.procName, t.phone, t.uuid
					from s
						cross apply t 
					where styleid is not null
					)
				insert @inv 
				select styleid, color, size, qty, procName, phone, uuid from f;

				select distinct @proc = procName from @inv
				select distinct @phone = phone from @inv
				select distinct @uuid  = uuid from @inv;



				select @this_total = ( select isnull (
					(
					select b.qty from web.baskets b 
						join web.logs l on l.logid= b.logid
						join @inv i on 
							i.styleid=b.parent_styleid
							and cmn.norm_(i.color)=cmn.norm_(b.color)
							and i.size =b.size 
							and (l.custid = cust.customer_id(i.phone) or l.uuid=i.uuid)
					), 0
					)
					)
							
				select @this = i.qty + @this_total from @inv i
				select @max =  inv.styleQty_avail_(@json);
						
				if (@this >@max) 
					begin
						select @note = 'превышено допустимое количество' ;
						throw 50001, @note, 1
					end 				
				else
					begin

					insert web.logs (uuid, custid)
					select distinct i.uuid,	cust.customer_id(i.phone) from @inv i 
					select @logid= SCOPE_IDENTITY();


					update b set b.logid=@logid
					from web.baskets b
						join web.logs l on l.logid=b.logid
					where l.custid = cust.customer_id(@phone)
						or l.uuid = @uuid;


					with s (logid, parent_styleid, color, size, qty)  as (
						select 	
							@logid, i.styleid, i.color, i.size,	i.qty 			
						from @inv i
					)
					merge web.baskets as t using s
						on t.logid=s.logid 
						and t.parent_styleid = s.parent_styleid
						and t.color = s.color
						and t.size = s.size
					when matched  then 
						update set t.qty = case 			
												when @proc in ('insert') then t.qty + s.qty
												when @proc in ('merge')	then 0 + s.qty  
												when @proc in ('delete') then t.qty - iif(s.qty> t.qty, t.qty, s.qty)
											end 
					when not matched and @proc in ('insert', 'merge' ) then 
						insert (logid, parent_styleid, color, size, qty)
						values (logid, parent_styleid, color, size, qty)
					when not matched by source and @proc in ('merge') and t.logid =@logid then delete;


				select @total = 
				(select isnull((
					select sum(b.qty) 
					from web.baskets b
						join web.logs l on l.logid=b.logid
						cross apply @inv u
						where l.custid = cust.customer_id(u.phone) or l.uuid= u.uuid

				), 0)) 

					select @note =  (select @this this, @max maximum, @total total for json path)
				end




				--;throw 50001, @note, 1
		commit transaction
	end try
	
	begin catch
		select @note = (select ERROR_MESSAGE() error for json path)
		rollback transaction
	end catch
go

set nocount on; declare @note varchar(max); 
declare @json varchar(max);
select @json = 
'[{"phone": "9167834248", "uuid": "fadd7d43-6065-45cd-a50d-670c1df19113", "procName": "insert"}, {"styleid": "13530", "color": "WHITE", "size": "4", "qty": "1"}]'

--exec web.basketAction_p @json, @note output; select @note;

select web.basket_this_total_(@json)