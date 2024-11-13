if OBJECT_ID('inv.barcode_reciept2_func') is not null drop function inv.barcode_reciept2_func
go
create function inv.barcode_reciept2_func (@barcodeid int) returns table as return

select 
		i.barcodeID
	,	br.brand �����
	,	se.season �����
	,	st.article �������
	, 	it.inventorytyperus ���������
	,	sz.size ������
	,	cl.color ���� 
	,	cmp.composition 
	,	pr.price ����
	,	round(pr.discount, -1) ������
	,	isnull(w.promo_discount, 0) �����
	,	round( (1 - isnull(pr.discount, 0))* pr.price, -1) price
	,	case l.logstate
					when 'IN-WAREHOUSE' then '� �������'
					when 'SOLD'  then '���������'
					when 'LOST' then '����������'
					else l.logstate
				end ������
	, d.divisionfullname �������
from inv.inventory i 
	join inv.logstates l						on l.logstateID= i.logstateID
	join org.divisions d						on d.divisionID = i.divisionID
	join inv.barcodes b							on b.barcodeID =i.barcodeID
	join inv.styles st							on st.styleID = b.styleID
	join inv.brands br							on br.brandID=st.brandID
	left join inv.seasons se					on se.seasonID=st.seasonID
	join inv.colors cl							on cl.colorID=b.colorID
	join inv.sizes sz							on sz.sizeID=b.sizeID
	join inv.inventorytypes it					on it.inventorytypeID=st.inventorytypeID
	left join inv.v_compositions cmp			on cmp.compositionID=st.compositionID
	left join web.styles_discounts_active_ w	on w.styleid=st.styleID
	cross apply 
		(select top 1 p.price, p.discount from inv.prices p
			join inv.pricesets ps on ps.pricesetID=p.pricesetID
			where p.styleID =st.styleID
			order by p.pricesetID desc
		) as pr 
where 1=1 
	and i.barcodeID = @barcodeid		
group by 
	i.barcodeID
	, l.logstate
	, d.divisionfullname
	, br.brand 
	, se.season
	, st.article
	, it.inventorytyperus
	, sz.size 
	, cl.color
	, pr.price 
	, pr.discount 
	, cmp.composition
	, w.promo_discount
having sum(i.opersign)>0
go


declare @shop varchar (25)= '07 ������', @barcodeid int =668549;
select barcodeID, �����, �����, �������, ���������, ������, ����, composition, ����, ������, ����� --, price
		from inv.barcode_reciept2_func(@barcodeid) f where f.������='� �������';
