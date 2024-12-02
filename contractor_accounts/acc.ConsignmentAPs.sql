if OBJECT_ID ('acc.ConsignmentAPs') is not null drop function acc.ConsignmentAPs
go 

create function acc.ConsignmentAPs (@startdate date = '20241101', @vendor varchar(max)) returns table as 
return

	with  _barcodes  (barcodeid ,  vendorid) as (
		select distinct 
			barcodeid, o.vendorID
		from inv.inventory i 
			join inv.orders o on o.orderID = i.transactionID and o.orderclassID =3
			join inv.transactions t on t.transactionID= o.orderID
		where 1=1
			and t.transactiondate >=@startDate
		)
	, _sales (saleid, article, shop, SC, category, cost, barcodeid, vendorid, transtype)  as 
		(
		select 
			s.saleID
			, st.article
			, d.divisionfullname
			, d.comment, it.inventorytyperus
			, case tt.transactiontype 
				when 'RETURN'  
					then -st.cost
				else 
					st.cost 
			end		
			, sg.barcodeid 
			, bc.vendorid 
			, tt.transactiontype
		from inv.sales s
			join inv.sales_goods sg on sg.saleID =s.saleID
			join _barcodes bc on bc.barcodeid= sg.barcodeID
			join inv.barcodes b on b.barcodeID = bc.barcodeid
			join inv.styles st on st.styleID=b.styleID
			join org.divisions d on d.divisionID=s.divisionID
			join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID
			join inv.transactions t on t.transactionID = s.saleID
			join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		
	)
, final as (
	select
		t.transactionid
		, FORMAT(t.transdate , 'dd.MM.yyyy') tranDate
		, s.transtype
		, shop, SC
		, category
		, article
		, cost amount
		, vendorid 
	from acc.transactions t 
		join _sales s on t.saleid =s.saleid and t.barcodeid =s.barcodeid
	union all 
	select 
		t.transactionid
		, FORMAT(t.transdate, 'dd.MM.yyyy')  transdate
		, case e.is_credit 
			when 'True' then 'CREDIT'
			else 'PAYMENT' end transtype
		, 'Банковский перевод'  
		, t.comment	
		, NULL
		, NULL
		, case e.is_credit 
			when 'True' then amount
			else - amount end amount
		, b.vendorid
	from acc.transactions t
		join acc.entries e on e.transactionid = t.transactionid
		join _barcodes b on b.vendorid = e.contractorid	
	where 1=1
		and e.accountid =7
		and t.saleid is null
	group by 
		vendorid
		, e.is_credit
		, t.transactionid, t.transdate, t.amount, t.comment
	)
	select f.transactionid, f.tranDate, f.transtype, shop, sc, category, article, amount 
	from final f
	join org.contractors c on c.contractor = @vendor

go

select * from acc.ConsignmentAPs (default, 'ИП Карпинская Анастасия') order by 1 desc
select * from acc.transactions t
where saleid =85934 



