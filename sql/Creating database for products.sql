-- Drop tables if they exist in the correct order
IF OBJECT_ID('dbo.OrderBalancesDue', 'U') IS NOT NULL DROP TABLE dbo.OrderBalancesDue;
IF OBJECT_ID('dbo.Shipments', 'U') IS NOT NULL DROP TABLE dbo.Shipments;
IF OBJECT_ID('dbo.Deposits', 'U') IS NOT NULL DROP TABLE dbo.Deposits;
IF OBJECT_ID('dbo.Barcodes', 'U') IS NOT NULL DROP TABLE dbo.Barcodes;
IF OBJECT_ID('dbo.Styles', 'U') IS NOT NULL DROP TABLE dbo.Styles;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.CustomerContacts', 'U') IS NOT NULL DROP TABLE dbo.CustomerContacts;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Currencies', 'U') IS NOT NULL DROP TABLE dbo.Currencies;
IF OBJECT_ID('dbo.Vendors', 'U') IS NOT NULL DROP TABLE dbo.Vendors;
IF OBJECT_ID('dbo.OrderStatuses', 'U') IS NOT NULL DROP TABLE dbo.OrderStatuses;
IF OBJECT_ID('dbo.Colors', 'U') IS NOT NULL DROP TABLE dbo.Colors;
IF OBJECT_ID('dbo.Sizes', 'U') IS NOT NULL DROP TABLE dbo.Sizes;

go
-- Create Customers table
CREATE TABLE Customers (
    CustomerID INT IDENTITY PRIMARY KEY, 
    CustomerName VARCHAR(255) NOT NULL UNIQUE
);

