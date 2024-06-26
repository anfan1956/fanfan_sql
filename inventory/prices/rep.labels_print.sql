USE [fanfan]
GO
/****** Object:  UserDefinedFunction [rep].[labels_print]    Script Date: 29.01.2024 2:34:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter function [rep].[labels_print]( @barcodes barcodes_list readonly )
returns table as return

with cte (styleid, price, discount, num) as (
	select 
		p.styleID, p.price, p.discount, 
		ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc)
	from inv.prices p 
)
	select	g.barcodeID, 
			cmn.barcode_gen_ean13( g.barcodeID ) as barcode, 
			convert( varchar, getdate(), 104 ) as header,
			g.brand, 
			g.category + ' - ' + g.article + '_'+
--						+ iif( left( s.season, 1 ) = 'F', 'w', 's' )
				case left (isnull(s.season, 'UD2000'), 1)
					when 'F' then 'W'
					when 'S' then 'S'
					else 'U' end 
						+ right( cast(isnull( s.seasonyear, 2000) as varchar ), 2 ) as article, 
			g.color + ' - ' + g.size as colorsize,
			g.composition,
			
			FORMAT( round(
				cte.price * (1-g.discount)

				, -1)			
			, '0,0' )  as price, 
			iif( g.discount = 0, '', format( g.discount * 100, '0' ) ) as discount,
			case  
				when g.discount > 0 then
					FORMAT( round(cte.price, -1), '0,0' )
				else ''
			end 
			baseprice, 
--			iif( g.discount = 0, '', format(round(ISNULL(p.cost_adj, 1) * p.cost * r.markup * r.rate, -1), '0,0' ) ) as baseprice,
			g.originRUS as origin
	from @barcodes bc
		join inv.v_goods g on g.barcodeID = bc.barcodeID 
								and g.originRUS is not null
								and g.composition is not NULL
		JOIN inv.v_remains vr ON vr.barcodeID=bc.barcodeID					
		JOIN inv.styles st ON st.styleID= g.styleID
		join inv.styles p on p.styleID=st.parent_styleid
		JOIN inv.orders o ON o.orderID=p.orderID
		left join inv.seasons s on s.season = g.season
		join cte on cte.styleid=st.styleID and cte.num=1
		left JOIN inv.current_rate_v r ON r.divisionid= vr.divisionID
							AND r.currencyid= o.currencyID		
	where vr.logstateID = inv.logstate_id('IN-WAREHOUSE')


go

set nocount on; declare @barcodes dbo.barcodes_list; 
insert @barcodes  values 
	(668201), (668127), (668126), (668131), (668132), (668044), (667758), (667761), (667764), (667763), 
	(667765), (667766), (667768), (667769), (667771), (667772), (667770); 
select * from rep.labels_print ( @barcodes ) order by brand, article, colorsize
select g.* , l.logstate
from inv.v_remains g 
	join inv.logstates l on l.logstateID=g.logstateID
where g.barcodeID= 667761


