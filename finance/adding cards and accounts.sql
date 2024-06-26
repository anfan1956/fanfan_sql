USE [fanfan]
GO

select * from acc.registers r
	join org.contractors c on c.contractorID=r.bankid
	join org.contractors c2 on c2.contractorID= clientid

if OBJECT_ID('acc.bankcards_update_p') is not null drop proc acc.bankcards_update_p
go
create proc acc.bankcards_update_p 
	@bank varchar(50), 
	@holder varchar (50), 
	@name_on_card varchar(50), 
	@valid char(7), 
	@cardnumber char (16), 
	@account char(20),
	@note varchar(max) output
as
	set nocount on;
	declare @records int;

	
	with s (cardnumber, valid, holderid, name_on_card, bankid, account) as (
		select @cardnumber, @valid, org.person_id(@holder), @name_on_card,org.contractor_id(@bank), @account
	)
	merge acc.bankcards as t using s 
	on t.cardnumber = s.cardnumber
	when matched and 
		t.valid<>s.valid or
		t.holderid<>s.holderid or
		t.name_on_card<>s.name_on_card or
		t.bankid <> s.bankid or
		t.account<>s.account 

	then update set 
		t.valid=s.valid,
		t.holderid=s.holderid,
		t.name_on_card=s.name_on_card,
		t.bankid = s.bankid,
		t.account = s.account
	when not matched then 
		insert  (cardnumber, valid, holderid, name_on_card, bankid, account)
		values  (cardnumber, valid, holderid, name_on_card, bankid, account);
	select @records =@@ROWCOUNT;

	if @records > 0 
		select @note = 'сделана ' + cast(@records as varchar(1)) + ' запись'
	else select @note = 'карта уже была в реестре'
go

declare @note varchar(max);
--exec acc.bankcards_update_p 'ТИНЬКОФФ', 'ФЕДОРОВ А. Н.', 'ALEKSANDR FEDOROV', '10/2029', '5280413752350988', '40817810900014646072', @note output;select @note;
--exec acc.bankcards_update_p 'ТИНЬКОФФ', 'ПИКУЛЕВА О. Н.', 'ОЛЬГА П.', '10/2028', '1084108410841084', '40817810900014646072', @note output;select @note;
--exec acc.bankcards_update_p 'ТИНЬКОФФ', 'ИП ФЕДОРОВ', 'Dmitriy Petrov', '06/2029', '5534200039928866', '40802810700002267131', @note output;select @note;

select * from acc.bankcards
if OBJECT_ID('acc.names_on_card_f') is not null drop function acc.names_on_card_f
go
create function acc.names_on_card_f(@bank varchar (50), @client varchar (50)) returns table as return

select distinct b.name_on_card, b.cardnumber, b.account
from acc.registers r
	join acc.bankcards b on b.account= r.account
where 
	r.bankid = org.contractor_id(@bank) and 
	r.clientid = org.contractor_id(@client)
go
	declare @bank varchar(50) = 'ТИНЬКОФФ', @client varchar (50) = 'ФЕДОРОВ А. Н.'
select name_on_card, cardnumber from acc.names_on_card_f(@bank, @client)

declare @holder varchar(50) = 'Петров Д. С.'
select  org.person_id(@holder)
select holder from acc.bank_account_holders_v order by 1


select * from org.users where username like 'Петро%'