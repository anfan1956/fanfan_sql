
if OBJECT_ID('acc.turnoverCharges_v') is not null drop view acc.turnoverCharges_v
go
create view acc.turnoverCharges_v as

	with _operations (operDate, operId, operType, division, customer, employee, pmtType, fiscal_id, amount) as (
	select
		cast(t.transactiondate as date)
		, s.saleID
		, tt.transactiontype
		, d.divisionfullname 
		, p.lfmname
		, pe.lfmname
		, rt.r_type_rus
		, fiscal_id
		, sr.amount * iif (inv.transaction_type_f(t.transactiontypeID) = 'RETURN', -1, 1) 
	from inv.sales s 
		join inv.transactions t on t.transactionID= s.saleID
		join inv.sales_receipts sr on sr.saleID=s.saleID
		join org.divisions d on d.divisionID=s.divisionID
		join cust.persons p on p.personID = s.customerID
		join org.persons ps on ps.personID = s.salepersonID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join org.persons pe on pe.personID =s.salepersonID
      /* 
      Author: ‘∏‰ÓÓ‚ ¿.
      Date: 
      Comment:  hardcoding startdate *********************************************************************************************************************
      */
		cross Apply (select '20240801') as st(startDate)  
      
	where 
		fiscal_id is not null
		and t.transactiondate >= st.startDate
	)
	select 
			cast (o.operDate as datetime) operDate
			, o.operId, o.operType, o.division
			, o.customer
			, o.employee
			, o.pmtType, o.fiscal_id, o.amount 
			, chrg.chargeType
			, case chrg.chargeType
				when 'tax' then 
					o.amount * fin.parValue_f('simplÂTax_6', o.operDate, default) 
				when 'rent' then
					o.amount * fin.parValue_f('rentTurnRate', o.operDate, org.division_id('05 ”» ≈Õƒ')) 
						*(1 + fin.parValue_f('VAT', o.operDate, default)) 
				end 
			charge
			, DATEPART(year, o.operDate) operYear
			, DATEPART(MONTH, o.operDate) operMonth
			, DATEPART(DAY, o.operDate) operDay
			, 'charges' journal


	from _operations o
		cross join (select 'tax' union all select 'rent' ) as chrg(chargeType)

go

select * from acc.turnoverCharges_v