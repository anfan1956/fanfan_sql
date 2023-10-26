if OBJECT_ID('inv.style_barcodes_json_') is not null drop function inv.style_barcodes_json_
go

create function inv.style_barcodes_json_(@json varchar(max)) returns varchar(max) as 
begin
declare @barcodes varchar(max);

with st (parentid ) as (
		select styleid from 
		openjson(@json)
		with (
			styleid int '$.styleid'
		) as jsonValues
	)
,_avail (color) as (
		select distinct color from web.photos_colors_(
			(select parentid from st)
		)
	)

select @barcodes = (
	select 
		b.barcodeid, p.color, p.size, d.divisionfullname магазин, 
		iif (cl.color is not null, 'есть', 'нет') фото, 
		sum(i.opersign) qty
	from inv.barcodes b
		join inv.inventory i on i.barcodeID =b.barcodeID
		join inv.styles s on s.styleID=b.styleID
		join org.divisions d on d.divisionID=i.divisionID
		cross apply inv.barcode_props_(b.barcodeID) p
		join st on st.parentid=s.parent_styleid
		left join _avail cl on cl.color=p.color
	where  i.logstateID=inv.logstate_id	('IN-WAREHOUSE')
	group by b.barcodeID, d.divisionfullname, p.color, p.size,cl.color

	having sum(i.opersign)>0
	order by p.color, size
	for json path
)
return @barcodes
end
go

declare @json varchar(max) = 
'[
	{"styleid": 19996}
]'

select inv.style_barcodes_json_(@json)

select distinct color from web.photos_colors_(19628)