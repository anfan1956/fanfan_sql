USE [fanfan]
GO

/****** Object:  View [rep].[v_salesreport_today]    Script Date: 26.10.2025 20:43:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [rep].[v_salesreport_today]
	as 
select sr.*
from rep.v_salesreport sr
where dbo.justdate( getdate() ) = sr.date
GO


select * from [rep].[v_salesreceipts]
where cast(date as date) = cast(getdate() as date)