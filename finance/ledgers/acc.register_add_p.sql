USE [fanfan]
GO
/****** Object:  StoredProcedure acc.register_add_p    Script Date: 31.12.2022 12:41:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [acc].[register_add_p] 
	@bank varchar(50), 
	@currency char(3), 
	@account char (20), 
	@client varchar (50), 
	@note varchar(max) output, 
	@date date, 
	@user varchar(50)
as
set nocount on;
begin;
	declare 
		@rows int, 
		@userid int = (select p.personID from org.persons p where p.lfmname = @user),
		@registerid int;
	declare @registers table (registerid int);
	with s (bankid, currencyid, account, clientid) as (
		select org.contractor_id(@bank), cmn.currency_id(@currency), @account, org.contractor_id(@client)
	)
	merge acc.registers as t using s
	on t.account =  s.account
	when not matched then 
		insert (bankid, currencyid, account, clientid)
		values (bankid, currencyid, account, clientid)
		output inserted.registerid into @registers;

	select @rows = @@ROWCOUNT;
	
	if (@rows = 0)
		select @note = 'регистр уже был занесен'
	else
		select @registerid = registerid from @registers;
		insert acc.beg_entries(entrydate, registerid, amount, bookkeeperid)
		values (@date, @registerid, 0, @userid);
		select @note = 'счет ' + @account + ' в банке ' + @bank + ' для плательщика ' + @client + ' добавлен в регистр'
end 
go

--declare @note varchar(max); exec acc.register_add_p 'АЛЬФА-БАНК', 'RUR', '40802810201070000802', 'ИП ФЕДОРОВ', @note output, '20221228', 'ПИКУЛЕВА О. Н.'; select @note;
select * from acc.beg_entries