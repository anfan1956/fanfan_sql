if OBJECT_ID('web.promo_log') is not null drop table web.promo_log
if OBJECT_ID('web.promo_events') is not null drop table web.promo_events
create table web.promo_events (
	eventid int not null identity primary key, 
	datestart date not null,
	datefinish date not null,
	comment varchar(250) null,
	discount decimal (4,3) not null default (0), 
	scope_global bit 
);

insert web.promo_events (datestart, datefinish, comment, discount, scope_global)
select getdate(), DATEADD(dd, 3, GETDATE()), 'test', .1, 'True'

select * from web.promo_events;

create table web.promo_log (
	logid int not null identity primary key, 
	eventid int not null foreign key references web.promo_events(eventid),
	custid int not null foreign key references cust.persons (personid),
	promocode char(6) not null, 
	used bit default('False'),
	logtime datetime not null default (current_timestamp)

)

if OBJECT_ID ('web.promo_p') is not null drop proc web.promo_p
go
create proc web.promo_p @phone char(10), @note varchar(max) output 
as
	set nocount on;

begin try
	begin transaction;
		declare @code char(6) = (select code from cmn.random_6)
		declare @custid int;
		declare @datefinish date;

-- не забыть подумать о том, если события будут пересекаться
		declare @eventid int = 
			(select top 1 eventid from web.promo_events p
				where cast(getdate() as date) between p.datestart and p.datefinish
			)
		select @datefinish = p.datefinish from web.promo_events p where p.eventid= @eventid

		select @custid = cust.customer_id(@phone);
		if @custid is not null 
		begin
			insert web.promo_log (eventid, custid, promocode) select @eventid, @custid, @code;
			select @note = 'ваш промокод: ' + @code + ', действует до '  + FORMAT(@datefinish, 'dd.MM.yyyy') ;
		end;
--		throw 50001, @note, 1;
	commit transaction
end try

begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
	
	
go

--set nocount on;declare @phone char (10) ='9637633465', @note varchar(max);exec web.promo_p @phone, @note output; select @note
select * from web.promo_log

