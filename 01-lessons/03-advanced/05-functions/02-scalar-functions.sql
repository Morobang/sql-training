-- ========================================
-- Scalar Functions
-- ========================================

USE TechStore;
GO

-- Drop existing functions
DROP FUNCTION IF EXISTS dbo.fn_CalculateTax;
DROP FUNCTION IF EXISTS dbo.fn_CalculateDiscount;
DROP FUNCTION IF EXISTS dbo.fn_FormatCurrency;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerTier;
DROP FUNCTION IF EXISTS dbo.fn_IsValidEmail;
DROP FUNCTION IF EXISTS dbo.fn_CalculateProfitMargin;
DROP FUNCTION IF EXISTS dbo.fn_GetStockStatus;
DROP FUNCTION IF EXISTS dbo.fn_DaysSinceLastPurchase;
GO

-- =============================================
-- Example 1: Simple Calculation Function
-- =============================================

CREATE FUNCTION dbo.fn_CalculateTax
(
    @Amount DECIMAL(10,2),
    @TaxRate DECIMAL(5,4) = 0.08  -- Default 8%
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * @TaxRate;
END;
GO

-- Test the function
SELECT dbo.fn_CalculateTax(100.00, DEFAULT) AS TaxAmount;
SELECT dbo.fn_CalculateTax(100.00, 0.10) AS TaxAmount;

-- Use in SELECT query
SELECT 
    ProductID,
    ProductName,
    Price,
    dbo.fn_CalculateTax(Price, 0.08) AS SalesTax,
    Price + dbo.fn_CalculateTax(Price, 0.08) AS PriceWithTax
FROM Products
WHERE IsActive = 1;
GO

-- =============================================
-- Example 2: Discount Calculation
-- =============================================

CREATE FUNCTION dbo.fn_CalculateDiscount
(
    @OriginalPrice DECIMAL(10,2),
    @DiscountPercent DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @DiscountAmount DECIMAL(10,2);
    
    -- Validate discount (0-100%)
    IF @DiscountPercent < 0 OR @DiscountPercent > 100
        RETURN 0;
    
    SET @DiscountAmount = @OriginalPrice * (@DiscountPercent / 100.0);
    
    RETURN @DiscountAmount;
END;
GO

-- Test discount calculation
SELECT 
    ProductID,
    ProductName,
    Price AS OriginalPrice,
    dbo.fn_CalculateDiscount(Price, 10) AS Discount10Percent,
    Price - dbo.fn_CalculateDiscount(Price, 10) AS SalePrice
FROM Products
WHERE Category = 'Electronics';
GO

-- =============================================
-- Example 3: String Formatting Function
-- =============================================

CREATE FUNCTION dbo.fn_FormatCurrency
(
    @Amount DECIMAL(10,2)
)
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN '$' + CAST(CAST(@Amount AS DECIMAL(10,2)) AS VARCHAR(20));
END;
GO

-- Test formatting
SELECT 
    ProductName,
    dbo.fn_FormatCurrency(Price) AS FormattedPrice,
    dbo.fn_FormatCurrency(Cost) AS FormattedCost
FROM Products
WHERE IsActive = 1;
GO

-- =============================================
-- Example 4: Classification Function
-- =============================================

CREATE FUNCTION dbo.fn_GetCustomerTier
(
    @TotalPurchases DECIMAL(10,2)
)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @Tier VARCHAR(10);
    
    SET @Tier = CASE
        WHEN @TotalPurchases >= 1000 THEN 'VIP'
        WHEN @TotalPurchases >= 500 THEN 'Gold'
        WHEN @TotalPurchases >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END;
    
    RETURN @Tier;
END;
GO

-- Test customer tier classification
SELECT 
    CustomerID,
    CustomerName,
    TotalPurchases,
    dbo.fn_GetCustomerTier(TotalPurchases) AS CustomerTier
FROM Customers
ORDER BY TotalPurchases DESC;

-- Count customers per tier
SELECT 
    dbo.fn_GetCustomerTier(TotalPurchases) AS Tier,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY dbo.fn_GetCustomerTier(TotalPurchases)
ORDER BY CustomerCount DESC;
GO

-- =============================================
-- Example 5: Validation Function
-- =============================================

CREATE FUNCTION dbo.fn_IsValidEmail
(
    @Email VARCHAR(100)
)
RETURNS BIT
AS
BEGIN
    -- Basic email validation
    IF @Email LIKE '%_@__%.__%'
        AND @Email NOT LIKE '%[^a-zA-Z0-9.@_-]%'  -- Only allow these characters
        AND LEN(@Email) >= 6
        RETURN 1;
    
    RETURN 0;
END;
GO

-- Test email validation
SELECT 
    'test@example.com' AS Email,
    dbo.fn_IsValidEmail('test@example.com') AS IsValid;

SELECT 
    'invalid-email' AS Email,
    dbo.fn_IsValidEmail('invalid-email') AS IsValid;

-- Use in WHERE clause (be cautious on large tables)
SELECT 
    CustomerID,
    CustomerName,
    Email
FROM Customers
WHERE dbo.fn_IsValidEmail(Email) = 1;
GO

-- =============================================
-- Example 6: Business Logic Function
-- =============================================

CREATE FUNCTION dbo.fn_CalculateProfitMargin
(
    @Price DECIMAL(10,2),
    @Cost DECIMAL(10,2)
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Margin DECIMAL(5,2);
    
    -- Avoid division by zero
    IF @Cost = 0
        RETURN 0;
    
    SET @Margin = ((@Price - @Cost) / @Cost) * 100.0;
    
    RETURN @Margin;
END;
GO

-- Test profit margin calculation
SELECT 
    ProductID,
    ProductName,
    Price,
    Cost,
    Price - Cost AS Profit,
    dbo.fn_CalculateProfitMargin(Price, Cost) AS ProfitMarginPercent,
    CASE 
        WHEN dbo.fn_CalculateProfitMargin(Price, Cost) >= 50 THEN 'Excellent'
        WHEN dbo.fn_CalculateProfitMargin(Price, Cost) >= 25 THEN 'Good'
        WHEN dbo.fn_CalculateProfitMargin(Price, Cost) >= 10 THEN 'Fair'
        ELSE 'Poor'
    END AS MarginRating
FROM Products
WHERE IsActive = 1
ORDER BY ProfitMarginPercent DESC;
GO

-- =============================================
-- Example 7: Status Determination Function
-- =============================================

CREATE FUNCTION dbo.fn_GetStockStatus
(
    @StockQuantity INT
)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Status VARCHAR(20);
    
    SET @Status = CASE
        WHEN @StockQuantity = 0 THEN 'OUT OF STOCK'
        WHEN @StockQuantity < 10 THEN 'LOW STOCK'
        WHEN @StockQuantity < 25 THEN 'MODERATE'
        ELSE 'IN STOCK'
    END;
    
    RETURN @Status;
END;
GO

-- Test stock status
SELECT 
    ProductID,
    ProductName,
    StockQuantity,
    dbo.fn_GetStockStatus(StockQuantity) AS Status
FROM Products
WHERE IsActive = 1
ORDER BY StockQuantity;

-- Alert for low stock products
SELECT 
    ProductID,
    ProductName,
    Category,
    StockQuantity,
    dbo.fn_GetStockStatus(StockQuantity) AS Status
FROM Products
WHERE dbo.fn_GetStockStatus(StockQuantity) IN ('OUT OF STOCK', 'LOW STOCK')
ORDER BY StockQuantity;
GO

-- =============================================
-- Example 8: Date Calculation Function
-- =============================================

CREATE FUNCTION dbo.fn_DaysSinceLastPurchase
(
    @CustomerID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @LastPurchaseDate DATE;
    DECLARE @DaysSince INT;
    
    -- Get last purchase date
    SELECT @LastPurchaseDate = MAX(CAST(SaleDate AS DATE))
    FROM Sales
    WHERE CustomerID = @CustomerID;
    
    -- Calculate days since
    IF @LastPurchaseDate IS NULL
        RETURN NULL;  -- No purchases
    
    SET @DaysSince = DATEDIFF(DAY, @LastPurchaseDate, GETDATE());
    
    RETURN @DaysSince;
END;
GO

-- Test days since last purchase
SELECT 
    c.CustomerID,
    c.CustomerName,
    dbo.fn_DaysSinceLastPurchase(c.CustomerID) AS DaysSinceLastPurchase,
    CASE 
        WHEN dbo.fn_DaysSinceLastPurchase(c.CustomerID) IS NULL THEN 'Never Purchased'
        WHEN dbo.fn_DaysSinceLastPurchase(c.CustomerID) <= 30 THEN 'Active'
        WHEN dbo.fn_DaysSinceLastPurchase(c.CustomerID) <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END AS CustomerStatus
FROM Customers c
ORDER BY DaysSinceLastPurchase;
GO

-- =============================================
-- Example 9: Nested Function Calls
-- =============================================

-- Calculate final price with discount and tax
SELECT 
    ProductID,
    ProductName,
    Price AS OriginalPrice,
    dbo.fn_CalculateDiscount(Price, 15) AS DiscountAmount,
    Price - dbo.fn_CalculateDiscount(Price, 15) AS DiscountedPrice,
    dbo.fn_CalculateTax(
        Price - dbo.fn_CalculateDiscount(Price, 15), 
        0.08
    ) AS TaxOnDiscountedPrice,
    Price - dbo.fn_CalculateDiscount(Price, 15) + 
    dbo.fn_CalculateTax(
        Price - dbo.fn_CalculateDiscount(Price, 15), 
        0.08
    ) AS FinalPrice
FROM Products
WHERE Category = 'Electronics' AND IsActive = 1;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP FUNCTION IF EXISTS dbo.fn_CalculateTax;
DROP FUNCTION IF EXISTS dbo.fn_CalculateDiscount;
DROP FUNCTION IF EXISTS dbo.fn_FormatCurrency;
DROP FUNCTION IF EXISTS dbo.fn_GetCustomerTier;
DROP FUNCTION IF EXISTS dbo.fn_IsValidEmail;
DROP FUNCTION IF EXISTS dbo.fn_CalculateProfitMargin;
DROP FUNCTION IF EXISTS dbo.fn_GetStockStatus;
DROP FUNCTION IF EXISTS dbo.fn_DaysSinceLastPurchase;
*/

-- 💡 Key Points:
-- - Scalar functions return single value
-- - Can be used in SELECT, WHERE, ORDER BY
-- - Always specify schema (dbo.)
-- - Validate inputs to prevent errors
-- - Functions called once per row (can be slow)
-- - Avoid in WHERE clauses on large tables (non-sargable)
-- - Use for calculations, formatting, validation
-- - Can nest function calls
-- - Must return a value (RETURN statement)
-- - Cannot modify data (no INSERT/UPDATE/DELETE)
