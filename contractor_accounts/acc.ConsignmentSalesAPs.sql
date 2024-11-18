-- ***************************************---
if OBJECT_ID ('acc.ConsignmentSalesAPs') is not null drop proc acc.ConsignmentSalesAPs
go

create proc  acc.ConsignmentSalesAPs as 
	set nocount on;
	set transaction isolation level read committed;
	declare @msg varchar (max)
	begin try  
		begin transaction


			declare @transOutput table (transactionid int, saleid int, barcodeid int);

			with s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid, barcodeid, vendorid) as (
				select 
					 cast(t.transactiondate as date)
					, org.user_id('INTERBOT')
					, 643
					, acc.article_id('за консигн. товар')
					, o.buyerID
					, st.cost
					,	case tt.transactiontype 
							when 'RETURN' then 'возврат конс. товара'
						else 'продажа конс. товара' 
						end
					, 'б/д'
					, sg.saleID
					, sg.barcodeID
					, o.vendorID
				from inv.sales_goods sg
					join inv.transactions t on t.transactionID = sg.saleID
					join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID 
					join inv.inventory i on i.barcodeID = sg.barcodeID
					join inv.orders o on o.orderID= i.transactionID and o.orderclassID = 3
					join inv.barcodes b on b.barcodeID = sg.barcodeID 
					join inv.styles st on st.styleID = b.styleID
				where 1=1
					and i.logstateID = inv.logstate_id ('IN-WAREHOUSE')
					and o.vendorID not in (org.contractor_id('E&N suppliers'))
			)
			merge acc.transactions as t using s
			on t.saleid = s.saleid 
				and t.barcodeid =  s.barcodeid
			when not matched then 	
				insert  (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid, barcodeid)
				values ( transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid, barcodeid)
				output inserted.transactionid, inserted.saleid, inserted.barcodeid into @transoutput	
			;
			with _entries (transactionid, is_credit, accountid, contractorid) as (
				select 
					t.transactionid,  
					s.is_credit 
					, s.accountid
					,	case 
							when  ((s.is_credit = 'true' and tr.transactiontypeid = inv.transactiontype_id ('return'))
									or 
									(s.is_credit = 'false' and tr.transactiontypeID <>inv.transactiontype_id ('return')))
									then null
							else o.vendorID
						end
				from @transOutput t
					join inv.inventory i on i.barcodeID = t.barcodeid 
					join inv.orders o on o.orderID= i.transactionID and o.orderclassID = 3
					join inv.transactions tr on tr.transactionID= t.saleid
					join inv.transactiontypes tt on tt.transactiontypeID= tr.transactiontypeID
					cross apply (
							select 
								iif (tr.transactiontypeID = inv.transactiontype_id('RETURN'), 'True', 'False') 
								, acc.account_id('товар')
								from inv.transactions tra 
									where tra.transactionID= tr.transactionID							
							union all 
							select 
								iif (tr.transactiontypeID = inv.transactiontype_id('RETURN'), 'False', 'True') 
								, acc.account_id('счета к оплате')
								from inv.transactions tra
									where tra.transactionID= tr.transactionID
						) as s(is_credit, accountid)
					where i.logstateID = inv.logstate_id('in-warehouse')
				)
				insert acc.entries(transactionid, is_credit, accountid, contractorid)
				select e.transactionid, e.is_credit, e.accountid, e.contractorid
				from _entries e		
				;

			select 
				t.transactionid, t.transdate, amount, t.comment, t.saleid, t.barcodeid, 
				case e.is_credit
					when 1 then 'Credit'
					else 'Debet' 
				end is_credit
				, a.account, c.contractor
			from acc.transactions t 
				join @transOutput tou on tou.transactionid=t.transactionid
				join acc.entries e on e.transactionid =t.transactionid
				join acc.accounts a on a.accountid=e.accountid
				left join org.contractors c on c.contractorID =e.contractorid
			order by 1 

--		;throw 50001, 'debuging' , 1 
		select @msg = null
		commit transaction
	end try
	begin catch
		select @msg = ERROR_MESSAGE()
		select @msg
		rollback transaction
	end catch
go 


--exec acc.ConsignmentSalesAPs 
        


