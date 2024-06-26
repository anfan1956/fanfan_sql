USE [fanfan]
GO

if OBJECT_ID('inv.barcode_price3')  is not null drop function inv.barcode_price3
go
create function inv.barcode_price3 (@barcodeid int) returns table as return
	with cte (styleid, price, discount, num) as
	(
		select 
			p.styleID, p.price, p.discount,
			ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc)
		from inv.prices p 
	)

	select   		
		round(
			case o.orderclassID 
				when 3 then cte.price 
				else
					sp.cost * ISNULL(sp.cost_adj, 1) * cr.rate * cr.markup
					end
					, -1) price, 
			cte.discount
	from inv.v_r_inwarehouse v
		join org.divisions d on d.divisionID= v.divisionID
		join inv.barcodes b on b.barcodeID = v.barcodeID
		join inv.styles s on s.styleID=b.styleID
		join cte on cte.styleid =s.styleID and num =1
		left join inv.styles sp on sp.styleID=s.parent_styleid
		join inv.orders o on o.orderID=s.orderID
		join inv.current_rate_v cr on v.divisionID=cr.divisionid 
							and cr.currencyid=o.currencyID
	where v.barcodeID = @barcodeid 



go
declare @bc int = 666706
select * from  inv.barcode_price3 (@bc)