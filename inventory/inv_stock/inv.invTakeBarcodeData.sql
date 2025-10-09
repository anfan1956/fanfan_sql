use fanfan
go

select * 
--delete
from inv.invTake_barcodes 
--where barcodeid= 668692 and takeid = 91751
order by 1 desc;
go

create or alter function inv.invTakeBarcodeData (@barcodeid int) returns table 
as return
select 
		����� as �����	
		, �������
		, f.barcodeID as ������	
		, ���������	
		, ����
		, ������
		, logstate as [�������� ���:]
		, ����� as [� ��������]	
		, li.transactionID
		, li.transactiontype as [��������� ��������]
		, li.transactiondate as ����
from inv.barcodeid_info_f(@barcodeid) f
	outer apply (
		select top 1
			i.transactionID ,tt.transactiontype, t.transactiondate
		from inv.inventory i
			join inv.transactions t on t.transactionID=i.transactionID
			join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		where 1=1
			and i.barcodeID = f.barcodeID
			and i.opersign = 1
		order by t.transactionID desc
	) as li
go

declare @barcodeid int = 668692
select  
  [�����]
, [�������]
, [������]
, [���������]
, [����]
, [������]
, [�������� ���:]
, [� ��������]
, [��������� ��������]
, [����]
from inv.invTakeBarcodeData(@barcodeid)

  
