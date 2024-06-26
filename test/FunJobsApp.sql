-- Step 1: Check if Database Exists and Drop if Needed
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'FunJobs')
BEGIN
    ALTER DATABASE FunJobs SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FunJobs;
END
GO

-- Step 2: Create the Database
CREATE DATABASE FunJobs;
GO

-- Use the FunJobs database
USE FunJobs;
GO

-- Step 3: Create Schema and Tables
-- Create schema hr
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'hr')
BEGIN
    EXEC('CREATE SCHEMA hr');
END
GO

-- Create table companies with unique names
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'companies' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.companies (
        company_id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) UNIQUE NOT NULL
    );
END
GO

-- Create table positions with unique names, nullable
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'positions' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.positions (
        position_id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) UNIQUE
    );
END
GO

-- Create table persons
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'persons' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.persons (
        person_id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL
    );
END
GO

-- Create table personsCompanies
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'personsCompanies' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.personsCompanies (
        person_id INT NOT NULL,
        company_id INT NOT NULL,
        PRIMARY KEY (person_id, company_id),
        FOREIGN KEY (person_id) REFERENCES hr.persons(person_id),
        FOREIGN KEY (company_id) REFERENCES hr.companies(company_id)
    );
END
GO

-- Create table eventTypes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'eventTypes' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.eventTypes (
        event_type_id INT IDENTITY(1,1) PRIMARY KEY,
        type NVARCHAR(255) NOT NULL
    );
END
GO

-- Insert initial event types
IF NOT EXISTS (SELECT * FROM hr.eventTypes)
BEGIN
    INSERT INTO hr.eventTypes (type) VALUES ('Interview'), ('Meeting'), ('Call'), ('Offer'), ('Rejection');
END
GO

-- Create table applicants
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'applicants' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.applicants (
        applicant_id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        email NVARCHAR(255) UNIQUE NOT NULL,
        password_hash NVARCHAR(255) NOT NULL,
        salt NVARCHAR(255) NOT NULL
    );
END
ELSE
BEGIN
    -- Ensure the table has the necessary columns
    IF COL_LENGTH('hr.applicants', 'password_hash') IS NULL
    BEGIN
        ALTER TABLE hr.applicants ADD password_hash NVARCHAR(255) NOT NULL;
    END
    IF COL_LENGTH('hr.applicants', 'salt') IS NULL
    BEGIN
        ALTER TABLE hr.applicants ADD salt NVARCHAR(255) NOT NULL;
    END
END
GO

-- Create table interviewEvents
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'interviewEvents' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.interviewEvents (
        event_id INT IDENTITY(1,1) PRIMARY KEY,
        event_date DATETIME NOT NULL,
        event_type_id INT NOT NULL,
        company_id INT NOT NULL,
        position_id INT,
        applicant_id INT NOT NULL,
        person_id INT NOT NULL,
        FOREIGN KEY (event_type_id) REFERENCES hr.eventTypes(event_type_id),
        FOREIGN KEY (company_id) REFERENCES hr.companies(company_id),
        FOREIGN KEY (position_id) REFERENCES hr.positions(position_id),
        FOREIGN KEY (applicant_id) REFERENCES hr.applicants(applicant_id),
        FOREIGN KEY (person_id) REFERENCES hr.persons(person_id)
    );
END
GO

-- Create table personsContacts
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'personsContacts' AND schema_id = SCHEMA_ID('hr'))
BEGIN
    CREATE TABLE hr.personsContacts (
        contact_id INT IDENTITY(1,1) PRIMARY KEY,
        person_id INT NOT NULL,
        contact NVARCHAR(255) NOT NULL,
        contact_type NVARCHAR(50) NOT NULL,
        FOREIGN KEY (person_id) REFERENCES hr.persons(person_id)
    );
END
GO

-- Create a stored procedure to add a new user with hashed password
IF OBJECT_ID('hr.sp_AddUser', 'P') IS NOT NULL
    DROP PROCEDURE hr.sp_AddUser;
