--select * from web.baskets ;
--select * from web.logs

if OBJECT_ID('web.basketAction_2') is not null drop proc web.basketAction_2
go
create  proc web.basketAction_2 (@json varchar(max)) as
set nocount on;
begin try
	begin transaction

		declare @logid int, @proc varchar (max), @this int, @total int, @max int;
		declare @inv table (
			styleid int, color varchar(max), size varchar(max), 
			qty int, procName varchar(max), phone char(10), uuid char(36));

		;with s (styleid, color, size, qty, procName, phone, uuid ) as ( 
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
			) as jsonValue
		)
		, t (procName, phone, uuid) as (
			select procName, phone, uuid
			from s
			where phone is not null or uuid is not null
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

		select distinct @proc =  procName from @inv;

		select @max = sum(inv.opersign) 
		from @inv i
			join inv.styles s on s.parent_styleid= i.styleid
			join inv.barcodes b on b.styleID =s.styleID
			join inv.colors c on c.colorID=b.colorID
			join inv.sizes sz on sz.sizeID=b.sizeID
			join inv.inventory inv on inv.barcodeID=b.barcodeID
		where inv.logstateID in (8) and inv.divisionID in (0, 14, 18, 25, 27)
			and cmn.norm_(c.color)=cmn.norm_(i.color) and sz.size=i.size
		;	
		select @this =  b.qty
		from web.baskets b
			join web.logs l on l.logid=b.logid
			join @inv i  on i.styleid= b.parent_styleid
				and cmn.norm_(b.color)=cmn.norm_(i.color)
				and b.size=i.size 
				and  (l.custid= cust.customer_id(i.phone) or l.uuid=i.uuid)
		if @this is null select @this = 0;

		if @proc = 'insert'
			begin
				if (
					select qty from @inv i 
					where i.qty is not null
					) > @max - @this 
					begin
						declare @note varchar(max) = 'максимальное количество: ' + cast(@max as varchar(max));
						throw 500001, @note, 1;
					end 
			end 

		insert web.logs(uuid, custid)
		select distinct i.uuid, cust.customer_id(i.phone)
		from @inv i
		select @logid = SCOPE_IDENTITY() ;

		update b set b.logid=@logid
		from web.baskets b
			join web.logs l on l.logid=b.logid
			join @inv i on l.custid= cust.customer_id(i.phone) or i.uuid=l.uuid

		; with s (parent_styleid, color, size, logid, qty) as (select 
			styleid, color, size, @logid, qty
			from @inv i
		)
		merge web.baskets as t using s on 
			t.logid=s.logid 
			and t.parent_styleid = s.parent_styleid
			and t.color = s.color
			and t.size = s.size
		when matched  then 
			update set t.qty = 
			case 			
					when @proc in ('insert') then t.qty + s.qty
					when @proc in ('remove') then t.qty - iif(s.qty> t.qty, t.qty, s.qty) 
					when @proc in ('purchase') then t.qty - iif(s.qty> t.qty, t.qty, s.qty) end
			when not matched and @proc in ('insert') then
			insert (parent_styleid, color, size, logid, qty)
			values (parent_styleid, color, size, logid, qty)
		;
		delete from web.baskets where qty =0

				select @total =  sum(b.qty)
				from web.baskets b
					join web.logs l on l.logid=b.logid
					join @inv i  on (l.custid= cust.customer_id(i.phone) or l.uuid=i.uuid)
				select @total = isnull(@total, 0);

		select @this =  b.qty
		from web.baskets b
			join web.logs l on l.logid=b.logid
			join @inv i  on i.styleid= b.parent_styleid
				and cmn.norm_(b.color)=cmn.norm_(i.color)
				and b.size=i.size 
				and  (l.custid= cust.customer_id(i.phone) or l.uuid=i.uuid)

		if @proc in ('purchase')
			begin;
				select  'will have to run the purch proc' success for json path;
			end
		else if @proc in ('insert', 'remove')
			begin
				select @this =  b.qty
				from web.baskets b
					join web.logs l on l.logid=b.logid
					join @inv i  on i.styleid= b.parent_styleid
						and cmn.norm_(b.color)=cmn.norm_(i.color)
						and b.size=i.size 
						and  (l.custid= cust.customer_id(i.phone) or l.uuid=i.uuid)
				select @this = isnull(@this, 0);
				select 'success' success ,  @this this, @total total for json path, include_null_values
			end 
		else 
			begin
				select  'success' success for json path;
			end
		
	commit transaction
end try
begin catch;
	select ERROR_MESSAGE() error for json path
	rollback transaction
end catch
go

declare @json varchar(max);
select @json = 
'[{"uuid": "103ef4dc-5ef4-4c0d-ac16-c832ca67c081", "procName": "insert"}, {"styleid": 19363, "color": "72547", "size": "44", "qty": "1"}]';
--exec web.basketAction_2 @json