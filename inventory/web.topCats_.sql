if OBJECT_ID('web.topCats_') is not null drop function web.topCats_
go 
create function web.topCats_( ) returns table as return

	with cats (cat, inventorytyperus) as (
		select 
			CASE 
				WHEN PATINDEX('%[^a-zA-Z0-9а-яА-Я]%', it.inventorytyperus + ' ' )> 1 
				THEN SUBSTRING(it.inventorytyperus, 1, PATINDEX('%[^a-zA-Z0-9а-яА-Я]%', it.inventorytyperus + ' ' ) -1)
				ELSE it.inventorytyperus 
			END , 
			it.inventorytyperus
		from inv.inventorytypes it
	)
	, s as (
		select 
			st.gender, c.cat, st.styleID, b.barcodeID
	from inv.styles_photos sp
		join inv.styles st on st.parent_styleid = sp.styleid
		join inv.inventorytypes it on it.inventorytypeID = st.inventorytypeID
		join inv.barcodes b on b.styleID=st.styleID
		join cats c on c.inventorytyperus=it.inventorytyperus
		join inv.inventory i on i.barcodeID = b.barcodeID
	where i.logstateID = inv.logstate_id ('in-warehouse')
		group by st.gender, c.cat, st.styleID, b.barcodeID
	having sum(i.opersign)>0
	)
	, f as (
	select 
		count(barcodeid) qty,
		cat
		, gender, 
		sum (count(barcodeID)) over (partition by cat) total
	from s
		group by cat
		, gender
	)
	select distinct top 200 total, cat, iif(total =qty, gender, 'b') genders
	from f

go

select top 12 cat, genders, rank() over(order by total desc) photo from web.topCats_() order by total desc 
