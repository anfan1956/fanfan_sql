if OBJECT_ID('acc.rentPayments_v') is not null drop view acc.rentPayments_v
go
create view acc.rentPayments_v as
with 
  _start (startdate) as (select '20240701' )
, _rent (amount, pmtDate, article, pmtId, fiscalDocNum) as (
	select sum(inp.amount), pmt.transdate, a2.article, pmt.transactionid
		, pmt.document
	from acc.invoices_payments inp
		join acc.transactions t on t.transactionid = inp.invoiceid
		join acc.invoices i on i.invoiceid =inp.invoiceid		
		join acc.articles a on a.articleid = t.articleid
		join acc.transactions pmt on pmt.transactionid= inp.paymentid
		join acc.articles a2 on a2.articleid=pmt.articleid		
		cross apply _start s 
	where 1=1
		and t.transdate >= s.startdate
		and i.vendorid = org.contractor_id('КРОКУС СИТИ МОЛЛ')
		and t.clientid =  org.client_id_clientRUS('ИП Иванова')
		and a.article = 'АРЕНДА ПО СЧЕТУ'		
	group by pmt.transdate, a2.article, pmt.transactionid, pmt.document
)
select 
	operDate		= r.pmtDate
	, operId		= pmtId
	, operType		= article
	, division		= '05 УИКЕНД'
	, customer		= ''
	, pmtType		= 'Платежное поручение'
	, fiscalDocNum	= r.fiscalDocNum
	, amount		= r.amount
	, chargeType	= 'rent'
	, charge		= - r.amount
	, operYear		= DATEPART(YEAR, r.pmtDate)
	, operMonth		= DATEPART(MONTH, r.pmtDate)
	, operDay		= DATEPART(DAY, r.pmtDate)
	, journal		= 'payments'
from _rent r;
go

select * from acc.rentPayments_v