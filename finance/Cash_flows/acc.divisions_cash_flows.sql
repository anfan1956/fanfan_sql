			with _sales (transdate, amount, account) as (
				select 
					cast(t.transactiondate as date),
					sum (sr.amount * iif(tt.transactiontypeID = 13, -1, 1)),
					'hc' + d.divisionfullname 
				from inv.sales_receipts sr
					join inv.transactions t on t.transactionID= sr.saleID
					join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
					join inv.sales s on s.saleID=sr.saleID
					join org.divisions d on d.divisionID= s.divisionID
					join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
				where receipttype like '%cash%'
					and cast(t.transactiondate as date)>='20220101'
				group by d.divisionfullname, cast(t.transactiondate as date)
			)
			select * from _sales;
select * from acc.registers
