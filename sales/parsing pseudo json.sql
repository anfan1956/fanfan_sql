declare @sales_table table (saleid int, reciepttypeid int, amount money, registerid int)
declare @registerid int = 5;
declare @cross_table table (
	pmtType varchar(15), receipttypeID int
)
insert @cross_table (pmtType, receipttypeID) values
('по карте', 5), 
('по QR-коду', 7), 
('по телефону', 8), 
('наличными', 1)
--select * from fin.receipttypes;

--declare @string varchar(max) ='по карте: 14140: АЛЬФА-БАНК, по QR-коду: 20000: АЛЬФА-БАНК, по телефону: 5000: ТИНЬКОФФ, наличными: 5000: '
declare @string varchar(max) 
set @string	='по QR-коду: 10700: АЛЬФА-БАНК'
set @string = 'по карте:1000:ТИНЬКОФФ, по QR-коду:1200:АЛЬФА-БАНК, по телефону:1500:ТИНЬКОФФ, наличными:3322:'
set @string = 'по карте:731:ТИНЬКОФФ, по QR-коду:4000:АЛЬФА-БАНК, по телефону:1250:ТИНЬКОФФ, наличными:3750:'
set @string = 'по карте:731:ТИНЬКОФФ, по QR-коду:4000:АЛЬФА-БАНК, по телефону:1250:ТИНЬКОФФ, наличными:3750:'
			  
declare @data table (myData varchar(max));
declare @shop varchar(15) = '05 УИКЕНД'
declare @rec_types table (pmtType varchar(15), amount money, contractor varchar (25))
declare @saleid int = 76656;

declare @shopRegisterid int  = (
	select  v.registerid from acc.registerid_divisionid_v v 
		join org.divisions d on d.divisionID=v.divisionID
	where d.divisionfullname= @shop)

declare @clientid int = (select clientID from org.divisions d where d.divisionfullname= @shop);
--select @clientid;

insert @data select value from  string_split (@string, ',')
select  * from @data;
UPDATE @data SET myData = TRIM(myData);

insert @rec_types
select 
	SUBSTRING(myData, 1, charindex(':', myData)-1) pmtType, 
	SUBSTRING(myData, charindex(':', myData)+1, charindex(':', myData, (charindex(':', myData, 1))+1)-charindex(':', myData)-1) amount,
	substring(myData, charindex(':', myData, (charindex(':', myData, 1))+1)+1,15) contractor
from @data
--
select *, len(pmtType) from @rec_types; --select * , len(pmtType)from @cross_table
if (select  count (*)  from @rec_types r where r.pmtType<>'наличными') >  (select  count (*)  from @rec_types r where contractor <>'' and r.pmtType<>' наличными')
throw 500001, 'error register no avail' , 1

select * 
from @rec_types r
	join @cross_table t on t.pmtType=r.pmtType
	left join fin.receipttypes rt on rt.receipttypeID=t.receipttypeID
	left join org.contractors cn on cn.contractor= r.contractor

insert @sales_table 
select 
	@saleid saleID, rt.receipttypeID, r.amount, 
	case when r.pmtType in ('наличными', 'по телефону') then @registerid
	else	rg.registerid end
from @rec_types r
	left join @cross_table c on c.pmtType=r.pmtType
	left join fin.receipttypes rt on rt.receipttypeID=c.receipttypeID
	left join org.contractors cn on cn.contractor = r.contractor
	left join acc.registers rg on rg.bankid = cn.contractorID and rg.clientid=@clientid

--select *, sum (amount) over() from @sales_table
if (select amount from @rec_types where pmtType= 'по телефону') >0 
begin
	declare @transid int = 100000;
	declare @bank varchar(25) = (select contractor from @rec_types where pmtType= 'по телефону')
	select 
		@transid, cast (getdate() as date) transdate, 
		CURRENT_TIMESTAMP recorded, 
		1 bookkeeperid, 
		643 currencyid, 12 articleid, 619 clientid, 
		r.amount,
		'05 Уикенд ' + 'в ' + @bank comment, 'cash' document
	from @rec_types r where r.pmtType = 'по телефону';
	with _seed (is_credit, accountid, personid, registerid) as (
		select 'True', acc.account_id('деньги'), null, @registerid
		union all
		select 'False', acc.account_id('подотчет'), org.person_id('Федоров А. Н.'), null
	)
	select @transid transactionid, cast (is_credit as bit) is_credit, accountid, null contractorid, personid, registerid 
	from _seed;

end 

--select charindex(':', myData), charindex(':', myData, (charindex(':', myData, 1))+1) from @data
--select top 5 * from inv.sales_receipts order by 1 desc
select * 
from acc.transactions t
	join acc.entries e on e.transactionid = t.transactionid
where t.articleid = acc.article_id('ВЫДАЧА ПОД ОТЧЕТ')
and t.transactionid = 1378
