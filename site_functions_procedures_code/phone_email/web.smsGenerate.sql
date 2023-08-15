if OBJECT_ID('web.sms_log') is not null drop table web.sms_log
go
create table web.sms_log (
	logid int not null identity primary key, 
	phone char(10) not null, 
	smsCode int not null
)

if OBJECT_ID('web.smsGenerate') is not null drop proc web.smsGenerate
go 
create proc web.smsGenerate @phone char(10) as
set nocount on;
	declare @code table (code int); 
	declare @r int;

	insert web.sms_log(phone, smsCode)
	output inserted.smsCode into @code
	select @phone, code
	from cmn.random_5

	select @r = (select code from @code)
	return @r
go

declare @phone char(10) = '9167834248', @r int; exec @r = web.smsGenerate @phone; select @r
go
declare @phone char(10) = '9167834248', @r int;
select *from web.sms_log where phone = @phone order by logid desc

select top 1 smsCode from web.sms_log where phone = '9167834248' order by logid desc