if OBJECT_ID('web.promo_styles_discounts') is not null drop table web.promo_styles_discounts
if OBJECT_ID('web.promo_log') is not null drop table web.promo_log
if OBJECT_ID('web.promo_events') is not null drop table web.promo_events

--if discount is not null then event is global and provides the discount for all styles
create table web.promo_events (
	eventid int not null identity primary key, 
	datestart date not null,
	datefinish date not null,
	comment varchar(250) null,
	discount decimal (4,3) null, 
	eventClosed bit not null default(0)
	
);

--insert web.promo_events (datestart, datefinish, comment, discount)
--select getdate(), DATEADD(dd, 3, GETDATE()), 'testing the global', .2

create table web.promo_log (
	logid int not null identity primary key, 
	eventid int not null foreign key references web.promo_events(eventid),
	styleid int constraint fk_promo_log_styles foreign key references inv.styles (styleid), 
	custid int not null foreign key references cust.persons (personid),
	promocode char(6) not null, 
	used bit default('False'),
	logtime datetime not null default (current_timestamp)
)


create table web.promo_styles_discounts (
	eventid int not null constraint fk_promo_styles_events foreign key references web.promo_events (eventid), 
	styleid int not null  constraint fk_promo_styles_styles foreign key references inv.styles (styleid), 
	discount dec(4,3) not null
)

if OBJECT_ID('web.promo_event_create') is not null drop proc web.promo_event_create
go
create proc web.promo_event_create 
	@info inv.barcodes_discounts_type readonly,
	@eventid int,
	@datestart date, 
	@datefinish date, 
	@comment varchar(150),
	@discount dec (4,3) = null, 
	@note varchar(max) output
as	
-- the actually  not only creates the proc but also merges the styles
set nocount on;
	declare 
		@rows_affected int, 
		@r int; 
	declare @TBL table (act varchar(20));
	
	--select @eventid = w.eventid from web.promo_events w 
	--where @datefinish = w.datefinish
	if @eventid <>0
		begin;
			with s (eventid, styleid, discount) as (
				select @eventid, i.styleid, i.discount
				from @info i
			)
			merge web.promo_styles_discounts as t using s
			on 
				t.eventid = s.eventid and
				t.styleid = s.styleid
			when matched  and
				t.discount<>s.discount
			then update set
				t.discount = s.discount
			when not matched then 
				insert (eventid, styleid, discount)
				values (eventid, styleid, discount)
			when not matched by source and t.eventid = @eventid
				then delete
			OUTPUT $action INTO @TBL;

			select @rows_affected = count(*) from @TBL;

			select @note = 'eventId ' + cast(@eventid as varchar(max)) + ' existed with the same finish date. ' +  
				cast(@rows_affected as varchar(max)) + ' rows affected';
			return @eventid;
		end 

		insert web.promo_events (datestart, datefinish, comment, discount)
			select @datestart, @datefinish, @comment, @discount;
	
		select @eventid = SCOPE_IDENTITY();
	
		insert web.promo_styles_discounts (eventid, styleid, discount)
		select @eventid, i.styleid, i.discount
		from @info i
		select @note = 'eventId ' + cast(@eventid as varchar(max)) + ' created.'
		return @eventid;
go

set nocount on; 
declare 
	@r int,
	@datestart date = getdate(), 
	@datefinish date = dateadd(dd, 5, getdate()),
	@comment varchar(150) = 'global discount test', 
	@note varchar(max);
declare
	@info inv.barcodes_discounts_type;
insert @info (styleid, discount)	
values (19996, .2), (19354, .25); 

--exec @r = web.promo_event_create 
--	@info=@info, 
--	@datestart= @datestart,
--	@datefinish = @datefinish, 
--	@comment = @comment, 
--	@note = @note output;

--select @r, @note


	
if OBJECT_ID ('web.promo_p') is not null drop proc web.promo_p
go
create proc web.promo_p 
	@phone char(10), 
	@styleid int, 
	@note varchar(max) output 
as
	set nocount on;

begin try
	begin transaction;
		declare @code char(5) = (select code from cmn.random_5)
		declare 
			@custid int, 
			@discount dec(4,3),
			@datefinish date,
			@prString as varchar(max);

-- не забыть подумать о том, если события будут пересекаться
		declare @eventid int = (
			select top 1 p.eventid 
			from web.promo_events p
				join web.promo_styles_discounts ps on ps.eventid=p.eventid
			where cast(getdate() as date) between p.datestart and p.datefinish
				and ps.styleid =@styleid
			);		

		if @eventid is not null
			begin
				select @datefinish = 
					p.datefinish 
					from web.promo_events p 
					where p.eventid= @eventid;

				select @prString = 
					--concat('бренд: ' + b.brand, ';  артикул:' + s.article) 
					--from inv.styles s
					--	join inv.brands b on b.brandID=s.brandID
					--where s.styleID = @styleid
					concat(b.brand, ' модель ' + cast(@styleid as varchar(max))) 
					from inv.styles s
						join inv.brands b on b.brandID=s.brandID
					where s.styleID = @styleid

				select @custid = cust.customer_id(@phone);
			
				if @custid is not null 
				begin
					select @discount =
						w.discount
						from web.promo_styles_discounts w
						where w.eventid= @eventid 
							and w.styleid=@styleid

					insert web.promo_log (eventid, styleid, custid, promocode) 
					select @eventid, @styleid, @custid, @code
					from web.promo_styles_discounts w;

					select @note = 'доп -' + format (@discount, '#,##0%' ) + ' код ' + @code + ' до '  + FORMAT(@datefinish, 'dd.MM.yy') + ': ' + @prString  ;
				end;
			end
		else select @note = 'сейчас на этот артикул промокода нет'
--		throw 50001, @note, 1;
	commit transaction
end try

begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch	
go

set nocount on;declare @phone char (10) ='9167834248', @note varchar(max), @styleid int = 19354;
--exec web.promo_p @phone = @phone, @styleid = @styleid, @note =@note output; select @note
exec web.promo_p @phone, @styleid, @note output; select @note
select * from web.promo_log
select * from web.promo_events
select * from web.promo_styles_discounts

--select * from cust.connect p where p.personID = 12 ;select * from hr.emps_on_duty_f('20230316', '08 ФАНФАН');
