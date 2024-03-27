if OBJECT_ID('cust.customerDiscount_') is not null drop function cust.customerDiscount_
go

create function cust.customerDiscount_(@personid int) returns numeric(4,3) as
begin
	declare @discount numeric(4,3)

	; with _lastYear as (
		select 		isnull(sum (g.amount), 0) total
		from cust.persons p
			left join inv.sales s on s.customerID=p.personID
			left join inv.sales_goods g on g.saleID=s.saleID
			left join inv.transactions t on t.transactionID=s.saleID 
		where p.personID=@personid 
			and t.transactiondate>=DATEADD(YYYY, -1, dbo.justdate(getdate()))

		)
		, _earned as (select l.discountlevelID, l.min_amount, y.total
						from cust.discount_levels l
							cross apply _lastYear y   
						where l.discountlevelID <=20
		)
	, _all as (select discountlevelID , ROW_NUMBER() over (order by discountlevelid desc) num
				from _earned where total>=min_amount
			)
	, _level as (
			select top 1 
				case pp.customermode
					when 'M' then pp.discountlevelID
					when 'A' then (select discountlevelID from _all where num =1)
					end discountlevelid
			from cust.persons_programs pp
				cross apply _all a
			where pp.personID = @personid
	)

	select @discount = d.discount 
	from _level l
		join cust.discount_levels d on d.discountlevelID=l.discountlevelid
	return @discount
end
go

declare @personid int = 
	--14995;
	--17460 
	4
select cust.customerDiscount_(@personid)