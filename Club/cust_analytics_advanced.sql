USE fanfan
GO

IF OBJECT_ID('cust.analytics_adv') IS NOT NULL DROP FUNCTION cust.analytics_adv
GO
CREATE FUNCTION cust.analytics_adv() RETURNS TABLE AS RETURN

WITH _CASE_tran_types (sale_type, transactiontypeid) AS (
	SELECT 
		CASE WHEN 
				T.transactiontype IN ('SALE', 'SALE CASH', 'SALE MIXED', 'SALE INTERNAL')
					THEN 'SALES'
			WHEN T.transactiontype IN ('RETURN') 
					THEN 'RETURNS'
			ELSE T.transactiontype END,
			T.transactiontypeID		
	FROM inv.transactiontypes t
)
, s AS (
	SELECT	P.phoneid, P.customerid
	FROM sms.phones p
)
, _dates(cust_id, cust_name , trans_id, purch_date, division, sale_type, chain ) AS (
	SELECT 
		s.customerid, p.lfmname, T.transactionID, T.transactiondate, d.divisionfullname, 
		TT.sale_type , c.chain
	FROM s 
		JOIN inv.sales sl ON sl.customerID=s.customerid
		JOIN inv.transactions t ON T.transactionID=sl.saleID	
		JOIN _CASE_tran_types TT ON TT.transactiontypeid=T.transactiontypeID
		JOIN org.divisions d ON D.divisionID=sl.divisionID
		JOIN org.chains c ON c.chainID=D.chainID
		JOIN cust.persons p ON P.personID=s.customerid
) 
	, _nums (cust_id, cust_name, trans_id, purch_date, division, sale_type, num_asc, nums_desc, chain) as (
	SELECT 
		s.cust_id, s.cust_name, s.trans_id, s.purch_date, s.division, s.sale_type, 
		ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY purch_date), 
		ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY purch_date desc), 
		s.chain 
	FROM _dates s 
	WHERE s.sale_type = 'SALES'

)
, _start(cust_id, cust_name, frst_trans_id, frst_date, frs_div, chain ) AS (
	SELECT n.cust_id, cust_name, n.trans_id, n.purch_date, n.division, n.chain
	FROM _nums n
	WHERE n.num_asc = 1
)
, _sms_dates (cust_id, smsdate, num)  AS (
SELECT s.customerid, i.smsdate,
ROW_NUMBER() OVER (PARTITION BY s.customerid ORDER BY i.smsid desc )
FROM s
LEFT JOIN sms.instances_customers ic ON ic.customerid= s.customerid
LEFT JOIN sms.instances i ON I.smsid	=ic.smsid
)
, _end (cust_id, lst_trans_id, lst_date, lst_div) AS (
	SELECT n.cust_id, n.trans_id, n.purch_date, n.division
	FROM _nums n
	WHERE n.nums_desc = 1
)
SELECT 
	s.cust_id, s.cust_name, s.chain registered,  
	s.frst_trans_id, s.frst_date, s.frs_div, e.lst_trans_id, 
	e.lst_date, e.lst_div, ISNULL(dbo.justdate(sd.smsdate), 0) sms_date
FROM _start s
	JOIN _end e ON e.cust_id= s.cust_id
	JOIN _sms_dates sd ON sd.cust_id= s.cust_id
WHERE sd.num =1;


GO

