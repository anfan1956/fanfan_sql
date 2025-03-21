USE [fanfan]
GO
/****** Object:  UserDefinedFunction [acc.holder_accounts_f]    Script Date: 20.10.2024 21:27:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [acc].[holder_accounts_f] (@holder varchar (50)) returns table as return
select c2.contractor bank, r.account 
from acc.registers r
	join org.clients c  on c.clientID=r.clientid
	join org.contractors c2 on c2.contractorID=r.bankid
where c.clientRus =  @holder 
	and left (r.account, 2) not in ('1c')
go

