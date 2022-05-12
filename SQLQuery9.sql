use anfan_release
go

;
use fanfan
go
if OBJECT_ID('rep.cash_on_date') is not null drop proc rep.cash_on_date
go
create proc rep.cash_on_date  @user varchar (37), @date date = null
as
declare @mydate date = isnull(@date, getdate());


with _user (userid) as (
	select userid from fanfan.org.users u
		where username = @user and u.roleID in  (2,3)
)
, s (������, ���, �����) As (
	select ������, ���_�����
		, sum(isnull(�����, 0) * anfan_release.acc.current_rate_cur(������)) �����
	from anfan_release.acc.cash_daily_f(@mydate)
	group by ������, ���_�����
	having  sum(isnull(�����, 0) * anfan_release.acc.current_rate_cur(������))>0
)
select s.������, s.���, 
	format (s.�����, '#,##0') �����,
	format (sum(s.�����) over (), '#,##0') �����
from s
	cross apply _user

;
go

declare @user varchar (37) = '�������� �. �.';
exec rep.cash_on_date @user, @date  = '20220511';


use anfan_release
select * from acc.currencies c
join  acc.rates_latest_v v on v.currencyid= c.currencyid


if OBJECT_ID('acc.current_rate') is not null drop function acc.current_rate
go
create function acc.current_rate(@currencyid int ) returns decimal (10, 4) as
begin
	declare @rate decimal (10,4);
		select @rate=rate from acc.rates_latest_v v where v.currencyid =@currencyid
	return @rate;
end
go
if OBJECT_ID('acc.current_rate_cur') is not null drop function acc.current_rate_cur
go
create function acc.current_rate_cur(@currency char(3) ) returns decimal (10, 4) as
begin
	declare @rate decimal (10,4);
		select @rate=rate from acc.rates_latest_v v 
			join acc.currencies c on c.currencyid=v.currencyid
		where c.currency =@currency
	return @rate;
end

go 
select * from fanfan.org.users;
