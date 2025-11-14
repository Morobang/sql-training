/*============================================================================
  Script:   generate-sample-data.sql
  Purpose:  Generate realistic sample data for TechStore database
  Database: TechStore
  
  Description:
  Creates a populated TechStore database with realistic customer orders,
  products, and transactional data. Useful for:
  - Testing queries and performance
  - Demonstrating data quality issues
  - Practicing data analysis
  - Learning data warehousing concepts
  
  Generates:
  - 100 customers across various cities
  - 50 products in different categories
  - 1000+ orders over 90-day period
  - Intentional data quality issues for training
  
  Author:       SQL Training Team
  Created:      2025-11-14
  Modified:     2025-11-14
  Version:      1.0
============================================================================*/

-- Create database
IF DB_ID('TechStore') IS NOT NULL
BEGIN
    PRINT 'Dropping existing TechStore database...';
    USE master;
    ALTER DATABASE TechStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TechStore;
END
GO

CREATE DATABASE TechStore;
GO

USE TechStore;
GO

PRINT 'Creating TechStore sample database...';
PRINT '';

/*----------------------------------------------------------------------------
  TABLE CREATION
----------------------------------------------------------------------------*/

-- Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    City VARCHAR(50),
    State VARCHAR(2),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    CustomerType VARCHAR(20) DEFAULT 'Standard'
);

-- Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) CHECK (Price >= 0),
    StockQuantity INT CHECK (StockQuantity >= 0),
    LastRestockedDate DATETIME,
    IsActive BIT DEFAULT 1
);

-- Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    Quantity INT DEFAULT 1 CHECK (Quantity > 0),
    LoadedAt DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

/*----------------------------------------------------------------------------
  GENERATE SAMPLE CUSTOMERS (100 customers)
----------------------------------------------------------------------------*/

PRINT 'Generating 100 sample customers...';

DECLARE @i INT = 1;
DECLARE @FirstNames TABLE (Name VARCHAR(50));
DECLARE @LastNames TABLE (Name VARCHAR(50));
DECLARE @Cities TABLE (City VARCHAR(50), State VARCHAR(2));

-- First names pool
INSERT INTO @FirstNames VALUES
('James'), ('Mary'), ('John'), ('Patricia'), ('Robert'), ('Jennifer'), ('Michael'), ('Linda'),
('William'), ('Barbara'), ('David'), ('Elizabeth'), ('Richard'), ('Susan'), ('Joseph'), ('Jessica'),
('Thomas'), ('Sarah'), ('Charles'), ('Karen'), ('Christopher'), ('Nancy'), ('Daniel'), ('Lisa'),
('Matthew'), ('Betty'), ('Anthony'), ('Margaret'), ('Mark'), ('Sandra'), ('Donald'), ('Ashley'),
('Steven'), ('Kimberly'), ('Paul'), ('Emily'), ('Andrew'), ('Donna'), ('Joshua'), ('Michelle'),
('Kenneth'), ('Dorothy'), ('Kevin'), ('Carol'), ('Brian'), ('Amanda'), ('George'), ('Melissa'),
('Edward'), ('Deborah'), ('Ronald'), ('Stephanie'), ('Timothy'), ('Rebecca'), ('Jason'), ('Sharon'),
('Jeffrey'), ('Laura'), ('Ryan'), ('Cynthia'), ('Jacob'), ('Kathleen'), ('Gary'), ('Amy'),
('Nicholas'), ('Shirley'), ('Eric'), ('Angela'), ('Jonathan'), ('Helen'), ('Stephen'), ('Anna');

-- Last names pool
INSERT INTO @LastNames VALUES
('Smith'), ('Johnson'), ('Williams'), ('Brown'), ('Jones'), ('Garcia'), ('Miller'), ('Davis'),
('Rodriguez'), ('Martinez'), ('Hernandez'), ('Lopez'), ('Gonzalez'), ('Wilson'), ('Anderson'), ('Thomas'),
('Taylor'), ('Moore'), ('Jackson'), ('Martin'), ('Lee'), ('Perez'), ('Thompson'), ('White'),
('Harris'), ('Sanchez'), ('Clark'), ('Ramirez'), ('Lewis'), ('Robinson'), ('Walker'), ('Young'),
('Allen'), ('King'), ('Wright'), ('Scott'), ('Torres'), ('Nguyen'), ('Hill'), ('Flores'),
('Green'), ('Adams'), ('Nelson'), ('Baker'), ('Hall'), ('Rivera'), ('Campbell'), ('Mitchell'),
('Carter'), ('Roberts'), ('Gomez'), ('Phillips'), ('Evans'), ('Turner'), ('Diaz'), ('Parker');

