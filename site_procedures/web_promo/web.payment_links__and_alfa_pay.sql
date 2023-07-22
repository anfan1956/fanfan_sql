use fanfan
go
declare @orderid int =77355;


if OBJECT_ID('web.link_suffix') is not null drop table web.link_suffix
if OBJECT_ID('web.payment_links') is not null drop table web.payment_links
if OBJECT_ID('web.payment_link_states') is not null drop table web.payment_link_states
create table web.payment_link_states (
stateid int not null identity primary key,
linkState varchar(25) 
)
insert web.payment_link_states values ('active'), ('expired'), ('cancelled'), ('executed');
if OBJECT_ID('web.pmtLinkState_id') is not null drop function web.pmtLinkState_id
go

create function web.pmtLinkState_id(@linkState varchar(25)) returns int as 
begin
	declare @stateid int;
	select @stateid = stateid from web.payment_link_states where linkState = @linkState
	return @stateid;
end


go
create table web.payment_links (
	linkid int not null identity primary key, 
	orderid int not null foreign key references inv.site_reservations (reservationid),
	sequenceid int not null, 
	duration int not null, 
	bankid int not null foreign key references org.banks,
	linktime datetime default current_timestamp, 
	stateid int foreign key references web.payment_link_states (stateid)
)

if OBJECT_ID('web.link_prefix') is not null drop table web.link_prefix
go
create table web.link_prefix (
	bankid int not null foreign key references org.banks(bankid),
	dateRecorded datetime default current_timestamp, 
	prefix varchar(250)
)
insert web.link_prefix (bankid, prefix)
values (org.contractor_id('АЛЬФА-БАНК'), 'https://payment.alfabank.ru/payment/merchants/ecom2/payment_ru.html?mdOrder=' )
select * from web.link_prefix;
go

create table web.link_suffix (
	linkid int not null primary key,
	suffix  varchar (100)
)

--select * from web.payment_links

if OBJECT_ID('web.link_generate') is not null drop proc web.link_generate
go
create proc web.link_generate @orderid int, @bankid int, @duration int, @note varchar(max) output as
set nocount on;
	declare @sequence int, @num int, @r int;
	begin try
		begin transaction
			select @sequence =  isnull(l.sequenceid, 0)
			from web.payment_links l where l.orderid = @orderid;
			select @num = case 
				when @sequence is null then 1
				else  @sequence + 1
				end ;
			--select @num;
			insert  web.payment_links (orderid, sequenceid, bankid, duration, stateid) 
			values (@orderid, @num, @bankid, @duration, web.paymentLinkState_id('active'))
			--select * from web.payment_links;
			select @r = SCOPE_IDENTITY();

		select @note = cast(@orderid as varchar(max)) + '/' + cast(@num as varchar(max));
		--throw 50001, @note, 1
		commit transaction
		return @r;
	end try
	begin catch
		select @note= ERROR_MESSAGE()
		rollback transaction
	end catch
go

if OBJECT_ID ('web.suffix_record') is not null  drop proc web.suffix_record
go
create proc web.suffix_record(@string varchar(max)) as
begin
	set nocount on;
	with s(parameter, myOrder)  as (
	select 
		value, 
		ROW_NUMBER() over ( order by len(value))
	from  string_split(@string, ':')
	)
	, t  (sequenceid, orderid, suffix) as (
	select  s.parameter, s1.parameter, s2.parameter
	from s
	cross apply s as s1
	cross apply s as s2
		where s.myOrder = 1
		and s1.myOrder=2
		and s2.myOrder=3
	)
	insert web.link_suffix (linkid, suffix)
	select l.linkid, t.suffix
	from web.payment_links l
		join t on t.sequenceid=l.sequenceid
			and t.orderid=l.orderid
	end 
go
declare @r int, @string varchar(max) = '77376:1:037c6cd4-778d-7bb9-9953-d19300b32438';
--exec @r = web.suffix_record @string; select @r;



--declare @orderid int = 77355, @bankid int = org.contractor_id('АЛЬФА-БАНК'), @duration int = 20, @r int, @note  varchar (max) ;exec @r = web.link_generate @orderid = @orderid, @bankid = @bankid, @duration = @duration, @note = @note output ;select @r, @note;
go
set nocount on; declare @orderid int = 77359, @bankid int = org.contractor_id('АЛЬФА-БАНК'), @duration int = 10, @r int, @note  varchar (max); 
--exec @r = web.link_generate @orderid = @orderid, @bankid = @bankid, @duration = @duration, @note = @note output; select @r, @note;
select l.*, s.linkState from web.payment_links l join web.payment_link_states s on s.stateid=l.stateid
select * from web.link_suffix;
go

--exec web.reservations_clear
select * from web.promo_log where custid = 17448 and used = 0 order by styleid



