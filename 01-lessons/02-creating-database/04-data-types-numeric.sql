-- ============================================================================
-- Lesson 04: Numeric Data Types
-- ============================================================================
-- Learn to work with numbers in SQL Server

USE BookStore;
GO

PRINT 'Lesson 04: Numeric Data Types';
PRINT '=============================';
PRINT '';

-- ============================================================================
-- Concept 1: Integer Types
-- ============================================================================

PRINT 'Concept 1: Integer Types';
PRINT '-----------------------';
PRINT 'TINYINT  - 0 to 255 (1 byte)';
PRINT 'SMALLINT - -32,768 to 32,767 (2 bytes)';
PRINT 'INT      - -2.1B to 2.1B (4 bytes) - most common';
PRINT 'BIGINT   - -9.2 quintillion to 9.2 quintillion (8 bytes)';
PRINT '';

CREATE TABLE IntegerExample (
    Age TINYINT,                    -- 0-255, perfect for ages
    EmployeeCount SMALLINT,         -- -32K to 32K, good for small companies
    Population INT,                 -- -2.1B to 2.1B, most versatile
    NationalDebt BIGINT             -- Very large numbers
);

INSERT INTO IntegerExample VALUES
    (25, 150, 1000000, 31000000000000);

SELECT 
    Age,
    EmployeeCount,
    Population,
    NationalDebt,
    CAST(NationalDebt AS VARCHAR(20)) AS DebtFormatted  -- Avoid scientific notation
FROM IntegerExample;

DROP TABLE IntegerExample;
PRINT '';

-- ============================================================================
-- Concept 2: DECIMAL and NUMERIC
-- ============================================================================

PRINT 'Concept 2: DECIMAL and NUMERIC';
PRINT '------------------------------';
PRINT 'DECIMAL(precision, scale) - Exact numeric';
PRINT 'precision = total digits (1-38)';
PRINT 'scale = digits after decimal (0-precision)';
PRINT 'Use for money, measurements requiring precision';
PRINT '';

CREATE TABLE PreciseNumbers (
    ProductID INT IDENTITY(1,1),
    Price DECIMAL(10, 2),           -- 99999999.99 (10 digits, 2 after decimal)
    TaxRate DECIMAL(5, 4),          -- 0.0825 = 8.25%
    Weight DECIMAL(8, 3),           -- 12345.678 kg
    Discount DECIMAL(3, 2)          -- 0.25 = 25%
);

INSERT INTO PreciseNumbers (Price, TaxRate, Weight, Discount) VALUES
    (1299.99, 0.0825, 15.750, 0.15),
    (49.50, 0.0900, 0.500, 0.00);

SELECT 
    Price,
    TaxRate,
    Price * TaxRate AS TaxAmount,
    Price * (1 + TaxRate) AS TotalWithTax,
    Price * (1 - Discount) AS DiscountedPrice
FROM PreciseNumbers;

DROP TABLE PreciseNumbers;
PRINT '';

-- ============================================================================
-- Concept 3: FLOAT and REAL (Approximate)
-- ============================================================================

PRINT 'Concept 3: FLOAT and REAL';
PRINT '------------------------';
PRINT 'REAL   - 7 digits precision (4 bytes)';
PRINT 'FLOAT  - 15 digits precision (8 bytes)';
PRINT 'Use for scientific data, NOT for money!';
PRINT '';

CREATE TABLE ApproximateNumbers (
    Measurement FLOAT,
    Calculation REAL
);

INSERT INTO ApproximateNumbers VALUES (123.456789012345, 123.456789);

SELECT 
    Measurement,
    Calculation,
    CAST(Measurement AS DECIMAL(18, 6)) AS AsDecimal
FROM ApproximateNumbers;

-- WARNING: Precision issues with FLOAT
DECLARE @f FLOAT = 0.1;
SELECT 
    @f + @f + @f AS FloatSum,               -- May not equal 0.3 exactly!
    CAST(@f + @f + @f AS DECIMAL(10,2)) AS DecimalSum;

DROP TABLE ApproximateNumbers;
PRINT '';

-- ============================================================================
-- Concept 4: MONEY and SMALLMONEY
-- ============================================================================

PRINT 'Concept 4: MONEY Types';
PRINT '---------------------';
PRINT 'SMALLMONEY - 4 decimal places, ±214,748.3647 (4 bytes)';
PRINT 'MONEY      - 4 decimal places, ±922 trillion (8 bytes)';
PRINT 'Note: DECIMAL(19,4) often preferred for portability';
PRINT '';

CREATE TABLE FinancialData (
    TransactionID INT IDENTITY(1,1),
    Amount MONEY,
    Fee SMALLMONEY,
    Total AS (Amount + Fee)         -- Computed column
);

INSERT INTO FinancialData (Amount, Fee) VALUES
    (1500.75, 25.00),
    (99.99, 2.50);

SELECT 
    Amount,
    Fee,
    Total,
    CONVERT(VARCHAR(20), Amount, 1) AS AmountFormatted  -- 1,500.75
FROM FinancialData;

DROP TABLE FinancialData;
PRINT '';

-- ============================================================================
-- Concept 5: Mathematical Operations
-- ============================================================================

PRINT 'Concept 5: Math Functions and Operations';
PRINT '----------------------------------------';
PRINT '';

CREATE TABLE MathExamples (
    Value1 DECIMAL(10, 2),
    Value2 DECIMAL(10, 2)
);

