USE [fanfan]
GO

--this is the correct version of acc.registers and  acc.accounts_cards

if OBJECT_ID('acc.accounts_cards') is not null drop table acc.accounts_cards
if OBJECT_ID('acc.registers') is not null drop table acc.registers


CREATE TABLE acc.registers(
	[registerid] [int] IDENTITY(1,1) NOT NULL,
	[bankid] [int] NOT NULL,
	[currencyid] [int] NOT NULL,
	[account] [varchar](24) not NULL,
	[clientid] [int] NULL
 CONSTRAINT [pk_acc_registers] PRIMARY KEY CLUSTERED 
(
	[registerid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_acc_registers] UNIQUE NONCLUSTERED 
(
	[account] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE acc.registers  WITH CHECK ADD  CONSTRAINT [fk_acc_registers] FOREIGN KEY([bankid])
REFERENCES [org].[contractors] ([contractorid])
GO

ALTER TABLE acc.registers CHECK CONSTRAINT [fk_acc_registers]
GO

ALTER TABLE acc.registers  WITH CHECK ADD  CONSTRAINT [fk_acc_registers_currencies] FOREIGN KEY([currencyid])
REFERENCES [cmn].[currencies] ([currencyID])
GO

ALTER TABLE acc.registers CHECK CONSTRAINT [fk_acc_registers_currencies]
GO

ALTER TABLE acc.registers  WITH CHECK ADD  CONSTRAINT [fk_acc_registers_clients] FOREIGN KEY([clientid])
REFERENCES [org].[contractors] ([contractorid])
GO

ALTER TABLE acc.registers CHECK CONSTRAINT [fk_acc_registers_clients]
GO


insert acc.registers (bankid, currencyid, account, clientid)
values 
(179, 643, 'hc 07 ФАНФАН', 619),
(179, 643, '1c 07 ФАНФАН', 619), 
(619, 643, 'hc 08 ФАНФАН', 619),
(619, 643, '1c 08 ФАНФАН', 619), 
(619, 643, 'hc 05 УИКЕНД', 619),
(619, 643, '1c 05 УИКЕНД', 619),
(585, 643, '40817810900014646072', 269), 
(585, 643, '408028107000 02267131', 619) 

select * from acc.registers


--select * from org.banks b
--join org.contractors c on c.contractorID=b.bankID
--where b.active = 'TRue'

if OBJECT_ID('acc.bankcards') is not null drop table acc.bankcards
create table acc.bankcards (
	cardid int not null identity primary key,
	cardnumber char(16) not null,
	valid char (7) not null,
	holderid int  not null constraint fk_cardholders foreign key references org.persons (personid),
	name_on_card varchar(50) not null,
	constraint uq_bankcards unique (cardnumber, valid)
)
go
create table acc.accounts_cards (
	registerid int not null constraint fk_accounts_registers foreign key references acc.registers (registerid), 
	cardid int not null constraint fk_accounts_cards foreign key references acc.bankcards (cardid),
	dateattached date not null, 
	constraint pk_accounts_cards primary key (registerid, cardid, dateattached)
)
insert acc.bankcards(cardnumber, valid, holderid, name_on_card) values ('5280413752350988', '10/2029', 1, 'ALEKSANDR FEDOROV')
select * from acc.bankcards;
insert acc.accounts_cards (registerid, cardid, dateattached)
values (7, 1, '20220101' )
select * from acc.accounts_cards