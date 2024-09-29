use fanfan
go
--declare @startdate date = '20240511', @days int = 14, @userid int = 47, @username varchar(max) = 'ÊÓËÈÊÎÂÑÊÀß Ñ. À.'; 
--declare @startdate date = '20240614', @days int = 14, @userid int = 47, @username varchar(max) = 'ÊÓËÈÊÎÂÑÊÀß Ñ. À.'; 
--declare @startdate date = '20240602', @days int = 14, @userid int = 66, @username varchar(max) = 'ÁÅÇÇÓÁÖÅÂÀ Å. Â.'; 
declare @startdate date = '20240701', @days int = 14, @userid int = 66, @username varchar(max) = 'ØÅÌßÊÈÍÀ Å. Â.'; 
declare @except date  = '20230607'
declare	@lastFullPeriodDate datetime=
		case when datepart(DD, @startdate)<16 
			then  eomonth(@startdate, -1)
			else datefromparts(datepart(yyyy, @startdate), datepart(MM, @startdate), 16) end;
select @lastFullPeriodDate;

select 
	t.transactionid, t.transdate, a.article, t.amount, ac.account, t.document
	--, 
	--sum (amount) over() ,
	--sum (amount) over ()/(12 * 29.3) * @days
	--sum (amount) over (partition by datepart(yyyy, t.transdate), datepart(MM, t.transdate))
from acc.transactions t 
	join acc.articles a on a.articleid=t.articleid
	join acc.entries e on e.transactionid=t.transactionid
	join acc.accounts ac on ac.accountid=e.accountid
	
where 
	t.articleid = 13 
	and e.personid = @userid 
	and e.is_credit='True'
	and ac.accountid = 8
	and transdate > DATEADD(MM, -12,  @lastFullPeriodDate) 
	and t.transdate<= @lastFullPeriodDate
	and t.transdate <> @except

order by transdate desc, t.transactionid desc, document 

select * from org.users u where u.username like 'Øå%'