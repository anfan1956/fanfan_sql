
--SELECT STRING_AGG('7'+ connect + ':'+ format(RAND()*1000000, '00000#'), ', ') 
--from cust.connect where personid in (34, 4) and connecttypeID=1

if OBJECT_ID('sms.record_individ_p') is not null drop proc sms.record_individ_p
go 
create proc sms.record_individ_p
	@sms_text varchar(255), 
	@customers dbo.id_type readonly, 
	@clientid int,
	@userid int, 
	@cost money,
	@note varchar(max) OUTPUT, 
	@expires DATE, 
	@discount DECIMAL (4,3),
	@singleCode BIT = 'False'

as
BEGIN
	set nocount on;
	if OBJECT_ID('temp.phones') is not null drop table temp.phones;
	create table temp.phones (personid int, phone varchar(50), code char(6))
	declare @number int = (select count (id) from @customers);
	declare @i int =0;

	while @number > @i
		begin
			insert temp.phones (personid, phone, code)
			select p.personID, c.connect, 
				format( rand()*1000000, '00000#') code 
			from cust.persons p
				join cust.connect c on c.personID=p.personID
				join @customers cu on cu.Id=p.personID
			where c.connecttypeID=1
			order by p.personID
			offset @i rows
			fetch next 1 rows only;
			set @i = @i+1;
		end

	declare @smsid int;
	
	insert sms.instances(smstext,smsdate, senderid, userid, cost, singlePromo, expirationDate, discount)
	select @sms_text, CURRENT_TIMESTAMP	, @clientid, @userid, @cost * @number, 'False', @expires, @discount;
	set @smsid= SCOPE_IDENTITY();
	--select * from sms.instances where smsid=@smsid;

	insert sms.customers (smsid, customerid, phone, promocode)
		select @smsid, p.personid, p.phone, p.code from temp.phones p

	select @note =
		STRING_AGG(CONVERT(VARCHAR(MAX), '7'+ phone + ':' + code), ', ') 
	from temp.phones
END
go 

set nocount on;
declare @sms_text varchar(255) = 'Sale in FANFAN. Your promocode:';
declare @cost money = 3.62;
declare @customers dbo.id_type, @note varchar(max), @clientid int =179, @userid int =1, 
	@expires date = '20220801', @discount DECIMAL(4, 3)= 0.15; 
insert @customers values (4),(34),(17338);
exec sms.record_individ_p @sms_text, @customers, @clientid, @userid, @cost, @note OUTPUT, @expires, @discount;
select @note;

select * from sms.customers
select * from temp.phones
select * from sms.instances

IF OBJECT_ID('sms.purchase_p') IS NOT NULL DROP PROC sms.purchase_p
GO
CREATE PROCEDURE sms.purchase_p @custmerid INT, @code , @note VARCHAR(MAX) OUTPUT
AS 
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
			THROW 50001, @note, 1
		COMMIT TRANSACTION;
		RETURN @note;
	END TRY
	BEGIN CATCH
		SELECT @note = ERROR_MESSAGE();
		ROLLBACK TRANSACTION;
		RETURN @note;
	END CATCH
GO
		