-- Cities pool
INSERT INTO @Cities VALUES
('New York', 'NY'), ('Los Angeles', 'CA'), ('Chicago', 'IL'), ('Houston', 'TX'),
('Phoenix', 'AZ'), ('Philadelphia', 'PA'), ('San Antonio', 'TX'), ('San Diego', 'CA'),
('Dallas', 'TX'), ('San Jose', 'CA'), ('Austin', 'TX'), ('Jacksonville', 'FL'),
('Fort Worth', 'TX'), ('Columbus', 'OH'), ('San Francisco', 'CA'), ('Charlotte', 'NC'),
('Indianapolis', 'IN'), ('Seattle', 'WA'), ('Denver', 'CO'), ('Boston', 'MA'),
('El Paso', 'TX'), ('Detroit', 'MI'), ('Nashville', 'TN'), ('Portland', 'OR'),
('Las Vegas', 'NV'), ('Oklahoma City', 'OK'), ('Tucson', 'AZ'), ('Atlanta', 'GA');

-- Generate customers
WHILE @i <= 100
BEGIN
    INSERT INTO Customers (FirstName, LastName, Email, City, State, CreatedDate, IsActive, CustomerType)
    SELECT TOP 1
        fn.Name,
        ln.Name,
        LOWER(fn.Name) + '.' + LOWER(ln.Name) + CAST(@i AS VARCHAR) + '@example.com',
        c.City,
        c.State,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 365), GETDATE()),  -- Random date in last year
        CASE WHEN @i % 20 = 0 THEN 0 ELSE 1 END,  -- 5% inactive
        CASE 
            WHEN @i % 10 = 0 THEN 'VIP'
            WHEN @i % 5 = 0 THEN 'Premium'
            ELSE 'Standard'
        END
    FROM @FirstNames fn
    CROSS JOIN @LastNames ln
    CROSS JOIN @Cities c
    ORDER BY NEWID();
    
    SET @i = @i + 1;
END

-- Add some data quality issues
UPDATE Customers SET FirstName = NULL WHERE CustomerID = 5;  -- Missing first name
UPDATE Customers SET Email = NULL WHERE CustomerID IN (10, 15);  -- Missing emails
INSERT INTO Customers (FirstName, LastName, Email, City, State)
VALUES ('John', 'Doe', 'john.doe1@example.com', 'New York', 'NY');  -- Duplicate name (different email)

PRINT 'Generated 100 customers with 3 data quality issues.';
PRINT '';

/*----------------------------------------------------------------------------
  GENERATE SAMPLE PRODUCTS (50 products)
----------------------------------------------------------------------------*/

PRINT 'Generating 50 sample products...';

-- Product categories and names
DECLARE @Products TABLE (
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    BasePrice DECIMAL(10,2)
);

