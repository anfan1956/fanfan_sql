USE [fanfan]
GO

if OBJECT_ID ('cmn.logCode_confirm_p') is not null drop proc cmn.logCode_confirm_p 

go

create proc cmn.logCode_confirm_p @code varchar(10), @userid int as
	set nocount on;
	if exists( 
	select code from hr.logAutorizations a where userid =@userid and a.used is null and a.code = @code)
		begin
			update a set a.used = 'True' from hr.logAutorizations a where a.userid=@userid;
			select 1
		end
	else 
		select 0
go


--set nocount on; declare @code char (5) = 49454, @userid int = org.person_id('БЕЗЗУБЦЕВА Е. В.'); exec cmn.logCode_confirm_p @code, @userid