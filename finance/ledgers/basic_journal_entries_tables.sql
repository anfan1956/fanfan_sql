use fanfan
go 



if OBJECT_ID ('acc.entries') is not null drop table acc.entries
if OBJECT_ID('acc.transactions') is not null drop table acc.transactions

create table acc.transactions (
	transactionid int not null identity primary key,
	transdate date not null,
	recorded datetime not null default( getdate()), 
	bookkeeperid int not null constraint fk_bookkeper foreign key references org.users (userid), 
	currencyid int not null constraint fk_trans_currencies foreign key references cmn.currencies(currencyid),
	articleid int not null constraint fk_trans_articles foreign key references acc.articles (articleid),
	clientid int not null constraint fk_trans_clients foreign key references org.contractors (contractorid), 
	amount money not null,
	comment varchar(150)
)
create table acc.entries (
	entryid int not null identity primary key,
	transactionid int not null constraint fk_entries_trans foreign key references acc.transactions (transactionid),
	is_credit bit not null,
	accountid int not null constraint fk_entries_accounts foreign key references acc.accounts (accountid),
	contractorid int null constraint fk_entries_contractors foreign key references org.contractors (contractorid), 
	personid int null constraint fk_entries_persons foreign key references org.persons (personid),
	registerid int  null constraint fk_entry_reg_reg foreign key references acc.registers (registerid)
	
)


select * from acc.transactions
select * from acc.entries