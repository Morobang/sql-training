-- ========================================
-- Table-Valued Functions (Inline and Multi-Statement)
-- ========================================

USE TechStore;
GO

-- Drop existing functions
DROP FUNCTION IF EXISTS dbo.fn_GetProductsByCategory;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerOrders;
DROP FUNCTION IF EXISTS dbo.fn_GetTopSellingProducts;
DROP FUNCTION IF EXISTS dbo.fn_GetSalesSummary;
DROP FUNCTION IF EXISTS dbo.fn_GetProductsInPriceRange;
DROP FUNCTION IF EXISTS dbo.fn_SplitString;
GO

-- =============================================
-- INLINE TABLE-VALUED FUNCTIONS (Fast, Preferred)
-- =============================================

-- Example 1: Simple Inline TVF
-- =============================================

CREATE FUNCTION dbo.fn_GetProductsByCategory
(
    @Category NVARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        StockQuantity,
        IsActive
    FROM Products
    WHERE Category = @Category
);
GO

-- Test inline TVF
SELECT * FROM dbo.fn_GetProductsByCategory('Electronics');

-- Use in JOIN
SELECT 
    c.CustomerName,
    p.ProductName,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN dbo.fn_GetProductsByCategory('Electronics') p ON s.ProductID = p.ProductID;
GO

-- =============================================
-- Example 2: Inline TVF with Multiple Parameters
-- =============================================

CREATE FUNCTION dbo.fn_GetProductsInPriceRange
(
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        Cost,
        Price - Cost AS Profit,
        CAST((Price - Cost) * 100.0 / NULLIF(Cost, 0) AS DECIMAL(5,2)) AS ProfitMarginPercent
    FROM Products
    WHERE Price BETWEEN @MinPrice AND @MaxPrice
        AND IsActive = 1
);
GO

-- Test price range function
SELECT * FROM dbo.fn_GetProductsInPriceRange(50, 200)
ORDER BY Price DESC;

-- Find affordable products
SELECT * FROM dbo.fn_GetProductsInPriceRange(0, 50)
WHERE ProfitMarginPercent > 30
ORDER BY ProfitMarginPercent DESC;
GO

-- =============================================
-- Example 3: Inline TVF with JOIN
-- =============================================

CREATE FUNCTION dbo.fn_GetCustomerOrders
(
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        s.SaleID,
        s.SaleDate,
        p.ProductName,
        p.Category,
        s.Quantity,
        s.TotalAmount,
        s.PaymentMethod
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
);
GO

-- Test customer orders
SELECT * FROM dbo.fn_GetCustomerOrders(1)
ORDER BY SaleDate DESC;

-- Aggregate function results
SELECT 
    Category,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM dbo.fn_GetCustomerOrders(1)
GROUP BY Category;
GO

-- =============================================
-- Example 4: Inline TVF with Aggregation
-- =============================================

CREATE FUNCTION dbo.fn_GetTopSellingProducts
(
    @TopN INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        p.ProductID,
        p.ProductName,
        p.Category,
        COUNT(s.SaleID) AS TimesSold,
        SUM(s.Quantity) AS TotalQuantitySold,
        SUM(s.TotalAmount) AS TotalRevenue
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category
    ORDER BY SUM(s.TotalAmount) DESC
);
GO

-- Get top 5 selling products
SELECT * FROM dbo.fn_GetTopSellingProducts(5);

-- Get top 10 with additional analysis
SELECT 
    ProductName,
    Category,
    TotalRevenue,
    TotalQuantitySold,
    TotalRevenue / NULLIF(TotalQuantitySold, 0) AS AvgPricePerUnit
FROM dbo.fn_GetTopSellingProducts(10);
GO

-- =============================================
-- MULTI-STATEMENT TABLE-VALUED FUNCTIONS (Slower, Avoid if Possible)
-- =============================================

-- Example 5: Multi-Statement TVF with Complex Logic
-- =============================================

CREATE FUNCTION dbo.fn_GetSalesSummary
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS @Summary TABLE
(
    SummaryDate DATE,
    OrderCount INT,
    TotalRevenue DECIMAL(10,2),
    AvgOrderValue DECIMAL(10,2),
    UniqueCustomers INT,
    TopCategory NVARCHAR(50)
)
AS
BEGIN
    -- Insert daily summaries
    INSERT INTO @Summary (SummaryDate, OrderCount, TotalRevenue, AvgOrderValue, UniqueCustomers)
    SELECT 
        CAST(SaleDate AS DATE) AS SummaryDate,
        COUNT(SaleID) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue,
        COUNT(DISTINCT CustomerID) AS UniqueCustomers
    FROM Sales
    WHERE SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY CAST(SaleDate AS DATE);
    
    -- Update with top category per day
    UPDATE s
    SET TopCategory = (
        SELECT TOP 1 p.Category
        FROM Sales sa
        INNER JOIN Products p ON sa.ProductID = p.ProductID
        WHERE CAST(sa.SaleDate AS DATE) = s.SummaryDate
        GROUP BY p.Category
        ORDER BY SUM(sa.TotalAmount) DESC
    )
    FROM @Summary s;
    
    RETURN;
END;
GO

-- Test sales summary
SELECT * FROM dbo.fn_GetSalesSummary('2024-01-01', '2024-12-31')
ORDER BY SummaryDate DESC;