-- Create CustomerContacts table
CREATE TABLE CustomerContacts (
    CustomerID INT NOT NULL,
    CustomerContactType VARCHAR(255) NOT NULL,
    CustomerContact VARCHAR(255) NOT NULL,
    PRIMARY KEY (CustomerID, CustomerContactType, CustomerContact),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Create Currencies table
CREATE TABLE Currencies (
    CurrencyID INT IDENTITY PRIMARY KEY,
    CurrencyCode VARCHAR(3) NOT NULL UNIQUE,
    CurrencyName VARCHAR(50) NOT NULL UNIQUE
);

-- Create Vendors table
CREATE TABLE Vendors (
    VendorID INT IDENTITY PRIMARY KEY,
    VendorName VARCHAR(255) NOT NULL UNIQUE
);

-- Create OrderStatuses table
CREATE TABLE OrderStatuses (
    StatusID INT IDENTITY PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

-- Insert predefined statuses into OrderStatuses table
INSERT INTO OrderStatuses (StatusName) VALUES ('Ordered'), ('Deposit Paid'), ('Ready to Ship');

-- Create Orders table
CREATE TABLE Orders (
    OrderID INT IDENTITY PRIMARY KEY,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CustomerID INT NOT NULL,
    CurrencyID INT NOT NULL,
    VendorID INT NOT NULL,
    StatusID INT NOT NULL,
    DepositRequiredRate DECIMAL(5, 2) NOT NULL DEFAULT 0.0,
    BalanceRequired BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (CurrencyID) REFERENCES Currencies(CurrencyID),
    FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID),
    FOREIGN KEY (StatusID) REFERENCES OrderStatuses(StatusID)
);

-- Create Styles table
CREATE TABLE Styles (
    StyleID INT IDENTITY PRIMARY KEY,
    OrderID INT,
    Article VARCHAR(255),
    Cost DECIMAL(10, 2) NOT NULL,
    CONSTRAINT uqStyles UNIQUE (OrderID, Article),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Create Colors table
CREATE TABLE Colors (
    ColorID INT IDENTITY PRIMARY KEY,
    ColorName VARCHAR(50) NOT NULL
);

-- Create Sizes table
CREATE TABLE Sizes (
    SizeID INT IDENTITY PRIMARY KEY,
    SizeName VARCHAR(50) NOT NULL
);

-- Create Barcodes table
CREATE TABLE Barcodes (
    BarcodeID INT IDENTITY PRIMARY KEY,
    StyleID INT NOT NULL,
    ColorID INT NOT NULL,
    SizeID INT NOT NULL,
    FOREIGN KEY (StyleID) REFERENCES Styles(StyleID),
    FOREIGN KEY (ColorID) REFERENCES Colors(ColorID),
    FOREIGN KEY (SizeID) REFERENCES Sizes(SizeID)
);

-- Create Deposits table
CREATE TABLE Deposits (
    DepositID INT IDENTITY PRIMARY KEY,
    OrderID INT NOT NULL,
    DepositAmount DECIMAL(10, 2) NOT NULL,
    DepositDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Create Shipments table
CREATE TABLE Shipments (
    ShipmentID INT IDENTITY PRIMARY KEY,
    OrderID INT NOT NULL,
    ShipmentDate DATETIME,
    BalancePaid BIT NOT NULL DEFAULT 0,
    ReadyForShipment BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Create OrderBalancesDue table
CREATE TABLE OrderBalancesDue (
    BalanceDueID INT IDENTITY PRIMARY KEY,
    OrderID INT NOT NULL,
    OutstandingAmount DECIMAL(10, 2) NOT NULL,
    DueDate DATETIME NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
go
-- Drop the procedure if it already exists
IF OBJECT_ID('dbo.usp_RecordPayment', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_RecordPayment;
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.usp_RecordPayment
    @OrderID INT,
    @PaymentAmount DECIMAL(10, 2),
    @PaymentDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert the payment into the Deposits table
        INSERT INTO Deposits (OrderID, DepositAmount, DepositDate)
        VALUES (@OrderID, @PaymentAmount, @PaymentDate);

        -- Update the order status based on the payment
        DECLARE @TotalPaid DECIMAL(10, 2);
        SELECT @TotalPaid = SUM(DepositAmount) FROM Deposits WHERE OrderID = @OrderID;

        DECLARE @OrderTotal DECIMAL(10, 2);
        SELECT @OrderTotal = SUM(Cost) FROM Styles WHERE OrderID = @OrderID;

        DECLARE @DepositRequiredRate DECIMAL(5, 2);
        SELECT @DepositRequiredRate = DepositRequiredRate FROM Orders WHERE OrderID = @OrderID;

        DECLARE @DepositRequiredAmount DECIMAL(10, 2);
        SET @DepositRequiredAmount = @OrderTotal * @DepositRequiredRate / 100;

        IF @TotalPaid >= @DepositRequiredAmount
        BEGIN
            -- Update order status to 'Deposit Paid'
            UPDATE Orders
            SET StatusID = (SELECT StatusID FROM OrderStatuses WHERE StatusName = 'Deposit Paid')
            WHERE OrderID = @OrderID;
        END

        IF @TotalPaid >= @OrderTotal
        BEGIN
            -- Update order status to 'Ready to Ship'
            UPDATE Orders
            SET StatusID = (SELECT StatusID FROM OrderStatuses WHERE StatusName = 'Ready to Ship')
            WHERE OrderID = @OrderID;

            -- Mark the balance as paid in the Shipments table
            UPDATE Shipments
            SET BalancePaid = 1
            WHERE OrderID = @OrderID;
        END

        -- Update the OrderBalancesDue table
        DECLARE @OutstandingAmount DECIMAL(10, 2);
        SET @OutstandingAmount = @OrderTotal - @TotalPaid;

        IF @OutstandingAmount > 0
        BEGIN
            -- Insert or update the outstanding balance
            IF EXISTS (SELECT 1 FROM OrderBalancesDue WHERE OrderID = @OrderID)
            BEGIN
                UPDATE OrderBalancesDue
                SET OutstandingAmount = @OutstandingAmount, DueDate = DATEADD(month, 1, @PaymentDate)
                WHERE OrderID = @OrderID;
            END
            ELSE
            BEGIN
                INSERT INTO OrderBalancesDue (OrderID, OutstandingAmount, DueDate)
                VALUES (@OrderID, @OutstandingAmount, DATEADD(month, 1, @PaymentDate));
            END
        END
        ELSE
        BEGIN
            -- Remove the balance due record if the outstanding amount is zero
            DELETE FROM OrderBalancesDue WHERE OrderID = @OrderID;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Return the error information
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
select * from OrderStatuses