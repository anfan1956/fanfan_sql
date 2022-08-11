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
--, _dates(custid, tr_date, tr_type, start_nums, lst, frs_division, lst_division) AS (
, _dates(cust_id, trans_id, purch_date, div_id, sale_type ) AS (
	SELECT 
		s.customerid, T.transactionID, T.transactiondate, sl.divisionID, TT.sale_type  
	FROM s 
	JOIN inv.sales sl ON sl.customerID=s.customerid
	JOIN inv.transactions t ON T.transactionID=sl.saleID	
	JOIN _CASE_tran_types TT ON TT.transactiontypeid=T.transactiontypeID
) 
	, _nums (cust_id, trans_id, purch_date, div_id, sale_type, num_asc, nums_desc) as (
	SELECT 
		s.cust_id, s.trans_id, s.purch_date, s.div_id, s.sale_type, 
		ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY purch_date), 
		ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY purch_date desc) 
	FROM _dates s 
	WHERE s.sale_type = 'SALES'

)
, _start(cust_id, frst_trans_id, frst_date, frs_divid ) AS (
	SELECT n.cust_id, n.trans_id, n.purch_date, n.div_id
	FROM _nums n
	WHERE n.num_asc = 1
)
, _end (cust_id, lst_trans_id, lst_date, lst_divid ) AS (
	SELECT n.cust_id, n.trans_id, n.purch_date, n.div_id
	FROM _nums n
	WHERE n.nums_desc = 1
)
SELECT s.cust_id, s.frst_trans_id, s.frst_date, s.frs_divid, e.lst_trans_id, e.lst_date, e.lst_divid
FROM _start s
	JOIN _end e ON e.cust_id= s.cust_id
WHERE s.frst_date=e.lst_date

GO

SELECT aa.* 
FROM cust.analytics_adv() aa
	
