
if OBJECT_ID('acc.turnoverCharges_f') is not null drop function acc.turnoverCharges_f
go
create function acc.turnoverCharges_f (@startdate date) returns table as
return 
	with _operations (operDate, operId, operType, division, customer, pmtType, fiscal_id, amount) as (
	select
		cast(t.transactiondate as date)
		, s.saleID
		, tt.transactiontype
		, d.divisionfullname 
		, p.lfmname
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
	where 
		fiscal_id is not null
		and t.transactiondate >= @startdate
	)
	select 
			o.operDate, o.operId, o.division, o.customer, o.pmtType, o.fiscal_id, o.amount 
			, chrg.chargeType
			, case chrg.chargeType
				when 'tax' then 
					o.amount * fin.parValue_f('simplÂTax_6', o.operDate, default) 
				when 'rent' then
					o.amount * fin.parValue_f('rentTurnRate', o.operDate, org.division_id('05 ”» ≈Õƒ')) 
						*(1 + fin.parValue_f('VAT', o.operDate, default)) 
				end 
			charge
	from _operations o
		cross join (select 'tax' union all select 'rent' ) as chrg(chargeType)

go
declare @startdate date = '2024-09-01';
select * from acc.turnoverCharges_f (@startdate)