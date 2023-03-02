--if OBJECT_ID ('sms.promocodes_requests') is not null drop table sms.promocodes_requests
--if OBJECT_ID('sms.promoevents') is not null drop table sms.promoevents
--create table sms.promoevents (
--	eventid int not null identity primary key,
--	datestart date not null,
--	datefinish date not null,
--	details varchar(155) not null,
--	firstdiscount decimal (4,3) not null, 
--	nextdiscount decimal (4,3) null, 
--	eventclosed bit not null default('False'), 
--	constraint uq_promoevents unique (datestart, details)
--)
--go
--create table sms.promocodes_requests (
--	requestid int not null identity primary key, 
--	phoneid int not null foreign key references sms.phones (phoneid),
--	requestdate datetime not null,
--	eventid int not null foreign key references sms.promoevents (eventid),
--	used bit not null default (0),
--	promocode char(6) not null, 
--	discount decimal(4,3) null
--)
if OBJECT_ID('sms.promoevents_merge') is not null drop proc sms.promoevents_merge
if type_ID('sms.promoevents_type') is not null drop type sms.promoevents_type 

create type sms.promoevents_type as table (
	eventid int,
	datestart date ,
	datefinish date,
	details varchar(155),
	firstdiscount decimal (4,3), 
	nextdiscount decimal (4,3), 
	eventclosed bit 
)

go
create proc sms.promoevents_merge @info sms.promoevents_type readonly as
	set nocount on;
	with s  as (
		select * from @info
	)
	merge sms.promoevents as t using s
	on t.eventid = s.eventid 
	when matched then update set
		t.datestart= s.datestart,
		t.datefinish = s.datefinish,
		t.details= s.details, 
		t.firstdiscount = s.firstdiscount,
		t.nextdiscount =  s.nextdiscount,
		t.eventclosed= s.eventclosed
	when not matched then 
	insert 
		(datestart, datefinish, details, firstdiscount, nextdiscount, eventclosed)
	values 
		(datestart, datefinish, details, firstdiscount, nextdiscount, eventclosed)
	when not matched by source then delete;

go


if OBJECT_ID('sms.promo_discount_f') is not null drop function sms.promo_discount_f
go
create function sms.promo_discount_f (@promocode varchar(6), @customerid int ) returns dec(4,3) as
	begin 
		declare @discount dec(4,3)
		select @discount = discount 
		from sms.instances i
		join sms.instances_customers ic on ic.smsid= i.smsid
		where customerid= @customerid and ic.promocode =  @promocode 
			and i.expirationDate >= cast(getdate()as date)
		return @discount;
	end 
go

if OBJECT_ID ('sms.promocode_request') is not null drop proc sms.promocode_request
go
create proc sms.promocode_request (@customerid int, @note varchar(max) output) as
set nocount on; 
	begin

		declare @date date = getdate(), @datetime datetime = current_timestamp;
		declare @phoneid int = sms.phone_id(@customerid);
		if  @phoneid is null
			begin
				select @note = 'unknown customer'
				return
			end
		declare @eventid int = ( 
				select e.eventid from sms.promoevents e
				where e.datestart <=@date 
					and e.datefinish>= @date
					and eventclosed = 'False' )

		declare @code char(6) = (select code from cmn.random_6)

		declare @firstdiscount dec(4,3), @nextdiscount dec (4,3);

		select @firstdiscount = firstdiscount, @nextdiscount = nextdiscount
			from sms.promoevents where eventid=@eventid 

		declare @qty int;
		
		select @qty = count(requestid) from sms.promocodes_requests 
			where eventid = @eventid and phoneid = @phoneid;

		if @qty = 0 
			insert sms.promocodes_requests (phoneid, requestdate, eventid, used, promocode, discount) values (@phoneid, @datetime, @eventid, 'False', @code, @firstdiscount);

		if @qty = 1 
			begin 
				if (select used from sms.promocodes_requests  where eventid = @eventid and phoneid = @phoneid ) = 'FALSE'
					update r set r.promocode = @code, r.requestdate = @datetime from sms.promocodes_requests r  where eventid = @eventid and phoneid = @phoneid;
				if (select used from sms.promocodes_requests  where eventid = @eventid and phoneid = @phoneid ) = 'TRUE'
					insert sms.promocodes_requests (phoneid, requestdate, eventid, used, promocode, discount) 
					values (@phoneid, @datetime, @eventid, 'False', @code, @nextdiscount);
			end 
		else 
				with s (requestid, num) as (select r.requestid, ROW_NUMBER() over (order by r.requestid desc) 
					from sms.promocodes_requests r where eventid = @eventid and phoneid = @phoneid
				)
				--select * from s;
				update r set r.promocode = @code, used = 'FALSE' , r.requestdate = @datetime
				from sms.promocodes_requests r  
					join s on s.requestid =r.requestid
				where eventid = @eventid and phoneid = @phoneid and s.num = 1;
		
		select @note = @code;
	end
go


if OBJECT_ID('sms.phone_id') is not null drop function sms.phone_id
go
create function sms.phone_id(@customerid int) returns int as 
	begin
		declare @phoneid int
		select @phoneid = phoneid from sms.phones p where p.customerid = @customerid
		return @phoneid
	end
go


--insert sms.promoevents (datestart, datefinish, details, firstdiscount, nextdiscount)
--values (getdate(), '20230228', 'multi use event', .3, .05);


declare 
	@phoneid int = 6577, 
	@date date = getdate();
--update r set r.used = 'True' from sms.promocodes_requests r where requestid= 1;
--declare @customerid int = 17425, @note varchar(max); exec sms.promocode_request @customerid, @note output; select @note;
select * from sms.promoevents
select * from sms.promocodes_requests


