USE fanfan
go

if OBJECT_ID ('sms.instance_results_p') is not null drop proc sms.instance_results_p
IF TYPE_ID('sms.results_type') IS NOT NULL DROP TYPE sms.results_type
CREATE TYPE sms.results_type AS TABLE (
	phone varchar(13) NOT NULL,
	code VARCHAR(6) NULL,
	cost MONEY null
)
go

create proc sms.instance_results_p @sms_id INT, @results sms.results_type READONLY, @note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin TRANSACTION
		INSERT sms.instances_customers (smsid, customerid, promocode, cost)	
		SELECT @sms_id, p.customerid, r.code, r.cost
		FROM @results r
			JOIN sms.phones p ON p.phone=r.phone;
		DECLARE @rows_inserted INT = @@rowcount;

	set @note = 'отправлено СМС сообщений: ' + CAST(@rows_inserted AS VARCHAR(MAX));

--	;throw 50001, @message, 1
	commit TRANSACTION
--	RETURN @note;
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback TRANSACTION

end catch
go
		

set nocount on; declare @note varchar (max), @sms_id INT = 1;
DECLARE @results sms.results_type;
INSERT @results VALUES 
(79637633465,4209,3.62), 
(79167834248,8853,2.8),
(789520,7928,null),
(79857278054,5415,2.8)
--; EXEC sms.instance_results_p @sms_id, @results, @note output; select @note note
