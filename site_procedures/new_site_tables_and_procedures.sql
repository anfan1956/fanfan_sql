--select * from cust.registrations; --select * from cust.users

--if OBJECT_ID ('tmp.customers') is not null drop table tmp.customers
--go
--create table tmp.customers (
--	custid int not null identity,
--	custname varchar(50), 
--	lastname varchar (50),
--	phone char(10) unique, 
--	email varchar(50)
--)

--if object_id ('tmp.customer_registrations') is not null drop table tmp.customer_registrations
--create table tmp.customer_registrations (
--	regid int not null identity primary key,
--	custname varchar(50), 
--	lastname varchar (50),
--	phone char(10) unique, 
--	email varchar(50), 
--	status bit null,
--	regtime datetime not null default current_timestamp,
--	code char(6) not null
--)


if OBJECT_ID ('tmp.cust_register_p') is not null drop proc tmp.cust_register_p
if type_ID ('tmp.cust_string_type') is not null drop type tmp.cust_string_type
create type tmp.cust_string_type as table (
	custname varchar(50),
	lastname varchar(50), 
	phone char(10),
	email varchar(50), 
	regtime datetime
)
go

create proc tmp.cust_register_p 
	@reg_string tmp.cust_string_type readonly,
	@note varchar(max) output 
as
set nocount on;
	begin ;
		declare @email varchar(50) = (select email from @reg_string);
		declare @phone char(10)  = (select phone from @reg_string);
		declare @regtime datetime  = (select regtime from @reg_string);
		declare @code char(6) = (select code from cmn.random_6);
		declare @regid int = (select r.regid from tmp.customer_registrations r where r.phone = @phone and status is null);
	
		--check if email is already registered
		if exists (select * from tmp.customers c where c.email = @email)			
			begin
				select @note =  @email +  ' - этот адрес уже зарегистрирован'
				return 
			end ;
		
		--check if phone is already registered
		if exists (select * from tmp.customers c where c.phone = @phone)			
			begin
				select @note = format (cast(@phone as bigint), '+7-(###)-###-####')  +  ' - этот телефон уже зарегистрирован'
				return 
			end ;

			--create customer registration attemp			
			with s (custname, lastname, phone, email, regtime, code) as (
				select custname, lastname, @phone, @email, @regtime, @code
				from  @reg_string
			)
			merge tmp.customer_registrations as t using s on t.phone= s.phone
			when matched then update set 
				custname = s.custname, 
				lastname = s.lastname, 
				email = s.email,
				regtime = s.regtime,
				code = s.code
			when not matched then insert (custname, lastname, phone, email, regtime, code)
			values (custname, lastname, phone, email, regtime, code);
			select @note = 'код регистрации - ' + @code;
	end 
go

if OBJECT_ID('tmp.customer_confirmations') is not null drop proc tmp.customer_confirmations
go
create proc tmp.customer_confirmations @code char (6), @note varchar(max) output as
	set nocount on;
	begin
		declare @time datetime = current_timestamp;
		declare @regid int = (select regid from tmp.customer_registrations r 
			where r.code = @code  
			and datediff(MINUTE, r.regtime, @time) < 1000
			);
		declare @phone char(10) = (select  phone from tmp.customer_registrations r where r.code = @code )
		if @regid is null 
			begin 
				select @note = 'неверный код регистрации или время истекло '
--				return;
			end 
		else if (select r.status from tmp.customer_registrations r where r.regid = @regid) is not null
			begin
				select @note = 'этот номер телефона уже зарегистрирован'
--				return;
			end 
		else 
			begin
				--update customer registration requests
				update f set status = 'True' from tmp.customer_registrations f
				where f.regid = @regid;

					--add customer to the table
				with  s (custname, lastname, phone, email) as (
					select s.custname, s.lastname, s.phone, s.email
					from tmp.customer_registrations s where s.regid = @regid
				)
				insert tmp.customers (custname, lastname, phone, email)
				select custname, lastname, phone, email
				from  s
				select @note = 'регистрация прошла успешно'
			end 
			select  @note = '7' + @phone + ':' + @note;
	end
go

if OBJECT_ID('tmp.customer_promo_get') is not null drop proc tmp.customer_promo_get
go
create proc tmp.customer_promo_get @phone char(10), @note varchar(max) output as
	begin
		declare @code char(6)
		select @code = r.code from tmp.customers c 
			cross apply (select code from cmn.random_6) as r
		where c.phone= @phone;
		if @code is not null
			select @note  = '7' + @phone + ':' + 'ваш промокод - ' + @code
		else 
			select @note = 'Для получения промокода требуется регистрация'
	end
go



declare 
	@cust_string tmp.cust_string_type,
	@note varchar(max);
	insert @cust_string values  ('Александр', 'Федоров', '9637633465' ,'alexander.n.fedorov@gmail.com', getdate())
--exec tmp.cust_register_p @cust_string, @note output; select @note;
--exec tmp.customer_confirmations '647513', @note output; select @note;
--declare @time datetime = current_timestamp;
--declare @code char(6) = '273460';
--declare @regid int =(select regid from tmp.customer_registrations r 
--			where r.code = @code and datediff(MINUTE, r.regtime, @time) < 10);
--select @regid;
go

select * from tmp.customers
select * from tmp.customer_registrations
--set nocount on; declare @phone char(10), @note varchar(max); exec tmp.customer_promo_get '9167834248', @note output; select @note;