GO

CREATE PROCEDURE hr.sp_AddUser
    @name NVARCHAR(255),
    @email NVARCHAR(255),
    @password NVARCHAR(255)
AS
BEGIN
    DECLARE @salt NVARCHAR(255) = CONVERT(NVARCHAR(255), NEWID());
    DECLARE @password_hash NVARCHAR(255) = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password + @salt), 2);

    INSERT INTO hr.applicants (name, email, password_hash, salt)
    VALUES (@name, @email, @password_hash, @salt);
END
GO

-- Create a stored procedure to validate user login
IF OBJECT_ID('hr.sp_ValidateUser', 'P') IS NOT NULL
    DROP PROCEDURE hr.sp_ValidateUser;
GO

CREATE PROCEDURE hr.sp_ValidateUser
    @email NVARCHAR(255),
    @password NVARCHAR(255)
AS
BEGIN
    DECLARE @stored_hash NVARCHAR(255);
    DECLARE @stored_salt NVARCHAR(255);
    DECLARE @input_hash NVARCHAR(255);

    SELECT @stored_hash = password_hash, @stored_salt = salt
    FROM hr.applicants
    WHERE email = @email;

    SET @input_hash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password + @stored_salt), 2);

    IF @stored_hash = @input_hash
    BEGIN
        SELECT 'Login successful' AS Message;
    END
    ELSE
    BEGIN
        SELECT 'Invalid email or password' AS Message;
    END
END
GO

-- Create a stored procedure to create an event for an applicant
IF OBJECT_ID('hr.sp_CreateEventForApplicant', 'P') IS NOT NULL
    DROP PROCEDURE hr.sp_CreateEventForApplicant;
GO

CREATE PROCEDURE hr.sp_CreateEventForApplicant
    @applicant_id INT,
    @event_date DATETIME,
    @event_type_id INT,
    @company_id INT,
    @position_id INT,
    @person_id INT
AS
BEGIN
    -- Check if the last event for the applicant is 'Offer' or 'Rejection'
    DECLARE @last_event_type NVARCHAR(255);

    SELECT TOP 1 @last_event_type = et.type
    FROM hr.interviewEvents ie
    JOIN hr.eventTypes et ON ie.event_type_id = et.event_type_id
    WHERE ie.applicant_id = @applicant_id
    ORDER BY ie.event_date DESC;

    IF @last_event_type IN ('Offer', 'Rejection')
    BEGIN
        RAISERROR('Cannot schedule a new event. The last event was an Offer or Rejection.', 16, 1);
        RETURN;
    END

    -- Insert the new event
    INSERT INTO hr.interviewEvents (event_date, event_type_id, company_id, position_id, applicant_id, person_id)
    VALUES (@event_date, @event_type_id, @company_id, @position_id, @applicant_id, @person_id);
END
GO

-- Create a table-valued function to show the latest event status for an applicant
IF OBJECT_ID('hr.fn_GetApplicantStatus', 'IF') IS NOT NULL
    DROP FUNCTION hr.fn_GetApplicantStatus;
GO

CREATE FUNCTION hr.fn_GetApplicantStatus (@applicant_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        c.name AS company,
        p.name AS position,
        et.type AS status,
        ie.event_date
    FROM hr.interviewEvents ie
    JOIN hr.companies c ON ie.company_id = c.company_id
    JOIN hr.positions p ON ie.position_id = p.position_id
    JOIN hr.eventTypes et ON ie.event_type_id = et.event_type_id
    WHERE ie.applicant_id = @applicant_id
    ORDER BY ie.event_date DESC
);
GO

-- Add user alexander.n.fedorov@gmail.com with password "Gisele12!"
EXEC hr.sp_AddUser @name = 'Alexander Fedorov', @email = 'alexander.n.fedorov@gmail.com', @password = 'Gisele12!';
GO

-- Add event with GlowByte company for the multiple position (null), person Валентина Макарова, contact Telegram, @felinoe for the next Monday at 3
