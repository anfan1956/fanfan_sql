USE [fanfan]
GO
/****** Object:  StoredProcedure [cust].[totals_update]    Script Date: 05.09.2022 20:10:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [cust].[totals_update]
as
begin
	set nocount on;

	with 
	_tc as (
		select personID, programID, sum( amount ) as turnover_calc
		from (
			select sls.customerID as personID, cp.programID, 
			isnull( iif( s.transactiontypeID in ( inv.transactiontype_id( 'SALE' ), inv.transactiontype_id( 'SALE CASH' )), sp.amount, -sp.amount ), 0 ) 
							as amount
			from inv.transactions s
				join inv.sales sls on sls.saleID = s.transactionID
				join cust.programs_clients cp on cp.clientID = org.client_id( sls.divisionID ) 
				join inv.sales_receipts sp on sp.saleID = s.transactionID
			where dbo.justdate( s.transactiondate ) >= dateadd( yy, -1, dbo.justdate( getdate() ) )

		) as a
		group by personID, programID
	),
	_tt as (
		select personID, programID, sum( amount ) as turnover_total
		from (
			select sls.customerID as personID, cp.programID, 
			isnull( iif( s.transactiontypeID in ( inv.transactiontype_id( 'SALE' ), inv.transactiontype_id( 'SALE CASH' )), sp.amount, -sp.amount ), 0 ) 
							as amount
			from inv.transactions s
				join inv.sales sls on sls.saleID = s.transactionID
				join cust.programs_clients cp on cp.clientID = org.client_id( sls.divisionID ) 
				join inv.sales_receipts sp on sp.saleID = s.transactionID

		) as a
		group by personID, programID
	),

	_turnovers as (
		select t.personID, t.programID, isnull( c.turnover_calc, 0 ) as turnover_calc, isnull( t.turnover_total, 0 ) as turnover_total
		from cust.persons p 
			left join _tt t on t.personID = p.personID
			left join _tc c on c.personID = t.personID and c.programID = t.programID
	)

	merge cust.persons_programs as trg
	using	( 
			select personID, programID, turnover_calc, turnover_total 
			from _turnovers 
			where personID is not null 
			) as src
	on trg.personID = src.personID and trg.programID = src.programID
	when matched then
		update set turnover_calc = src.turnover_calc, turnover_total = src.turnover_total
	when not matched then
		insert ( personID, programID, discountlevelID, customermode, turnover_calc, turnover_total, daystochange, nextdiscountlevelID ) values
				( src.personID, src.programID, 1, 'A', src.turnover_calc, src.turnover_total, 0, 1 );

	update pp set discountlevelID = dl.discountlevelID
	from cust.discount_levels dl
		join cust.persons_programs pp on pp.turnover_calc >= dl.min_amount and pp.turnover_calc <= dl.max_amount
	where pp.customermode in ( 'A', 'X' );

	with
	_sls as (
		select s.customerID as personID, dbo.justdate( t.transactiondate ) as dt, pc.programID, sum( sr.amount ) as amount
		from inv.sales s
			join inv.sales_receipts sr on sr.saleID = s.saleID
			join inv.transactions t on t.transactionID = s.saleID
			join cust.programs_clients pc on pc.clientID = org.client_id( s.divisionID )
		group by s.customerID, dbo.justdate( t.transactiondate ), pc.programID
		union all
		select pf.personID, pf.turnover_date, pf.programID, sum( pf.turnover_fake )
		from cust.persons_faketurnovers pf
		group by pf.personID, pf.turnover_date, pf.programID 
	),
	_track as (
		select s.personID, s.programID, dt, pp.discountlevelID, pp.turnover_calc - sum( s.amount ) over( partition by s.personID, s.programID order by dt ) as turnover_next
		from _sls s
			join cust.persons_programs pp on pp.personID = s.personID and pp.programID = s.programID 
		where dt >= dateadd( yy, -1, dbo.justdate( getdate() ) )
		  and pp.customermode in ( 'A', 'X' )
	),
	_dlchange as (
		select t.personID, t.programID, t.dt, t.discountlevelID as level_cur, dl.discountlevelID as level_next
		from _track t
			cross join cust.discount_levels dl
		where t.turnover_next between dl.min_amount and dl.max_amount
	),
	_datechange as (
		select *, rank() over( partition by personID, programID order by dt ) as rnk
		from _dlchange 
		where level_cur > level_next
	),
	_res as (
		select personID, programID, level_next, datediff( dd, dbo.justdate( getdate() ), dateadd( yy, 1, dt ) ) as dtdiff
		from _datechange where rnk = 1
	)
	update pp set daystochange = r.dtdiff, nextdiscountlevelID = r.level_next
	from _res r
		join cust.persons_programs pp on pp.personID = r.personID and pp.programID = r.programID;

-- если у клиента скидка когда-нибудь поднималась больше 0, то его минимальная скидка всегда - 3%
-- устанавливаем тек.скидку 3% и след.скидку 3%
	update pp set pp.discountlevelID = dl.discountlevelID, pp.nextdiscountlevelID = dl.discountlevelID
	from cust.persons_programs pp
		cross join cust.discount_levels dl
	where pp.customermode = 'A'
	  and pp.discountlevelID = 1
	  and pp.turnover_total >= dl.min_amount and dl.discount = 0.03
-- устанавливаем след.скидку 3%
	update pp set pp.nextdiscountlevelID = dl.discountlevelID
	from cust.persons_programs pp
		cross join cust.discount_levels dl
	where pp.customermode = 'A'
	  and pp.nextdiscountlevelID = 1
	  and pp.turnover_total >= dl.min_amount and dl.discount = 0.03

	return 0
end

