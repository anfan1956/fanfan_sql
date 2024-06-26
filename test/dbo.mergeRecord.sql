use test
go

select name
from sys.tables
--if OBJECT_ID('dbo.entries') is not null drop table dbo.entries
--if OBJECT_ID('dbo.users') is not null drop table dbo.users

--create table dbo.users (
--	userId int identity primary key,
--	userName varchar (max) not null,
--	userPassword varchar (10) default null
--)
--go
--insert dbo.users (userName)
--values ('Александр'), ('Ефим');


--create table dbo.entries (
--entryId int identity primary key, 
--entryDate datetime not null,
--recorded datetime not null default current_timestamp,
--comment varchar(max) not null,
--amount money, 
--userId int not null foreign key references dbo.users (userId)
--)

if OBJECT_ID ('dbo.mergeRecord') is not null drop proc dbo.mergeRecord
go 
create proc dbo.mergeRecord @entryid int, @entryDate date, @comment varchar(max), @amount money, @user varchar(max)
as
set nocount on;
begin;
	with s (entryid, entryDate, comment, amount, userid) as	(
		select @entryId, @entryDate, @comment, @amount, u.userId
		from dbo.users u 
		where u.userName = @user
	)
	merge dbo.entries as t using s
	on t.entryId = s.entryId
	when matched 
		and t.entryDate<>s.entryDate
		or t.comment<>s.comment
		or t.amount<>s.amount
		or t.userid<>s.userid
		then update set 
			t.entryDate=s.entryDate, 
			t.comment=s.comment, 
			t.amount=s.amount,
			t.userid=s.userid, 
			t.recorded = current_timestamp
	when not matched then 
		insert (entryDate, comment, amount, userid)
		values (entryDate, comment, amount, userid)
	;
	declare @num int, @r int;
	select @num =  @@ROWCOUNT
	select 'rows affected: ' + cast (@num as varchar(10))
	select @r = SCOPE_IDENTITY()
	if @entryid<>0 select @r = @entryid;
	return @r;
end
go

declare 
	@r int,
	@entryid int = 0, 
	@entryDate date = '20240505', 
	@comment varchar(max) = 'на Тиньков', 
	@amount money = 2150, 
	@user varchar(max) = 'Ефим'

--exec @r =  dbo.mergeRecord 
--	@entryId=@entryId, 
--	@entryDate = @entryDate, 
--	@comment = @comment, 
--	@amount =  @amount, 
--	@user = @user;
--select @r;
go

if OBJECT_ID('dbo.accountReport_') is not null drop view dbo.accountReport_
go
create view dbo.accountReport_ as


select  e.entryId id, entryDate Дата, comment Комментарий, u.userName Записал, amount Сумма
from entries e
	join users u on u.userId = e.userId

go
select * from accountReport_