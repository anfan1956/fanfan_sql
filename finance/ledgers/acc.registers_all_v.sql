use fanfan
go

if OBJECT_ID('acc.registers_all_v') is not null drop view acc.registers_all_v
go
create view acc.registers_all_v as
select 
	r.registerid, c.contractor bank, currencycode, r.account, c2.contractor, 
	b.cardnumber, valid, b.name_on_card
from acc.registers	r
join org.contractors c on c.contractorID=r.bankid
join cmn.currencies cr on cr.currencyID=r.currencyid
join org.contractors c2 on c2.contractorID= r.clientid
LEFT JOIN acc.accounts_cards ac on ac.registerid = r.registerid
left join acc.bankcards b on b.cardid=ac.cardid



go

select * from acc.registers_all_v
select * from acc.registers	
select 
	registerid, c.contractor bank, currencycode, r.account, c2.contractor 
from acc.registers	r
join org.contractors c on c.contractorID=r.bankid
join cmn.currencies cr on cr.currencyID=r.currencyid
join org.contractors c2 on c2.contractorID= r.clientid