INSERT INTO MathExamples VALUES (100.50, 25.75), (50.00, 3.00);

SELECT 
    Value1,
    Value2,
    Value1 + Value2 AS Addition,
    Value1 - Value2 AS Subtraction,
    Value1 * Value2 AS Multiplication,
    Value1 / Value2 AS Division,
    Value1 % Value2 AS Modulo,
    POWER(Value1, 2) AS Squared,
    SQRT(Value1) AS SquareRoot,
    ROUND(Value1, 0) AS Rounded,
    CEILING(Value1) AS RoundUp,
    FLOOR(Value1) AS RoundDown,
    ABS(Value1 - Value2) AS AbsoluteDifference
FROM MathExamples;

-- Aggregate functions
SELECT 
    COUNT(*) AS RowCount,
    SUM(Value1) AS Total,
    AVG(Value1) AS Average,
    MIN(Value1) AS Minimum,
    MAX(Value1) AS Maximum,
    STDEV(Value1) AS StandardDeviation
FROM MathExamples;

DROP TABLE MathExamples;
PRINT '';

-- ============================================================================
-- Concept 6: IDENTITY (Auto-Increment)
-- ============================================================================

PRINT 'Concept 6: IDENTITY Auto-Increment';
PRINT '----------------------------------';
PRINT 'IDENTITY(seed, increment) - Automatic numbering';
PRINT '';

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1000, 1),  -- Starts at 1000, increments by 1
    CustomerID INT,
    OrderDate DATE DEFAULT CAST(GETDATE() AS DATE)
);

INSERT INTO Orders (CustomerID) VALUES (1), (2), (3);

SELECT 
    OrderID,
    CustomerID,
    OrderDate
FROM Orders;

-- Get last inserted ID
DECLARE @LastID INT;
INSERT INTO Orders (CustomerID) VALUES (4);
SET @LastID = SCOPE_IDENTITY();
PRINT 'Last inserted ID: ' + CAST(@LastID AS VARCHAR(10));

-- Check identity info
SELECT 
    IDENT_CURRENT('Orders') AS CurrentIdentity,
    IDENT_SEED('Orders') AS SeedValue,
    IDENT_INCR('Orders') AS IncrementValue;

DROP TABLE Orders;
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: Create Products with prices, calculate tax and totals';
PRINT 'Exercise 2: Create Inventory table with quantity tracking';
PRINT 'Exercise 3: Calculate discounts and sales statistics';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100),
    Price DECIMAL(10, 2),
    TaxRate DECIMAL(5, 4) DEFAULT 0.0825
);

INSERT INTO Products (ProductName, Price) VALUES
    (N'Laptop', 999.99),
    (N'Mouse', 24.99),
    (N'Keyboard', 79.50);

SELECT 
    ProductName,
    Price,
    TaxRate,
    ROUND(Price * TaxRate, 2) AS Tax,
    ROUND(Price * (1 + TaxRate), 2) AS Total
FROM Products;

DROP TABLE Products;

-- Exercise 2
CREATE TABLE Inventory (
    ItemID INT PRIMARY KEY IDENTITY(100, 1),
    ItemName NVARCHAR(100),
    QuantityInStock INT CHECK (QuantityInStock >= 0),
    ReorderLevel SMALLINT,
    UnitCost DECIMAL(10, 2)
);

INSERT INTO Inventory (ItemName, QuantityInStock, ReorderLevel, UnitCost) VALUES
    (N'Widget A', 150, 50, 12.50),
    (N'Widget B', 30, 50, 8.75),
    (N'Widget C', 200, 100, 15.00);

SELECT 
    ItemName,
    QuantityInStock,
    ReorderLevel,
    QuantityInStock - ReorderLevel AS StockDifference,
    CASE 
        WHEN QuantityInStock < ReorderLevel THEN 'REORDER NEEDED'
        ELSE 'OK'
    END AS Status,
    QuantityInStock * UnitCost AS TotalValue
FROM Inventory;

DROP TABLE Inventory;

-- Exercise 3
CREATE TABLE Sales (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    SaleAmount DECIMAL(10, 2),
    DiscountPercent DECIMAL(5, 2)
);

INSERT INTO Sales (SaleAmount, DiscountPercent) VALUES
    (100.00, 10.00),
    (250.00, 15.00),
    (75.00, 5.00),
    (500.00, 20.00);

SELECT 
    SaleAmount,
    DiscountPercent,
    ROUND(SaleAmount * (DiscountPercent / 100), 2) AS DiscountAmount,
    ROUND(SaleAmount * (1 - DiscountPercent / 100), 2) AS FinalAmount
FROM Sales;

SELECT 
    COUNT(*) AS TotalSales,
    SUM(SaleAmount) AS TotalRevenue,
    AVG(SaleAmount) AS AverageSale,
    MIN(SaleAmount) AS SmallestSale,
    MAX(SaleAmount) AS LargestSale
FROM Sales;

DROP TABLE Sales;
*/

-- ============================================================================
-- CLEANUP
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 04 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  • INT for most whole numbers';
PRINT '  • DECIMAL(p,s) for exact precision (money, percentages)';
PRINT '  • FLOAT/REAL for scientific data only';
PRINT '  • MONEY type available but DECIMAL often preferred';
PRINT '  • IDENTITY for auto-incrementing IDs';
PRINT '  • Always consider data range when choosing type';
PRINT '';
PRINT 'Next: Lesson 05 - Temporal Data Types';
PRINT '';
