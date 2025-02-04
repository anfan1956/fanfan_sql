set nocount on;
IF  OBJECT_ID('fsc.ReceiptCorrections', 'U') is not null drop table fsc.ReceiptCorrections

CREATE TABLE fsc.ReceiptCorrections (
    id INT identity PRIMARY KEY
    , saleid int not null references inv.sales 
	, docNo varchar(10) null
	, dateCorrected datetime 
	, correctionDocNum varchar (10)
	, correctionFisc varchar (12)
	, correctionManager int not null references org.users		
	, constraint uq_recCorrections unique (saleid)
);

go
declare @docNums table (docNo varchar(10), divisionid int null)
insert @docNums (docNo)
values 
  (6)
, (7) 
, (36) 
, (47) 
, (48) 
, (53) 
, (94) 
, (95) 
, (96) 
, (97) 
, (116) 
, (119) 
, (126) 
, (127) 
, (128) 
, (131) 
, (136) 
, (141) 
, (144) 
, (145) 
, (146) 
, (147) 
, (150) 
, (151) 
, (158) 
, (159) ;

update @docNums set divisionid = 35
where divisionid is null

insert @docNums (docNo)
values 
  (13)
, (14)
, (15)
, (16)
, (36)
, (37)
, (38)
, (43)
, (44)
, (45)
, (46)
, (47)
, (48)
, (49)
, (50)
, (51)
, (57)
, (62)
, (83)
, (104)
, (107)
, (126)
, (135)
, (150)
, (151)
, (160)
, (161)
, (164)
, (171)
, (176)
, (193)
, (200)
, (211)
, (214)
, (227) 
, (240)
, (245) 
, (264)
, (265) 
, (266)
, (269) 
, (270)
, (273)  
, (274)
, (275)  
, (292)
, (295)  ;
update d set d.divisionid = 27
from @docNums d where d.divisionid is null;

with CTE (saleid, docNo, divisionid) as (
	select  s.saleID, s.receiptid, isnull (l.redirectTo, s.divisionID)
	from inv.sales s 
		left join acc.CardRedirectLog l on l.transactionId = s.saleID	
)
insert fsc.ReceiptCorrections (saleid, docNo, correctionManager)
select 
	c.saleid 
	--, c.divisionid redirect , d.divisionid fiscal 
	, d.docNo
	, 1
from @docNums d
	 left join CTE c on c.divisionid = d.divisionid
		and c.docNo= d.docNo
where c.saleid is not null	

select * from fsc.ReceiptCorrections
select * from @docNums
/*
*/

