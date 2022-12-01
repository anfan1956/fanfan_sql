-- if OBJECT_ID ('acc.beg_entries') is not null drop table acc.beg_entries
--go
--create table acc.beg_entries (
--	entryid int not null identity primary key,
--	entrydate date not null,
--	registerid int not null constraint fk_begEntries_registers foreign key references acc.registers (registerid),
--	amount money not null,
--	constraint uq_beg_entries unique (entrydate, registerid)
--)

if OBJECT_ID('acc.beg_entries_v') is not null drop view acc.beg_entries_v
go
create view acc.beg_entries_v as
with s (id, дата, банк, счет, держатель, сумма, валюта, суммаRUR) as (
	select entryid, cast(entrydate as datetime), c.contractor, r.account, c2.contractor, b.amount, cr.currencycode, b.amount*crt.rate
	from acc.beg_entries b
		JOIN acc.registers r on r.registerid=b.registerid
		join org.contractors c on c.contractorID=r.bankid
		join org.contractors c2 on c2.contractorID= r.clientid
		join cmn.currencies cr on cr.currencyID=r.currencyid
		join cmn.currentrates crt on crt.currencyID=cr.currencyID
)
select * from s;

go

select * from acc.beg_entries_v
where дата =  dbo.justdate(GETDATE());
