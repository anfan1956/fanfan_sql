
declare @code nvarchar(95) =
(
select b.mark_code, charindex('21', b.mark_code), barcodeID
from inv.barcodes b 
	join inv.styles s on s.styleID = b.styleID
where 1=1 
	--and b.barcodeID = 
	and mark_code is not null
	and s.orderID  = 
--	87051
	91782
    and mark_code like '%''%'
    )

declare @char char(6) = '\u001D'
, @newCode nvarchar(95);

select *
from inv.barcodes b where b.barcodeID  = 668697
--select  
/*
*/
update b set b.mark_code = ( select
--set @newCode = 
    STUFF(
        STUFF(@code, 32, 0, @char), -- Insert \u001D at position 32
        44, 0, @char                    -- Insert \u001D at position 44
    ) 
/*	as new, len (
    STUFF(
        STUFF(@code, 32, 0, @char), -- Insert \u001D at position 32
        44, 0, @char                    -- Insert \u001D at position 44
    ) as newLength
	*/
    )
from inv.barcodes b where b.barcodeID  = 668697;
Select @newCode, len(@newCode) as lenth
	;

select mark_code, len(mark_code)
from inv.barcodes b 
where b.barcodeID = 668697