-- Aggregate the summary
SELECT 
    SUM(OrderCount) AS TotalOrders,
    SUM(TotalRevenue) AS TotalRevenue,
    AVG(AvgOrderValue) AS OverallAvgOrderValue,
    TopCategory,
    COUNT(*) AS DaysAsTopCategory
FROM dbo.fn_GetSalesSummary('2024-01-01', '2024-12-31')
GROUP BY TopCategory
ORDER BY DaysAsTopCategory DESC;
GO

-- =============================================
-- Example 6: String Split Function (Multi-Statement)
-- =============================================

CREATE FUNCTION dbo.fn_SplitString
(
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE
(
    RowNum INT IDENTITY(1,1),
    Value NVARCHAR(100)
)
AS
BEGIN
    DECLARE @Start INT = 1;
    DECLARE @End INT;
    
    WHILE @Start <= LEN(@String)
    BEGIN
        SET @End = CHARINDEX(@Delimiter, @String, @Start);
        
        IF @End = 0
            SET @End = LEN(@String) + 1;
        
        INSERT INTO @Result (Value)
        VALUES (SUBSTRING(@String, @Start, @End - @Start));
        
        SET @Start = @End + 1;
    END;
    
    RETURN;
END;
GO

-- Test string split
SELECT * FROM dbo.fn_SplitString('Electronics,Clothing,Books', ',');

-- Use in practical scenario
DECLARE @Categories NVARCHAR(MAX) = 'Electronics,Clothing';
SELECT p.*
FROM Products p
INNER JOIN dbo.fn_SplitString(@Categories, ',') c 
    ON p.Category = c.Value
WHERE p.IsActive = 1;
GO

-- =============================================
-- Performance Comparison: Inline vs Multi-Statement
-- =============================================

-- Inline TVF (FAST - query optimizer can optimize)
DROP FUNCTION IF EXISTS dbo.fn_GetActiveProducts_Inline;
GO

CREATE FUNCTION dbo.fn_GetActiveProducts_Inline()
RETURNS TABLE
AS
RETURN
(
    SELECT ProductID, ProductName, Category, Price, StockQuantity
    FROM Products
    WHERE IsActive = 1
);
GO

-- Multi-Statement TVF (SLOWER - estimated row count often wrong)
DROP FUNCTION IF EXISTS dbo.fn_GetActiveProducts_MultiStatement;
GO

CREATE FUNCTION dbo.fn_GetActiveProducts_MultiStatement()
RETURNS @Products TABLE
(
    ProductID INT,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Price DECIMAL(10,2),
    StockQuantity INT
)
AS
BEGIN
    INSERT INTO @Products
    SELECT ProductID, ProductName, Category, Price, StockQuantity
    FROM Products
    WHERE IsActive = 1;
    
    RETURN;
END;
GO

-- Compare execution (use Actual Execution Plan in SSMS)
-- SET STATISTICS IO ON;
-- SET STATISTICS TIME ON;

SELECT * FROM dbo.fn_GetActiveProducts_Inline();
SELECT * FROM dbo.fn_GetActiveProducts_MultiStatement();

-- SET STATISTICS IO OFF;
-- SET STATISTICS TIME OFF;
GO

-- =============================================
-- Practical Use Cases
-- =============================================

-- Use Case 1: Parameterized view replacement
SELECT * FROM dbo.fn_GetProductsByCategory('Electronics')
WHERE Price > 100;

-- Use Case 2: Reusable complex queries
SELECT 
    CustomerName,
    OrderCount,
    TotalSpent
FROM (
    SELECT 
        c.CustomerName,
        COUNT(o.SaleID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Customers c
    CROSS APPLY dbo.fn_GetCustomerOrders(c.CustomerID) o
    GROUP BY c.CustomerID, c.CustomerName
) AS Summary
WHERE OrderCount > 0
ORDER BY TotalSpent DESC;

-- Use Case 3: Dynamic filtering
SELECT * FROM dbo.fn_GetTopSellingProducts(5)
WHERE Category = 'Electronics';

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP FUNCTION IF EXISTS dbo.fn_GetProductsByCategory;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerOrders;
DROP FUNCTION IF EXISTS dbo.fn_GetTopSellingProducts;
DROP FUNCTION IF EXISTS dbo.fn_GetSalesSummary;
DROP FUNCTION IF EXISTS dbo.fn_GetProductsInPriceRange;
DROP FUNCTION IF EXISTS dbo.fn_SplitString;
DROP FUNCTION IF EXISTS dbo.fn_GetActiveProducts_Inline;
DROP FUNCTION IF EXISTS dbo.fn_GetActiveProducts_MultiStatement;
*/

-- 💡 Key Points:
-- 
-- INLINE TVF:
-- - Single RETURN SELECT statement
-- - Fast (optimized like views)
-- - Preferred for most scenarios
-- - No table variable declaration
-- - Query optimizer can push predicates
--
-- MULTI-STATEMENT TVF:
-- - Multiple statements with DECLARE @TableVar
-- - Slower (estimated row count often wrong)
-- - Use only when complex logic required
-- - Cannot optimize as well as inline
-- - Has BEGIN...END block
--
-- BEST PRACTICES:
-- - Always prefer inline TVF when possible
-- - Use CROSS APPLY for row-by-row operations
-- - TVFs can replace parameterized views
-- - Can join TVFs like regular tables
-- - Better than subqueries for reusable logic
-- - Avoid in WHERE clauses on large tables
-- - Check execution plans to verify performance
