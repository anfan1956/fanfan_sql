if OBJECT_ID ('inv.barcodeSearch_') is not null drop function inv.barcodeSearch_
go
create function inv.barcodeSearch_(
		@brand varchar (255)=null
		, @itype varchar(255) = null
		, @color varchar (255) = null
		, @size varchar (255) = null
		, @article varchar(255) = null
	) returns table as 
return
select 
	b.barcodeID, i.divisionID, c.color, sz.size, s.article
from inv.styles s 
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.brands br on br.brandID=s.brandID
	join inv.barcodes b on b.styleID=s.styleID
	join inv.inventory i on i.barcodeID =b.barcodeID
	join inv.colors c on c.colorID=b.colorID
	join inv.sizes sz on sz.sizeID= b.sizeID 
where 1=1
	and br.brand like '%' + isnull(@brand, '') + '%'
	and it.inventorytyperus like '%' + isnull(@itype, '') + '%'
	and sz.size LIKE '%' + @size + '%'
	and i.logstateID = inv.logstate_id('IN-WAREHOUSE')
	and c.color like '%' + isnull(@color, '') + '%'
	and s.article like '%' + isnull(@article, '') + '%'
/*
*/
group by 
	b.barcodeID, i.divisionID, color, sz.size, s.article
HAVING SUM(i.opersign)>0

go

declare 
	@brand varchar (255) = 'Aero'
	, @itype varchar (255) = 'футб'
	, @color varchar(255) = '73062'
	, @size varchar (255) = 'M'
	, @article varchar (255) ='TS2'


select * from inv.barcodeSearch_(

	@brand 
	, @itype
	, @color
	, @size
	, @article
)
;

select * from inv.brands br where br.brand LIKE '%' +ISNULL(@brand, '') + '%'