INSERT INTO @Products VALUES
-- Electronics
('iPhone 15 Pro', 'Electronics', 999.99),
('Samsung Galaxy S24', 'Electronics', 899.99),
('MacBook Pro 16"', 'Electronics', 2499.99),
('Dell XPS 15', 'Electronics', 1799.99),
('iPad Air', 'Electronics', 599.99),
('Sony WH-1000XM5 Headphones', 'Electronics', 399.99),
('Apple Watch Series 9', 'Electronics', 429.99),
('Samsung 55" 4K TV', 'Electronics', 799.99),
('Nintendo Switch', 'Electronics', 299.99),
('PlayStation 5', 'Electronics', 499.99),
-- Accessories
('USB-C Cable 6ft', 'Accessories', 19.99),
('Wireless Mouse', 'Accessories', 29.99),
('Mechanical Keyboard', 'Accessories', 129.99),
('Laptop Stand', 'Accessories', 49.99),
('Phone Case', 'Accessories', 24.99),
('Screen Protector', 'Accessories', 14.99),
('External SSD 1TB', 'Accessories', 149.99),
('Webcam 1080p', 'Accessories', 79.99),
('Microphone USB', 'Accessories', 99.99),
('HDMI Cable 10ft', 'Accessories', 15.99),
-- Home & Garden
('Robot Vacuum', 'Home & Garden', 299.99),
('Air Purifier', 'Home & Garden', 199.99),
('Smart Thermostat', 'Home & Garden', 249.99),
('Security Camera', 'Home & Garden', 129.99),
('LED Light Bulbs 4-pack', 'Home & Garden', 29.99),
('Cordless Drill', 'Home & Garden', 89.99),
('Toolset 100-piece', 'Home & Garden', 149.99),
('Garden Hose 50ft', 'Home & Garden', 39.99),
('Outdoor Lights', 'Home & Garden', 59.99),
('Smart Lock', 'Home & Garden', 179.99),
-- Sports & Outdoors
('Yoga Mat', 'Sports & Outdoors', 29.99),
('Dumbbells Set', 'Sports & Outdoors', 99.99),
('Tent 4-Person', 'Sports & Outdoors', 149.99),
('Camping Backpack', 'Sports & Outdoors', 89.99),
('Running Shoes', 'Sports & Outdoors', 119.99),
('Bicycle', 'Sports & Outdoors', 499.99),
('Fishing Rod', 'Sports & Outdoors', 79.99),
('Kayak', 'Sports & Outdoors', 599.99),
('Skateboard', 'Sports & Outdoors', 69.99),
('Basketball', 'Sports & Outdoors', 24.99),
-- Office Supplies
('Office Chair', 'Office', 249.99),
('Standing Desk', 'Office', 399.99),
('Monitor 27"', 'Office', 299.99),
('Printer All-in-One', 'Office', 179.99),
('Paper Shredder', 'Office', 89.99),
('Whiteboard 4x3ft', 'Office', 79.99),
('Desk Organizer', 'Office', 34.99),
('Filing Cabinet', 'Office', 149.99),
('Desk Lamp LED', 'Office', 49.99),
('Notebook 5-pack', 'Office', 19.99);

-- Insert products with random stock
INSERT INTO Products (ProductName, Category, Price, StockQuantity, LastRestockedDate)
SELECT 
    ProductName,
    Category,
    BasePrice * (0.9 + (ABS(CHECKSUM(NEWID())) % 20) / 100.0),  -- ±10% price variation
    ABS(CHECKSUM(NEWID()) % 100) + 10,  -- Random stock 10-110
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 30), GETDATE())  -- Restocked within 30 days
FROM @Products;

-- Add data quality issues
UPDATE Products SET Price = -49.99 WHERE ProductID = 5;  -- Negative price
UPDATE Products SET StockQuantity = -10 WHERE ProductID = 10;  -- Negative stock
UPDATE Products SET LastRestockedDate = DATEADD(DAY, -180, GETDATE()) WHERE ProductID IN (15, 20);  -- Stale restock

PRINT 'Generated 50 products with 4 data quality issues.';
PRINT '';

/*----------------------------------------------------------------------------
  GENERATE SAMPLE ORDERS (1000+ orders over 90 days)
----------------------------------------------------------------------------*/

PRINT 'Generating 1000+ orders over 90-day period...';

DECLARE @OrderCount INT = 0;
DECLARE @TargetOrders INT = 1000;
DECLARE @DaysBack INT = 90;
DECLARE @CurrentDate DATETIME;

