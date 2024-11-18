if OBJECT_ID ('acc.ConsignmentAPs') is not null drop function acc.ConsignmentAPs
go 



declare @barcodes table (barcodeid int);
insert @barcodes 
select distinct 
	barcodeid
from inv.inventory i 
where i.transactionID in (85921, 85922);


select
	format (t.transactiondate, 'dd.MM.yyyy', 'ru-ru') дата
	, st. article артикул
	, it.inventorytyperus категория
	, st.cost стоимость
	, sg.amount выручка
	, d.comment 
	, d.divisionfullname магазин
	--, sum(cost) over() всего_стоимость
	--, sum(sg.amount) over() всего_выручка
from inv.sales_goods sg 
	join @barcodes b on b.barcodeid = sg.barcodeID
	join inv.barcodes bc on bc.barcodeid = b.barcodeid
	join inv.styles st on st.styleID = bc.styleID
	join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID
	join inv.transactions t on t.transactionID = sg.saleID
	join inv.sales s on s.saleID=sg.saleID
	join org.divisions d on d.divisionID = s.divisionID
order by 1 