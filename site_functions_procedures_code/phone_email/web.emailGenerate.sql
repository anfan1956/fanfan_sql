if OBJECT_ID('web.email_log') is not null drop table web.email_log
go
create table web.email_log (
	logid int not null identity primary key, 
	email varchar(50) not null, 
	emailCode int not null
)

if OBJECT_ID('web.emailGenerate') is not null drop proc web.emailGenerate
go 
create proc web.emailGenerate @email varchar(50) as
set nocount on;
	declare @code table (code int); 
	declare @r int;

	insert web.email_log(email, emailCode)
	output inserted.emailCode into @code
	select @email, code
	from cmn.random_5

	select @r = (select code from @code)
	return @r
go

declare @email varchar(50) = 'af.fanfan.2012@gmail.com', @r int; exec @r = web.emailGenerate @email; select @r
go
declare @email varchar(50) = 'af.fanfan.2012@gmail.com', @r int;
select *from web.email_log where email = @email order by logid desc;
with s as (
	select *, ROW_NUMBER() over(partition by email order by logid desc) num
	from web.email_log 
)
select * from s order by num, email
select top 1 emailCode from web.email_log where email = 'af.fanfan.2012@gmail.com' order by logid desc