WHILE @OrderCount < @TargetOrders
BEGIN
    -- Random date in last 90 days
    SET @CurrentDate = DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % @DaysBack), GETDATE());
    
    -- Random customer, product, quantity
    INSERT INTO Orders (CustomerID, ProductID, OrderDate, Quantity, TotalAmount, LoadedAt, Status)
    SELECT TOP 1
        c.CustomerID,
        p.ProductID,
        @CurrentDate,
        ABS(CHECKSUM(NEWID()) % 5) + 1,  -- Quantity 1-5
        p.Price * (ABS(CHECKSUM(NEWID()) % 5) + 1),  -- Total = Price * Quantity
        DATEADD(MINUTE, ABS(CHECKSUM(NEWID()) % 120), @CurrentDate),  -- Loaded within 2 hours
        CASE ABS(CHECKSUM(NEWID()) % 10)
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'Cancelled'
            ELSE 'Shipped'
        END
    FROM Customers c
    CROSS JOIN Products p
    WHERE c.IsActive = 1
      AND p.IsActive = 1
    ORDER BY NEWID();
    
    SET @OrderCount = @OrderCount + 1;
END

-- Add data quality issues
UPDATE Orders SET TotalAmount = -100.00 WHERE OrderID = 50;  -- Negative amount
UPDATE Orders SET TotalAmount = 999999.99 WHERE OrderID = 75;  -- Suspicious high amount
UPDATE Orders SET LoadedAt = DATEADD(HOUR, -25, OrderDate) WHERE OrderID = 1;  -- Stale load (> 24 hours)

-- Create orphan orders (invalid references)
SET IDENTITY_INSERT Orders ON;
INSERT INTO Orders (OrderID, CustomerID, ProductID, OrderDate, TotalAmount, Quantity, LoadedAt, Status)
VALUES 
    (9999, 999, 1, GETDATE(), 100.00, 1, GETDATE(), 'Pending'),  -- Invalid CustomerID
    (9998, 1, 999, GETDATE(), 100.00, 1, GETDATE(), 'Pending');  -- Invalid ProductID
SET IDENTITY_INSERT Orders OFF;

PRINT 'Generated 1000+ orders with 5 data quality issues.';
PRINT '';

/*----------------------------------------------------------------------------
  CREATE INDEXES
----------------------------------------------------------------------------*/

PRINT 'Creating indexes for performance...';

CREATE INDEX IX_Customers_Email ON Customers(Email);
CREATE INDEX IX_Customers_City_State ON Customers(City, State);
CREATE INDEX IX_Products_Category ON Products(Category);
CREATE INDEX IX_Products_Price ON Products(Price);
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_Orders_ProductID ON Orders(ProductID);
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
CREATE INDEX IX_Orders_LoadedAt ON Orders(LoadedAt);

PRINT 'Indexes created.';
PRINT '';

/*----------------------------------------------------------------------------
  SUMMARY & VERIFICATION
----------------------------------------------------------------------------*/

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║        TECHSTORE SAMPLE DATABASE CREATED SUCCESSFULLY           ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';

SELECT 
    'Customers' AS TableName,
    COUNT(*) AS RowCount,
    MIN(CreatedDate) AS EarliestRecord,
    MAX(CreatedDate) AS LatestRecord
FROM Customers

UNION ALL

SELECT 
    'Products',
    COUNT(*),
    MIN(LastRestockedDate),
    MAX(LastRestockedDate)
FROM Products

UNION ALL

SELECT 
    'Orders',
    COUNT(*),
    MIN(OrderDate),
    MAX(OrderDate)
FROM Orders;

PRINT '';
PRINT 'Data Quality Issues (Intentional):';
PRINT '- Customers: 1 NULL FirstName, 2 NULL Emails';
PRINT '- Products: 1 negative price, 1 negative stock, 2 stale restock dates';
PRINT '- Orders: 1 negative amount, 1 suspicious high, 1 stale load, 2 orphans';
PRINT '';
PRINT 'Sample Queries to Try:';
PRINT '1. SELECT * FROM Customers WHERE City = ''New York'';';
PRINT '2. SELECT * FROM Products WHERE Category = ''Electronics'' ORDER BY Price DESC;';
PRINT '3. SELECT c.FirstName, COUNT(o.OrderID) AS OrderCount';
PRINT '   FROM Customers c LEFT JOIN Orders o ON c.CustomerID = o.CustomerID';
PRINT '   GROUP BY c.CustomerID, c.FirstName ORDER BY OrderCount DESC;';
PRINT '';

/*============================================================================
  END OF SCRIPT
============================================================================*/
