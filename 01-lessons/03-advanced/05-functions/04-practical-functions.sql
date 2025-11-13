-- ========================================
-- Practical Functions - Real-World Examples
-- ========================================

USE TechStore;
GO

-- Drop existing functions
DROP FUNCTION IF EXISTS dbo.fn_GetRevenueByDateRange;
DROP FUNCTION IF EXISTS dbo.fn_CalculateLoyaltyPoints;
DROP FUNCTION IF EXISTS dbo.fn_GetInventoryValue;
DROP FUNCTION IF EXISTS dbo.fn_FormatProductDetails;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerMetrics;
DROP FUNCTION IF EXISTS dbo.fn_IsRestockNeeded;
DROP FUNCTION IF EXISTS dbo.fn_GetProductRecommendations;
GO

-- =============================================
-- Pattern 1: Date Range Analytics (Inline TVF)
-- =============================================

CREATE FUNCTION dbo.fn_GetRevenueByDateRange
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        CAST(s.SaleDate AS DATE) AS SaleDate,
        COUNT(s.SaleID) AS OrderCount,
        SUM(s.TotalAmount) AS DailyRevenue,
        AVG(s.TotalAmount) AS AvgOrderValue,
        COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
        COUNT(DISTINCT s.ProductID) AS UniqueProducts,
        SUM(s.TotalAmount) - LAG(SUM(s.TotalAmount)) OVER (ORDER BY CAST(s.SaleDate AS DATE)) AS DayOverDayGrowth
    FROM Sales s
    WHERE s.SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY CAST(s.SaleDate AS DATE)
);
GO

-- Usage: Weekly revenue analysis
DECLARE @WeekStart DATE = DATEADD(DAY, -7, GETDATE());
DECLARE @WeekEnd DATE = GETDATE();

SELECT * FROM dbo.fn_GetRevenueByDateRange(@WeekStart, @WeekEnd)
ORDER BY SaleDate DESC;

-- Monthly comparison
SELECT 
    DATENAME(MONTH, SaleDate) AS Month,
    SUM(DailyRevenue) AS MonthlyRevenue,
    AVG(AvgOrderValue) AS AvgOrderValue,
    SUM(UniqueCustomers) AS TotalCustomers
FROM dbo.fn_GetRevenueByDateRange('2024-01-01', '2024-12-31')
GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
ORDER BY YEAR(SaleDate), MONTH(SaleDate);
GO

-- =============================================
-- Pattern 2: Loyalty Points Calculator (Scalar)
-- =============================================

CREATE FUNCTION dbo.fn_CalculateLoyaltyPoints
(
    @PurchaseAmount DECIMAL(10,2),
    @CustomerTier VARCHAR(10)
)
RETURNS INT
AS
BEGIN
    DECLARE @Points INT;
    DECLARE @Multiplier DECIMAL(3,2);
    
    -- Tier-based multipliers
    SET @Multiplier = CASE @CustomerTier
        WHEN 'VIP' THEN 2.0
        WHEN 'Gold' THEN 1.5
        WHEN 'Silver' THEN 1.2
        ELSE 1.0
    END;
    
    -- Base: 1 point per dollar, multiplied by tier
    SET @Points = CAST(@PurchaseAmount * @Multiplier AS INT);
    
    -- Bonus: Extra 100 points for purchases over $100
    IF @PurchaseAmount >= 100
        SET @Points = @Points + 100;
    
    RETURN @Points;
END;
GO

-- Test loyalty points
SELECT 
    c.CustomerName,
    c.TotalPurchases,
    CASE 
        WHEN c.TotalPurchases >= 1000 THEN 'VIP'
        WHEN c.TotalPurchases >= 500 THEN 'Gold'
        WHEN c.TotalPurchases >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS Tier,
    dbo.fn_CalculateLoyaltyPoints(
        c.TotalPurchases,
        CASE 
            WHEN c.TotalPurchases >= 1000 THEN 'VIP'
            WHEN c.TotalPurchases >= 500 THEN 'Gold'
            WHEN c.TotalPurchases >= 100 THEN 'Silver'
            ELSE 'Bronze'
        END
    ) AS TotalLoyaltyPoints
FROM Customers c
ORDER BY TotalLoyaltyPoints DESC;
GO

-- =============================================
-- Pattern 3: Inventory Valuation (Inline TVF)
-- =============================================

CREATE FUNCTION dbo.fn_GetInventoryValue
(
    @Category NVARCHAR(50) = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        p.StockQuantity,
        p.Cost,
        p.Price,
        p.StockQuantity * p.Cost AS CostValue,
        p.StockQuantity * p.Price AS RetailValue,
        p.StockQuantity * (p.Price - p.Cost) AS PotentialProfit,
        CASE 
            WHEN p.StockQuantity = 0 THEN 'CRITICAL'
            WHEN p.StockQuantity < 10 THEN 'LOW'
            WHEN p.StockQuantity < 25 THEN 'MODERATE'
            ELSE 'GOOD'
        END AS StockLevel
    FROM Products p
    WHERE (@Category IS NULL OR p.Category = @Category)
        AND p.IsActive = 1
);
GO

