-- Step 1: Check if the table exists and create it with `userid` if it does not exist
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'versionLogs' AND s.name = 'org'
)
BEGIN
    CREATE TABLE org.versionLogs (
        logid INT PRIMARY KEY IDENTITY(1,1), -- Auto-incrementing log ID
        workstationid INT NOT NULL,          -- Workstation ID (FK to org.workstations)
        versionNumber INT NOT NULL,          -- Current version of the workstation
        logtime DATETIME DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the log entry
        userid INT NULL,                     -- User ID (FK to org.users, nullable)
        CONSTRAINT FK_WorkstationLogs FOREIGN KEY (workstationid) REFERENCES org.workstations(workstationid),
        CONSTRAINT FK_UserLogs FOREIGN KEY (userid) REFERENCES org.users(userid)
    );
END;

-- Step 2: Check if the `userid` column exists in the table and add it if it does not
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'versionLogs' AND s.name = 'org' AND c.name = 'userid'
)
BEGIN
    -- Add the `userid` column
    ALTER TABLE org.versionLogs
    ADD userid INT NULL;

    -- Add the foreign key constraint for `userid`
    ALTER TABLE org.versionLogs
    ADD CONSTRAINT FK_UserLogs FOREIGN KEY (userid) REFERENCES org.users(userid);
END;
GO

--insert org.versionLogs (workstationid, versionNumber)  values (23, 1124)
select * from org.versionLogs
-- Step 1: Drop the procedure if it exists
IF OBJECT_ID('org.versionLogInsert', 'P') IS NOT NULL
    DROP PROCEDURE org.versionLogInsert;
GO

-- Step 2: Create the procedure
CREATE PROCEDURE org.versionLogInsert
    @workstationid INT,
    @versionNumber INT,
    @userid INT
AS

BEGIN
    SET NOCOUNT ON;

    -- Insert a new log entry into the org.versionLogs table
    INSERT INTO org.versionLogs (workstationid, versionNumber, userid)
    VALUES (@workstationid, @versionNumber, @userid);
END;
GO

--declare @r int; EXEC @r = org.versionLogInsert @workstationid = 23, @versionNumber = 1125, @userid = 1;select @r

-- Step 1: Drop the function if it already exists
IF OBJECT_ID('org.versionUpToDate', 'FN') IS NOT NULL
    DROP FUNCTION org.versionUpToDate;
GO

-- Step 2: Create the scalar function
CREATE FUNCTION org.versionUpToDate (@workstationid INT)
RETURNS BIT
AS
BEGIN
    DECLARE @latestVersion INT;
    DECLARE @currentWorkstationVersion INT;
	declare @result bit

    -- Get the latest version from the cmn.versions table for the given working_file
    SELECT TOP 1 @latestVersion = timesheetsversionID
    FROM cmn.versions
    WHERE working_file = 'timesheets.xlsm'
    ORDER BY versionID DESC;


    -- Get the current version of the workstation from the org.versionLogs table
    SELECT TOP 1 @currentWorkstationVersion = versionNumber
    FROM org.versionLogs
    WHERE workstationid = @workstationid
    ORDER BY logid DESC;

    -- Compare the versions and return 1 if up to date, otherwise 0
    IF @currentWorkstationVersion = @latestVersion
        select @result = 1; -- Up to date
    ELSE
        select @result = 0; -- Not up to date

	return @result
END;
GO

select org.versionUpToDate(23)