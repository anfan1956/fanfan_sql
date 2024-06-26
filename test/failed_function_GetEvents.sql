-- Use the FunJobs database
USE FunJobs;
GO

-- Step 1: Insert the company GlowByte into the companies table
IF NOT EXISTS (SELECT * FROM hr.companies WHERE name = 'GlowByte')
BEGIN
    INSERT INTO hr.companies (name) VALUES ('GlowByte');
END
GO

-- Step 2: Insert the person Валентина Макарова into the persons table
IF NOT EXISTS (SELECT * FROM hr.persons WHERE name = N'Валентина Макарова')
BEGIN
    INSERT INTO hr.persons (name) VALUES (N'Валентина Макарова');
END
GO

-- Step 3: Insert the contact information into the personsContacts table
DECLARE @person_id INT;
SELECT @person_id = person_id FROM hr.persons WHERE name = N'Валентина Макарова';

IF NOT EXISTS (SELECT * FROM hr.personsContacts WHERE person_id = @person_id AND contact = '@felinoe' AND contact_type = 'Telegram')
BEGIN
    INSERT INTO hr.personsContacts (person_id, contact, contact_type) VALUES (@person_id, '@felinoe', 'Telegram');
END
GO

-- Step 4: Insert the event into the interviewEvents table
DECLARE @company_id INT;
DECLARE @position_id INT = NULL; -- Position is null
DECLARE @applicant_id INT = (SELECT applicant_id FROM hr.applicants WHERE email = 'alexander.n.fedorov@gmail.com');
DECLARE @event_type_id INT = (SELECT event_type_id FROM hr.eventTypes WHERE type = 'Interview');
DECLARE @event_date DATETIME =  + '20240616 15:00:00'; -- Next Monday at 3 PM

SELECT @company_id = company_id FROM hr.companies WHERE name = 'GlowByte';

declare @person_id int  = 1
select @applicant_id = 1;

EXEC hr.sp_CreateEventForApplicant 
    @applicant_id = @applicant_id,
    @event_date = @event_date,
    @event_type_id = @event_type_id,
    @company_id = @company_id,
    @position_id = @position_id,
    @person_id = @person_id;
GO
select * from hr.persons
select * from hr.personsContacts
select * from hr.fn_GetApplicantStatus (1)