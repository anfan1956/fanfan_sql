use fanfan
go



--if OBJECT_ID ('acc.journals') is not null drop table acc.journals
--create table acc.journals (
--	jouranlid int not null identity primary key,
--	journal varchar (25) not null unique
--)
if OBJECT_ID ('acc.accounts') is not null drop table acc.accounts
if OBJECT_ID('acc.groups') is not null drop table acc.groups
create table acc.groups (
	groupid int not null identity primary key,
	group_name varchar (25) not null unique
)
create table acc.accounts (
	accountid int not null identity primary key,
	account varchar(50) not null unique,
	groupid int not null constraint fk_accounts_groups foreign key references acc.groups (groupid)
)

if OBJECT_ID ('acc.transactions') is not null drop table acc.transactions
if OBJECT_ID ('acc.trans_types') is not null drop table acc.trans_types
create table acc.trans_types (
	trans_typeid int not null primary key,
	trans_type varchar (255) not null
)

create table acc.transactions (
	transactionid int not null identity primary key,
	transaction_date date not null, 
	trans_typeid int not null constraint fk_acc_transactions_types foreign key references acc.trans_types (trans_typeid),
	recorded datetime default (current_timestamp),
	clientid int not null constraint fk_acc_transactions_clients foreign key references org.clients (clientid),
	userid int not null  constraint fk_acc_transactions_users foreign key references org.persons (personid)

)

insert acc.groups (group_name) values 
('активы'), 
('пассивы'), 
('взаиморасчеты'), 
('соб.средства'), 
('доходы'), 
('с/ст.'), 
('Расходы')
;
insert acc.accounts (account, groupid) values
('деньги', 1),
('товар', 1),
('ОС', 1),
('депозиты', 1),
('авансы', 1),
('подотчет', 1),
('счета к оплате', 2),
('зарплата к оплате', 2),
('кредиты и ссуды', 2),
('долги', 2),
('взаиморасчеты', 3),
('НППП', 4),
('Выручка', 5),
('Себестоимость', 6),
('зарплата', 7),
('аренда', 7),
('МБП и ремонт', 7),
('Маркетинг', 7),
('Фин.расходы', 7)

if OBJECT_ID('acc.registers') is not null drop table acc.registers
create table acc.registers (
	registerid int not null identity primary key,
	divisionid int not null constraint fk_registers_divisions foreign key references org.divisions (divisionid),
	is_public bit default 'False',
	currencyid int not null constraint fk_registers_currencys foreign key references cmn.currencies (currencyid),
	constraint uq_acc_registers unique (divisionid, is_public)

)

select * from acc.accounts
select * from org.banks
select * from org.contractors c where c.contractor like 'Прое%'
insert acc.registers(divisionid, is_public, currencyid) values 
(18, 'False', 643), (25, 'False', 643), (27, 'False', 643) 
select * from acc.registers