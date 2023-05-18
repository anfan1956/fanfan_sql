declare @lastTrans int = 76931
select 
	s.* ,	t.transactiondate
from inv.sales s 
	join inv.transactions t on t.transactionID=s.saleID
where s.saleID>@lastTrans	
order by 1 desc 

--exec inv.transactions_btw_delete 76932 ,76934



--'python sale_fiscal.py "ФЕДОРОВ А. Н." 76935 "'648733','БРЮКИ',12576;'651518','БРЮКИ',23073" 15000 "sale"'
GO
if OBJECT_ID('fin.fisc_String') is not null drop function fin.fisc_String
go
create function fin.fisc_String (
		@salesPers varchar(max),
		@saleid int ,
		@barcodes dbo.id_money_type readonly,
		@cash money,
		@sale_type varchar(max) 
	)
returns varchar(max) as
begin
declare @finString varchar(max);

with _invString (string) as (
	select STRING_AGG((
		cast(b.id as varchar(max)) 
		+ ',' + it.inventorytyperus 
		+ ',' +	cast(b.amount as varchar(max))
		) , ';')
	--	b.id, it.inventorytyperus,  b.value 
from @barcodes b
	join inv.barcodes bc on bc.barcodeID=b.Id
	join inv.styles s on s.styleID=bc.styleID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
)
select 
	@finString =
	'"' + @salesPers + '" ' 
	+ '"' + s.string  + '" ' 
	+ '"' + cast(@cash as varchar(max)) + '" '
	+ '"' + @sale_type  + '"'  
from _invString s;
return @finString
end 
go

declare 
	@salesPers varchar(max) = 'ФЕДОРОВ А. Н.',
	@saleid int = 76935,
	@barcodes dbo.id_money_type,
	@cash money = 15000,
	@sale_type varchar(max) = 'sale';
insert @barcodes(Id,amount) values (648733, 12576), (651518, 23073);

select fin.fisc_String(	@salesPers, @saleid, @barcodes, @cash, @sale_type) fiscString
