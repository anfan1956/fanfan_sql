use fanfan
go

-- DO NOT RUN DROP TABLE IF ACTIVE!!!
-------------------------------------------------------------------------------------

if OBJECT_ID('cust.customer_update_log') is not null 
	begin
		if (select count(*) from cust.customer_update_log)<2
			begin
				drop table cust.customer_update_log 

				create table cust.customer_update_log (
					logid int not null identity constraint pk_cust_upd_log primary key,
					log_timecode datetime default current_timestamp,
					customerid int not null constraint fk_cust_upd_log foreign key references cust.persons (personid),
					phone_old char (10) not null,
					phone_new char (10) not null,
					personid int not null constraint fk_custlog_users foreign key references org.users (userid), 
					succeded bit not null default 'false', 
					divisionid int not null constraint fk_custlog_divisions foreign key references org.divisions (divisionid), 
				)
			end 
	end
--select * from cust.customer_update_log;

--- PROCEDURE!!
--------------------------------------------------------------------------------------------------------------------------------------------------
if OBJECT_ID('cust.customer_update_p') is not null drop proc cust.customer_update_p
go
create proc cust.customer_update_p 
	@phone char(10), 
	@new_phone char(10), 
	@code char(6), 
	@userid int, 
	@divisionid int,
	@note varchar(max) output
as 
	set nocount on; 
	declare @customerid int, @logid int;;

	begin try
		begin transaction;
			if OBJECT_ID('temp.cust_update_t') is null			
				throw 50001, 'клиента с таким номером телефона не существует', 1;
				--select 'STOP'
				select @customerid = c.personID  from cust.connect c 
					join temp.cust_update_t t on t.customerid=c.personID and t.code=@code
				where c.connecttypeID = 1 and c.connect = @phone

				if @customerid is not null
					begin
						insert cust.customer_update_log
							(customerid, phone_old, phone_new, personid, succeded , divisionid)
						select @customerid, @phone, @new_phone, @userid, 'True',  @divisionid;

						select @logid = SCOPE_IDENTITY();

						update c set c.connect = @new_phone
						from cust.connect c where c.personID = @customerid and c.connecttypeID =1;

						select @note = '“елефон обновлен'
					end 
				else 
					select @note = 'Ќеверный код подтверждени€';
				if OBJECT_ID('temp.cust_update_t') is not null drop table temp.cust_update_t;

			--	--throw 500001, 'debuging', 1
		commit transaction
		return @logid;
	end try
	begin catch
		select @note  = ERROR_MESSAGE();
		rollback transaction;
		return -1;
	end catch
go


-------------------------------------------------------------------------------------
if OBJECT_ID('cust.cust_update_try_p') is not null drop proc cust.cust_update_try_p
go
create proc cust.cust_update_try_p 
	@phone char(10), 
	@new_phone char(10), 
	@code char(6), 
	@note varchar(max) output
as
	set nocount on ;
	declare @customerid int, @r int;
	begin try
		begin transaction 
			if OBJECT_ID('temp.cust_update_t') is not null drop table temp.cust_update_t

			create TABLE temp.cust_update_t (
					customerid int not null, 
					new_phone char(10),
					code char (6) not null,
					try_time datetime default current_timestamp
				);

			select @customerid = c.personID  from cust.connect c 				
			where c.connecttypeID = 1 and c.connect = @phone;
			
			if @customerid is  null 
				begin;
					throw 50001, 'клиента с таким номером телефона не существует ',1
				end

				insert temp.cust_update_t (customerid, new_phone, code)
				select @customerid, @new_phone, @code;
				select @r = @@ROWCOUNT;
				
				select @note = 'контрольна€ запись сделана'
		commit transaction;
		return @r
	end try
	begin catch;
		select @note = ERROR_MESSAGE();
		rollback transaction
		return -1;
	end catch;
go

declare @r int, @note varchar(max), 
	@phone char (10) ='9637633465', @new_phone char(10) = '9637633466' ;
exec @r = cust.cust_update_try_p
	@phone = @phone,
	@new_phone = @new_phone,
	@code ='124585',
	@note = @note output;
select @r return_number, @note note;
--if OBJECT_ID('temp.cust_update_t') is not null select * from temp.cust_update_t;

--declare @note varchar(max), @r int;
exec @r = cust.customer_update_p 
	@phone = @phone,
	@new_phone = @new_phone, 
	@code = '124585', 
	@userid = 10,
	@divisionid = 18,
	@note  = @note output; 
select @r return_code, @note note;
select * 
from cust.connect c where c.personID = 4 and c.connecttypeID =1;

select * from cust.customer_update_log;
