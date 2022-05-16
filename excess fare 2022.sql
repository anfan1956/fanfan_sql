use anfan_release
go

--select * from acc.accounts a join acc.accountsections s on a.sectionid=s.sectionid where a.sectionid =13
--where a.sectionid=
--if OBJECT_ID ('tmp.excess_fare') is not null drop table tmp.excess_fare
--go

--create table tmp.excess_fare (
--	person varchar (50), 
--	charge money, 
--	personid int null

--)
--insert tmp.excess_fare (person, charge) values 
--	('БАЛУШКИНА А. А.',  34864.477383), ('БЕЗЗУБЦЕВА Е. В.',  -32484.056723), 
--	('ГОРИНА И. А.',  34811.244828), ('ГОРЛОВА А. Р.',  13354.877741), 
--	('КУЗЬМИНА С. А.',  21207.49087), ('КУЛИКОВСКАЯ С. А.',  27558.281547), 
--	('РОМАХИН М. Е.',  38836.529938), ('ШЕМЯКИНА Е. В.',  28514.488836)
--	;
--with s (person, personid) as (
--	select e.person, c.contractorid
--	from tmp.excess_fare e
--		join org.contractors c on c.contractor= e.person
--)
----select 
----update e set e.personid=s.personid
--from tmp.excess_fare e
--		join s on s.person = e.person;
--select * from tmp.excess_fare
--select  top 1 * from acc.fin_transactions

declare @details varchar(125) = 'доплата коммисс с 15.12.22 по 1 квартал 2022', @splitid int =1, @detailsid int, @currencyid int =643,
@date date = '20220416', @clientid int =1, @accpayable_id int = acc.accountid_func('зарплата к оплате', 'RUR'),
@accexpense_id int = acc.accountid_func('комиссионные', 'RUR');
select @detailsid = acc.details_id (@details); 
with s (splitid, currencyid, transactiondate, detailsid, clientid, comment) as (
	select @splitid, @currencyid, @date, @detailsid, @clientid,  convert(varchar (10), personid) 
		from tmp.excess_fare e
)
--insert acc.fin_transactions (splitid, currencyid, transactiondate, detailsid, clientid, comment)
--select *from s;
select top 2 * from acc.generalledger;
with _cricket (userid, is_credit, accountid ) as 
(
	select 1, 'False', @accexpense_id union all select 1, 'True', @accpayable_id
)
, s (transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid) as (
	select transactionid, CURRENT_TIMESTAMP,  c.userid, 
		c.accountid, cast (f.comment as int), c.is_credit, 5 
		from acc.fin_transactions f 
			cross apply _cricket c
	where f.detailsid= @detailsid
)
insert acc.generalledger (transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid, amount)
select transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid, e.charge amount 
from s 
	join  tmp.excess_fare e on e.personid=s.contractorid
;