-- Total inventory value
SELECT 
    SUM(CostValue) AS TotalCostValue,
    SUM(RetailValue) AS TotalRetailValue,
    SUM(PotentialProfit) AS TotalPotentialProfit,
    COUNT(*) AS ProductCount
FROM dbo.fn_GetInventoryValue(NULL);

-- Inventory by category
SELECT 
    Category,
    COUNT(*) AS Products,
    SUM(StockQuantity) AS TotalUnits,
    SUM(CostValue) AS CostValue,
    SUM(RetailValue) AS RetailValue,
    SUM(PotentialProfit) AS PotentialProfit
FROM dbo.fn_GetInventoryValue(NULL)
GROUP BY Category
ORDER BY RetailValue DESC;

-- Critical stock items
SELECT * FROM dbo.fn_GetInventoryValue(NULL)
WHERE StockLevel IN ('CRITICAL', 'LOW')
ORDER BY CostValue DESC;
GO

-- =============================================
-- Pattern 4: Product Details Formatter (Scalar)
-- =============================================

CREATE FUNCTION dbo.fn_FormatProductDetails
(
    @ProductName NVARCHAR(100),
    @Category NVARCHAR(50),
    @Price DECIMAL(10,2),
    @StockQuantity INT
)
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @Details NVARCHAR(500);
    
    SET @Details = @ProductName + ' (' + @Category + ') - $' + 
                   CAST(@Price AS NVARCHAR(20)) + ' - ' +
                   CASE 
                       WHEN @StockQuantity = 0 THEN 'OUT OF STOCK'
                       WHEN @StockQuantity < 10 THEN CAST(@StockQuantity AS NVARCHAR(10)) + ' left - LOW STOCK!'
                       ELSE CAST(@StockQuantity AS NVARCHAR(10)) + ' in stock'
                   END;
    
    RETURN @Details;
END;
GO

-- Generate product listings
SELECT 
    ProductID,
    dbo.fn_FormatProductDetails(ProductName, Category, Price, StockQuantity) AS ProductDetails
FROM Products
WHERE IsActive = 1
ORDER BY Category, ProductName;
GO

-- =============================================
-- Pattern 5: Customer Analytics (Multi-Statement TVF)
-- =============================================

CREATE FUNCTION dbo.fn_GetCustomerMetrics
(
    @CustomerID INT
)
RETURNS @Metrics TABLE
(
    MetricName VARCHAR(50),
    MetricValue NVARCHAR(100)
)
AS
BEGIN
    DECLARE @TotalOrders INT;
    DECLARE @TotalSpent DECIMAL(10,2);
    DECLARE @AvgOrderValue DECIMAL(10,2);
    DECLARE @LastPurchaseDate DATE;
    DECLARE @DaysSinceLastPurchase INT;
    DECLARE @FavoriteCategory NVARCHAR(50);
    DECLARE @CustomerTier VARCHAR(10);
    
    -- Calculate metrics
    SELECT 
        @TotalOrders = COUNT(s.SaleID),
        @TotalSpent = SUM(s.TotalAmount),
        @AvgOrderValue = AVG(s.TotalAmount),
        @LastPurchaseDate = MAX(CAST(s.SaleDate AS DATE))
    FROM Sales s
    WHERE s.CustomerID = @CustomerID;
    
    -- Days since last purchase
    IF @LastPurchaseDate IS NOT NULL
        SET @DaysSinceLastPurchase = DATEDIFF(DAY, @LastPurchaseDate, GETDATE());
    
    -- Favorite category
    SELECT TOP 1 @FavoriteCategory = p.Category
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
    GROUP BY p.Category
    ORDER BY SUM(s.TotalAmount) DESC;
    
    -- Customer tier
    SET @CustomerTier = CASE 
        WHEN @TotalSpent >= 1000 THEN 'VIP'
        WHEN @TotalSpent >= 500 THEN 'Gold'
        WHEN @TotalSpent >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END;
    
    -- Insert metrics
    INSERT INTO @Metrics VALUES ('Total Orders', CAST(ISNULL(@TotalOrders, 0) AS NVARCHAR(100)));
    INSERT INTO @Metrics VALUES ('Total Spent', '$' + CAST(ISNULL(@TotalSpent, 0) AS NVARCHAR(100)));
    INSERT INTO @Metrics VALUES ('Avg Order Value', '$' + CAST(ISNULL(@AvgOrderValue, 0) AS NVARCHAR(100)));
    INSERT INTO @Metrics VALUES ('Last Purchase', CAST(@LastPurchaseDate AS NVARCHAR(100)));
    INSERT INTO @Metrics VALUES ('Days Since Last Purchase', CAST(@DaysSinceLastPurchase AS NVARCHAR(100)));
    INSERT INTO @Metrics VALUES ('Favorite Category', ISNULL(@FavoriteCategory, 'N/A'));
    INSERT INTO @Metrics VALUES ('Customer Tier', @CustomerTier);
    
    RETURN;
