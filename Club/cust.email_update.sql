if OBJECT_ID('cust.email_update') is not null drop proc cust.email_update
go
create proc cust.email_update 
	@phone char(10), 
	@email varchar(50), 
	@notify bit= 'False' as
set nocount on;

	declare @custid int = cust.customer_id(@phone);
	declare @note varchar(max);
	
	with s (connect, personid, connecttypeID, notify) as (
		select @email, @custid, 4, @notify
		)
	merge cust.connect as t using s 
	on t.personid = s.personid
		and t.connecttypeID = s.connecttypeID
	when matched and 
		t.connect <> @email or
		t.notify<>s.notify
		then
		update set 
			t.connect = s.connect, 
			t.notify = s.notify
	when not matched  then 
	insert (personid, connecttypeID, connect, prim, active)
	values (personid, connecttypeID, connect, 1,1);
	
	if  (@@ROWCOUNT>0) 
		select 'updated'
	else 
		select 'no change'
go

declare 
	@phone char(10) = '9167834248', 
	@email varchar (max) = 'af.fanfan.2012@gmail.com',
	@notify bit = 'True', 
	@custid int = 17448

--exec cust.email_update '', @email , @notify

select * from cust.connect where connecttypeID = 4 and personID =@custid

select cust.customer_mail(cust.prime_phone_f(@custid))

select cust.customer_mail('9637633465') 
select cust.customer_mail('9167834248')