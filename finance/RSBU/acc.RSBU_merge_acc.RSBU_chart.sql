if OBJECT_ID ('acc.RSBU_merge') is not null drop proc acc.RSBU_merge
go 

create proc acc.RSBU_merge @info dbo.id_id_type readonly as
begin
	set nocount on;
	declare @r int;
	with s (accountid, rsbuSubId) as (
		select i.id1, i.id2 from @info i
		)
	merge acc.accounts as t using s
	on t.accountid= s.accountid
	when matched and isnull(t.rsbuSubID, 0) <> isnull(s.rsbuSubID, 0)
		then update 
		set t.rsbuSubId = s.rsbuSubId;
	select @r = @@ROWCOUNT;
	return @r;
end 
go

--declare @info dbo.id_id_type, @r int; insert @info values (1,null), (2,null); exec @r = acc.RSBU_merge @info; select @r;
if OBJECT_ID('acc.RSBU_chart_v') is not null drop view acc.RSBU_chart_v
go
create view acc.RSBU_chart_v as

select sec.sectionid,  sec.section, a.accountid, a.account, s.subaccount_num, s.subaccount, s.subaccountid
from acc.RSBU_subaccounts s
	join acc.RSBU_accounts a on a.accountid=s.accountid
	join acc.RSBU_sections sec on sec.sectionid=a.sectionid
go

select subaccountid, account, subaccount_num, section, subaccount from acc.RSBU_chart_v order by 1

select * From acc.accounts a

 


select * from acc.accounts