END;
GO

-- Customer profile dashboard
SELECT * FROM dbo.fn_GetCustomerMetrics(1);

-- All customer tiers
SELECT 
    c.CustomerID,
    c.CustomerName,
    m.MetricValue AS Tier
FROM Customers c
CROSS APPLY dbo.fn_GetCustomerMetrics(c.CustomerID) m
WHERE m.MetricName = 'Customer Tier'
ORDER BY 
    CASE m.MetricValue
        WHEN 'VIP' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        ELSE 4
    END;
GO

-- =============================================
-- Pattern 6: Restock Recommendation (Scalar)
-- =============================================

CREATE FUNCTION dbo.fn_IsRestockNeeded
(
    @ProductID INT,
    @DaysToAnalyze INT = 30,
    @DaysToStock INT = 60
)
RETURNS BIT
AS
BEGIN
    DECLARE @CurrentStock INT;
    DECLARE @AvgDailySales DECIMAL(10,2);
    DECLARE @EstimatedNeeded INT;
    
    -- Get current stock
    SELECT @CurrentStock = StockQuantity
    FROM Products
    WHERE ProductID = @ProductID;
    
    -- Calculate average daily sales
    SELECT @AvgDailySales = CAST(COUNT(*) AS DECIMAL(10,2)) / @DaysToAnalyze
    FROM Sales
    WHERE ProductID = @ProductID
        AND SaleDate >= DATEADD(DAY, -@DaysToAnalyze, GETDATE());
    
    -- Estimate needed stock for desired days
    SET @EstimatedNeeded = CEILING(@AvgDailySales * @DaysToStock);
    
    -- Return 1 if restock needed
    IF @CurrentStock < @EstimatedNeeded
        RETURN 1;
    
    RETURN 0;
END;
GO

-- Check restock needs
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.StockQuantity AS CurrentStock,
    dbo.fn_IsRestockNeeded(p.ProductID, 30, 60) AS NeedsRestock
FROM Products p
WHERE p.IsActive = 1
    AND dbo.fn_IsRestockNeeded(p.ProductID, 30, 60) = 1
ORDER BY p.Category, p.ProductName;
GO

-- =============================================
-- Pattern 7: Product Recommendations (Inline TVF)
-- =============================================

CREATE FUNCTION dbo.fn_GetProductRecommendations
(
    @CustomerID INT,
    @TopN INT = 5
)
RETURNS TABLE
AS
RETURN
(
    WITH CustomerPurchases AS (
        SELECT p.Category
        FROM Sales s
        INNER JOIN Products p ON s.ProductID = p.ProductID
        WHERE s.CustomerID = @CustomerID
        GROUP BY p.Category
    )
    SELECT TOP (@TopN)
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Price,
        p.StockQuantity,
        COUNT(s.SaleID) AS PopularityScore
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    WHERE p.IsActive = 1
        AND p.StockQuantity > 0
        AND p.Category IN (SELECT Category FROM CustomerPurchases)
        AND p.ProductID NOT IN (
            SELECT ProductID 
            FROM Sales 
            WHERE CustomerID = @CustomerID
        )
    GROUP BY p.ProductID, p.ProductName, p.Category, p.Price, p.StockQuantity
    ORDER BY COUNT(s.SaleID) DESC
);
GO

-- Get recommendations for customer
SELECT * FROM dbo.fn_GetProductRecommendations(1, 5);

-- Recommendations with formatted details
SELECT 
    ProductID,
    dbo.fn_FormatProductDetails(ProductName, Category, Price, StockQuantity) AS ProductInfo,
    PopularityScore
FROM dbo.fn_GetProductRecommendations(1, 10)
ORDER BY PopularityScore DESC;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP FUNCTION IF EXISTS dbo.fn_GetRevenueByDateRange;
DROP FUNCTION IF EXISTS dbo.fn_CalculateLoyaltyPoints;
DROP FUNCTION IF EXISTS dbo.fn_GetInventoryValue;
DROP FUNCTION IF EXISTS dbo.fn_FormatProductDetails;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerMetrics;
DROP FUNCTION IF EXISTS dbo.fn_IsRestockNeeded;
DROP FUNCTION IF EXISTS dbo.fn_GetProductRecommendations;
*/

-- 💡 Key Points:
-- - Combine scalar and table-valued functions
-- - Use inline TVF for analytics dashboards
-- - Scalar functions for calculations and formatting
-- - Multi-statement TVF for complex aggregations
-- - CROSS APPLY for row-by-row function calls
-- - Functions enable code reuse across applications
-- - Date range analysis with window functions
-- - Loyalty points, inventory valuation, recommendations
-- - Always consider performance impact
-- - Prefer inline TVF over multi-statement when possible
