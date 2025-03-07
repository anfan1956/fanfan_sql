use fanfan
go
if OBJECT_ID ('acc.ConsignmentAPs') is not null drop function acc.ConsignmentAPs
go 

create function acc.ConsignmentAPs (@startdate date = '20241101', @vendor varchar(max)) returns table as 
return

	select 
		 sr.transactionid	
		, sr.tranDate	
		, sr.transType	
		, sr.division	
		, sr.SC	
		, sr.category	
		, sr.article	
		, sr.amount
		, sr.transactionDate
	from 
	(
	select 
		 transactionid =		sg.saleID
		, tranDate =			format( t.transactiondate, 'dd.MM.yyyy')
		, transType =			tt.transactiontype
		, division =			divisionfullname
		, SC =					d.comment
		, category =			it.inventorytyperus
		, article  =			st.article
		, amount =				st.cost *	
									case tt.transactiontype
										when 'SALE' then 1
										else -1
									end
		, transactionDate = cast(t.transactiondate as date)

	from inv.sales_goods sg
		join inv.transactions t on t.transactionID=sg.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.barcodes b on b.barcodeID=sg.barcodeID
		join inv.styles st on st.styleID = b.styleID
		join inv.brands br on br.brandID = st.brandID
		join inv.sales s on s.saleID=sg.saleID
		join org.divisions d on d.divisionID = s.divisionID
		join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID	
		outer apply (
			select top 1
				bra.brandID
			from inv.brands bra
				join inv.styles sty on sty.brandID=bra.brandID
				join inv.orders ord on ord.orderID=sty.orderID
			where showroomID=org.contractor_id(@vendor)
			group by bra.brandid	
		) as bnd
		where 1=1
			and t.transactiondate>=@startdate
			and st.brandID= bnd.brandid
	/*
	*/
	union all
	select
		transactionid		= t.transactionid 
		, tranDate			=  format (t.transdate, 'dd.MM.yyyy')
		, transType			=  'PAYMENT' 
		, division			= 'ИП Иванова Т. К.'  
		, sc				= null
		, category			= null
		, article			= null
		, amount			= -amount 
		, trasactionDate	=  cast (t.transdate as date)
	from acc.transactions t
		join acc.entries e on e.transactionid = t.transactionid
			and is_credit = 'False'
			and e.contractorid = org.contractor_id('ИП Карпинская Анастасия')
	where t.transdate>=@startdate
	) as sr
go

select c.transactionid, c.tranDate, c.transType, c.division, c.sc, category, c.article, c.amount 
from acc.ConsignmentAPs (default, 'ИП Карпинская Анастасия') c 

order by c.transactiondate desc, transactionid 
