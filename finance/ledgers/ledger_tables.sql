use fanfan
go



--if OBJECT_ID ('acc.journals') is not null drop table acc.journals
--create table acc.journals (
--	jouranlid int not null identity primary key,
--	journal varchar (25) not null unique
--)
--if OBJECT_ID ('acc.accounts') is not null drop table acc.accounts
--if OBJECT_ID('acc.groups') is not null drop table acc.groups
--create table acc.groups (
--	groupid int not null identity primary key,
--	group_name varchar (25) not null unique
--)
--create table acc.accounts (
--	accountid int not null identity primary key,
--	account varchar(50) not null unique,
--	groupid int not null constraint fk_accounts_groups foreign key references acc.groups (groupid)
--)

--if OBJECT_ID ('acc.transactions') is not null drop table acc.transactions
--if OBJECT_ID ('acc.trans_types') is not null drop table acc.trans_types
--create table acc.trans_types (
--	trans_typeid int not null primary key,
--	trans_type varchar (255) not null
--)

--create table acc.transactions (
--	transactionid int not null identity primary key,
--	transaction_date date not null, 
--	trans_typeid int not null constraint fk_acc_transactions_types foreign key references acc.trans_types (trans_typeid),
--	recorded datetime default (current_timestamp),
--	clientid int not null constraint fk_acc_transactions_clients foreign key references org.clients (clientid),
--	userid int not null  constraint fk_acc_transactions_users foreign key references org.persons (personid)

--)

--insert acc.groups (group_name) values 
--('активы'), 
--('пассивы'), 
--('взаиморасчеты'), 
--('соб.средства'), 
--('доходы'), 
--('с/ст.'), 
--('Расходы')
--;
--insert acc.accounts (account, groupid) values
--('деньги', 1),
--('товар', 1),
--('ОС', 1),
--('депозиты', 1),
--('авансы', 1),
--('подотчет', 1),
--('счета к оплате', 2),
--('зарплата к оплате', 2),
--('кредиты и ссуды', 2),
--('долги', 2),
--('взаиморасчеты', 3),
--('НППП', 4),
--('Выручка', 5),
--('Себестоимость', 6),
--('зарплата', 7),
--('аренда', 7),
--('МБП и ремонт', 7),
--('Маркетинг', 7),
--('Фин.расходы', 7)

--if OBJECT_ID('acc.registers') is not null drop table acc.registers
--create table acc.registers (
--	registerid int not null identity primary key,
--	divisionid int not null constraint fk_registers_divisions foreign key references org.divisions (divisionid),
--	is_public bit default 'False',
--	currencyid int not null constraint fk_registers_currencys foreign key references cmn.currencies (currencyid),
--	constraint uq_acc_registers unique (divisionid, is_public)

--)

--if OBJECT_ID ('acc.articles') is not null drop table  acc.articles
--create table acc.articles (
--	articleid int not null identity primary key,
--	article varchar (150) not null unique,
--	accountid int not null constraint fk_articles_accounts references acc.accounts (accountid)
--)

--select * from acc.accounts

--insert acc.articles values ('бензин', 21)
--select * from acc.articles

--if OBJECT_ID('acc.vendors') is not null drop table acc.vendors
--create table acc.vendors (
--	vendorid int not null constraint fk_contr_acc_vendors foreign key references org.contractors (contractorid),
--	currencyid int not null constraint fk_currency_acc_vendors  foreign key references cmn.currencies (currencyid),
--	constraint pk_acc_vendors primary key (vendorid, currencyid)
--)



if OBJECT_ID ('acc.vendor_create_p') is not null drop proc acc.vendor_create_p
go
create proc acc.vendor_create_p @vendor varchar (50), @currency char(3), @note varchar(max)  output as
set nocount on
begin try
	begin transaction
	declare @vendorid int ;
	select @vendorid = contractorid from org.contractors where contractor = @vendor;
	if @vendorid is null 
		begin
			insert org.contractors (contractor) values (upper(@vendor));
			select @vendorid= SCOPE_IDENTITY();
		end
	insert acc.vendors (vendorid, currencyid) values(@vendorid, cmn.currency_id(@currency));
	select @note = 'добавлен поставщик: ' + upper(@vendor) + ', валюта: ' + @currency;
	--throw 50001, @note, 1;
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE();
	rollback transaction;
end catch
go


if OBJECT_ID ('acc.article_create_p') is not null drop proc acc.article_create_p
go
create proc acc.article_create_p @article varchar (150), @account varchar(50), @note varchar(max)  output as
set nocount on
begin
	declare @articleid int, @accountid int  ;
	select @articleid = articleid from acc.articles where article = @article;
	if @articleid is null 
		begin;
			with _accountid as (select accountid from acc.accounts where account= @account )
			insert acc.articles(article, accountid) select upper(@article), accountid from _accountid;
			select @articleid= SCOPE_IDENTITY();
			select @note = 'добавлена статья: ' + upper(@account) + ', кор. счет: ' + @account;
		end
	else
		select @note = 'статья уже в списке статей'
end

go

--declare @note varchar (max); exec acc.vendor_create_p 'РУССКАЯ ТРАНСПОРТНАЯ КОМПАНИЯ. ООО', 'RUR', @note output; select @note

select * from acc.vendors
select a.article, ac.account from acc.articles a join acc.accounts ac on ac.accountid=a.accountid
--declare @note varchar(max); exec acc.article_create_p 'обслуживание автотранспорта', 'транспорт', @note output; select @note

if OBJECT_ID('acc.accchart_v') is not null drop view acc.accchart_v
go
create view acc.accchart_v as
select a.account, g.group_name, a.accountid
from acc.accounts a
	join acc.groups g on g.groupid=a.groupid
go

select group_name, account from acc.accchart_v order by accountid

if OBJECT_ID('pmt.client_bank_accounts_f') is not null drop function pmt.client_bank_accounts_f
go
create function pmt.client_bank_accounts_f(@client varchar (50)) returns table as return
select distinct
	cn.contractor bank, r.account
from pmt.registers r 
	join org.banks b on b.bankID=r.bankid
	join org.clients c on c.clientID=r.clientid
	join org.contractors cn on cn.contractorID=r.bankid
where c.clientRus = @client
go

if OBJECT_ID('org.contractors_cleared_v') is not null drop view org.contractors_cleared_v
go
create view org.contractors_cleared_v as
with s as (
	select contractor, p.lastname, c.contractorID
	from  org.persons p
	join org.contractors c on p.lastname = left(c.contractor, len(p.lastname))
	where p.lastname <>''
)
select contractor from org.contractors 
except select divisionfullname from org.divisions 
except select contractor from s
go

