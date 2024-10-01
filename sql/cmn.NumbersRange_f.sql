use TESTING
go 

IF OBJECT_ID('Departments', 'U') IS NOT NULL
  DROP TABLE departments		
IF OBJECT_ID('Persons', 'U') IS NOT NULL
  DROP TABLE persons		
GO


CREATE TABLE Persons
(
	Id int identity primary key, 
	FirstName varchar(50), 
	LastName varchar(50), 
	Constraint uq_persons Unique (FirstName, LastName)
)

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100),
    ParentDepartmentID INT NULL,
    FOREIGN KEY (ParentDepartmentID) REFERENCES Departments(DepartmentID)
);
INSERT INTO Departments (DepartmentName, ParentDepartmentID) VALUES
('Head Office', NULL),
('HR Department', 1),
('IT Department', 1),
('Recruitment', 2),
('Employee Relations', 2),
('Software Development', 3),
('Network Administration', 3);






insert persons(FirstName, LastName)
values ('John', 'Smith'), ('Jane', 'Doe'), ('Alice', 'McDoug'), ('Bob', 'Sinclair'), ('Charlie', 'Tudor'), ('Lena', 'English'), ('Peter', 'Gabriel');

select * from Departments

select * from persons

