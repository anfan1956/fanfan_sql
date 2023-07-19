select a.*, cl.contractor holder 
from acc.registers a
	join org.contractors cl on cl.contractorID= a.clientid
where cl.contractor = 'ФЕДОРОВ А. Н.'
	
select * from acc.accounts a where a.account like '%день%'
if OBJECT_ID ('acc.registers_accounts') is not null drop table acc.registers_accounts
go
create table acc.registers_accounts (
	registerid int not null foreign key references acc.registers(registerid),
	accountid int not null foreign key references acc.accounts(accountid)
	constraint pk_registers_accounts primary key (registerid, accountid)
)

insert acc.registers_accounts values 
(1, 26), (3, 26), (5, 26), (7, 1), (15, 1), (20, 1), (25, 1), (26, 1)
,(8, 25) ,(9, 25) ,(17, 25) ,(18, 25) ,(19, 25) ,(23, 25) ,(24, 25) 

select r.*, ra.accountid, c.contractor bank
from acc.registers r
	left join acc.registers_accounts ra on ra.registerid=r.registerid
	join org.contractors c on c.contractorID=r.bankid

	