/*

		-- DO NOT PUSH THE BUTTON !

*/


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
	discount dec(4, 3) not null,
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

	with s(eventid, datestart, datefinish, comment) as(
		select @eventid, @datestart, @datefinish, @comment		
	)
	merge web.promo_events as t using s
	on t.eventid=s.eventid
	when matched and
		t.datestart<>s.datestart or
		t.datefinish<>s.datefinish or
		t.comment<>s.comment
	then update	set
		t.datestart=s.datestart, 
		t.datefinish=s.datefinish,
		t.comment=s.comment		
	when not matched then insert(datestart, datefinish, comment)
	values (datestart, datefinish, comment);
	if @eventid=0 set @eventid = SCOPE_IDENTITY()
	;

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

	select @note = 'eventId ' + cast(@eventid as varchar(max)) + ' updated. ' +  
		cast(@rows_affected as varchar(max)) + ' rows affected';
	return @eventid;

go

set nocount on; 
declare 
	@r int, 
	@eventid int = 0,
	@datestart date = getdate(), 
	@datefinish date = dateadd(dd, 5, getdate()),
	@comment varchar(150) = 'global discount test', 
	@note varchar(max);
declare
	@info inv.barcodes_discounts_type;
insert @info (styleid, discount)	
values (19996, .2), (19354, .25); 

--exec @r = web.promo_event_create 
--	@eventid = @eventid,
--	@info=@info, 
--	@datestart= @datestart,
--	@datefinish = @datefinish, 
--	@comment = @comment, 
--	@note = @note output;

--select @r, @note


	
