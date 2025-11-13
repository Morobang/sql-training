-- ========================================
-- OUTPUT Parameters and Return Values
-- ========================================

USE TechStore;
GO

-- Drop existing procedures
DROP PROCEDURE IF EXISTS usp_GetProductCount;
DROP PROCEDURE IF EXISTS usp_CalculateOrderTotal;
DROP PROCEDURE IF EXISTS usp_CreateSale;
DROP PROCEDURE IF EXISTS usp_ValidateStock;
DROP PROCEDURE IF EXISTS usp_GetSalesStats;
DROP PROCEDURE IF EXISTS usp_ProcessRefund;
GO

-- =============================================
-- Example 1: Simple OUTPUT Parameter
-- =============================================

CREATE PROCEDURE usp_GetProductCount
    @Category NVARCHAR(50) = NULL,  -- Optional filter
    @ProductCount INT OUTPUT  -- OUTPUT parameter
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT @ProductCount = COUNT(*)
    FROM Products
    WHERE (@Category IS NULL OR Category = @Category)
        AND IsActive = 1;
END;
GO

-- Execute with OUTPUT parameter
DECLARE @Count INT;
EXEC usp_GetProductCount @Category = 'Electronics', @ProductCount = @Count OUTPUT;
PRINT 'Electronics products: ' + CAST(@Count AS NVARCHAR(10));

-- Get all products count
DECLARE @TotalCount INT;
EXEC usp_GetProductCount @Category = NULL, @ProductCount = @TotalCount OUTPUT;
PRINT 'Total active products: ' + CAST(@TotalCount AS NVARCHAR(10));
GO

-- =============================================
-- Example 2: Multiple OUTPUT Parameters
-- =============================================

CREATE PROCEDURE usp_CalculateOrderTotal
    @CustomerID INT,
    @TotalOrders INT OUTPUT,
    @TotalSpent DECIMAL(10,2) OUTPUT,
    @AvgOrderValue DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        @TotalOrders = COUNT(SaleID),
        @TotalSpent = ISNULL(SUM(TotalAmount), 0),
        @AvgOrderValue = ISNULL(AVG(TotalAmount), 0)
    FROM Sales
    WHERE CustomerID = @CustomerID;
    
    -- Handle case where customer has no orders
    IF @TotalOrders IS NULL
    BEGIN
        SET @TotalOrders = 0;
        SET @TotalSpent = 0;
        SET @AvgOrderValue = 0;
    END;
END;
GO

-- Execute with multiple OUTPUT parameters
DECLARE @Orders INT, @Spent DECIMAL(10,2), @Avg DECIMAL(10,2);
EXEC usp_CalculateOrderTotal 
    @CustomerID = 1,
    @TotalOrders = @Orders OUTPUT,
    @TotalSpent = @Spent OUTPUT,
    @AvgOrderValue = @Avg OUTPUT;

PRINT 'Customer 1 Statistics:';
PRINT '  Orders: ' + CAST(@Orders AS NVARCHAR(10));
PRINT '  Total Spent: $' + CAST(@Spent AS NVARCHAR(20));
PRINT '  Average Order: $' + CAST(@Avg AS NVARCHAR(20));
GO

-- =============================================
-- Example 3: OUTPUT Parameter + Result Set
-- =============================================

CREATE PROCEDURE usp_CreateSale
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @PaymentMethod NVARCHAR(50),
    @NewSaleID INT OUTPUT  -- Return new SaleID
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Price DECIMAL(10,2);
    DECLARE @TotalAmount DECIMAL(10,2);
    
    -- Get product price
    SELECT @Price = Price
    FROM Products
    WHERE ProductID = @ProductID;
    
    -- Calculate total
    SET @TotalAmount = @Price * @Quantity;
    
    -- Insert sale
    INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
    VALUES (@CustomerID, @ProductID, @Quantity, GETDATE(), @TotalAmount, @PaymentMethod);
    
    -- Get new SaleID
    SET @NewSaleID = SCOPE_IDENTITY();
    
    -- Return sale details
    SELECT 
        @NewSaleID AS SaleID,
        @CustomerID AS CustomerID,
        @ProductID AS ProductID,
        @Quantity AS Quantity,
        @TotalAmount AS TotalAmount,
        @PaymentMethod AS PaymentMethod;
END;
GO

-- Execute and capture new SaleID
DECLARE @SaleID INT;
EXEC usp_CreateSale
    @CustomerID = 1,
    @ProductID = 1,
    @Quantity = 2,
    @PaymentMethod = 'Credit Card',
    @NewSaleID = @SaleID OUTPUT;

PRINT 'New Sale ID: ' + CAST(@SaleID AS NVARCHAR(10));
GO

-- =============================================
-- Example 4: RETURN Value (Status Code)
-- =============================================

CREATE PROCEDURE usp_ValidateStock
    @ProductID INT,
    @RequestedQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AvailableStock INT;
    
    -- Get current stock
    SELECT @AvailableStock = StockQuantity
    FROM Products
    WHERE ProductID = @ProductID AND IsActive = 1;
    
    -- Product not found
    IF @AvailableStock IS NULL
    BEGIN
        PRINT 'Error: Product not found or inactive';
        RETURN -1;
    END;
    
    -- Insufficient stock
    IF @AvailableStock < @RequestedQuantity
    BEGIN
        PRINT 'Error: Insufficient stock';
        PRINT 'Available: ' + CAST(@AvailableStock AS NVARCHAR(10));
        PRINT 'Requested: ' + CAST(@RequestedQuantity AS NVARCHAR(10));
        RETURN -2;
    END;
    
    -- Stock available
    PRINT 'Stock validation passed';
    PRINT 'Available: ' + CAST(@AvailableStock AS NVARCHAR(10));
    RETURN 0;  -- Success
END;
GO

-- Execute and check return value
DECLARE @ReturnCode INT;
EXEC @ReturnCode = usp_ValidateStock @ProductID = 1, @RequestedQuantity = 5;
PRINT 'Return Code: ' + CAST(@ReturnCode AS NVARCHAR(10));

-- Test with excessive quantity
EXEC @ReturnCode = usp_ValidateStock @ProductID = 1, @RequestedQuantity = 99999;
PRINT 'Return Code: ' + CAST(@ReturnCode AS NVARCHAR(10));
GO

-- =============================================
-- Example 5: Combining RETURN and OUTPUT
-- =============================================

CREATE PROCEDURE usp_GetSalesStats
    @StartDate DATE,
    @EndDate DATE,
    @TotalSales DECIMAL(10,2) OUTPUT,
    @OrderCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate dates
    IF @StartDate > @EndDate
    BEGIN
        PRINT 'Error: Start date must be before end date';
        RETURN -1;
    END;
    
    -- Get statistics
    SELECT 
        @TotalSales = ISNULL(SUM(TotalAmount), 0),
        @OrderCount = COUNT(*)
    FROM Sales
    WHERE SaleDate BETWEEN @StartDate AND @EndDate;
    
    -- Return result set for details
    SELECT 
        CAST(SaleDate AS DATE) AS Date,
        COUNT(*) AS DailyOrders,
        SUM(TotalAmount) AS DailyRevenue
    FROM Sales
    WHERE SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY CAST(SaleDate AS DATE)
    ORDER BY Date;
    
    RETURN 0;  -- Success
END;
GO

-- Execute with RETURN and OUTPUT
DECLARE @Revenue DECIMAL(10,2), @Orders INT, @Status INT;
EXEC @Status = usp_GetSalesStats
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @TotalSales = @Revenue OUTPUT,
    @OrderCount = @Orders OUTPUT;

PRINT 'Status: ' + CAST(@Status AS NVARCHAR(10));
PRINT 'Total Revenue: $' + CAST(@Revenue AS NVARCHAR(20));
PRINT 'Total Orders: ' + CAST(@Orders AS NVARCHAR(10));
GO

-- =============================================
-- Example 6: OUTPUT Parameter with Conditional Logic
-- =============================================

CREATE PROCEDURE usp_ProcessRefund
    @SaleID INT,
    @RefundAmount DECIMAL(10,2) OUTPUT,
    @Status NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OriginalAmount DECIMAL(10,2);
    DECLARE @SaleDate DATE;
    
    -- Get sale info
    SELECT 
        @OriginalAmount = TotalAmount,
        @SaleDate = CAST(SaleDate AS DATE)
    FROM Sales
    WHERE SaleID = @SaleID;
    
    -- Sale not found
    IF @OriginalAmount IS NULL
    BEGIN
        SET @RefundAmount = 0;
        SET @Status = 'ERROR: Sale not found';
        RETURN -1;
    END;
    
    -- Check if sale is within refund window (30 days)
    IF DATEDIFF(DAY, @SaleDate, GETDATE()) > 30
    BEGIN
        SET @RefundAmount = 0;
        SET @Status = 'DENIED: Outside 30-day refund window';
        RETURN -2;
    END;
    
    -- Approve refund
    SET @RefundAmount = @OriginalAmount;
    SET @Status = 'APPROVED';
    
    PRINT 'Refund approved for Sale ID: ' + CAST(@SaleID AS NVARCHAR(10));
    PRINT 'Refund Amount: $' + CAST(@RefundAmount AS NVARCHAR(20));
    
    RETURN 0;  -- Success
END;
GO

-- Test refund approval
DECLARE @Amount DECIMAL(10,2), @StatusMsg NVARCHAR(50), @Result INT;
EXEC @Result = usp_ProcessRefund
    @SaleID = 1,
    @RefundAmount = @Amount OUTPUT,
    @Status = @StatusMsg OUTPUT;

PRINT 'Return Code: ' + CAST(@Result AS NVARCHAR(10));
PRINT 'Refund Amount: $' + CAST(@Amount AS NVARCHAR(20));
PRINT 'Status: ' + @StatusMsg;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP PROCEDURE IF EXISTS usp_GetProductCount;
DROP PROCEDURE IF EXISTS usp_CalculateOrderTotal;
DROP PROCEDURE IF EXISTS usp_CreateSale;
DROP PROCEDURE IF EXISTS usp_ValidateStock;
DROP PROCEDURE IF EXISTS usp_GetSalesStats;
DROP PROCEDURE IF EXISTS usp_ProcessRefund;
*/

-- 💡 Key Points:
-- - OUTPUT parameters return values to the caller
-- - Must specify OUTPUT keyword in both CREATE and EXEC
-- - RETURN statement returns integer status code only
-- - Convention: 0 = success, negative = error codes
-- - Can combine OUTPUT parameters + RETURN + result sets
-- - OUTPUT parameters can be any data type
-- - RETURN is limited to INT
-- - Use OUTPUT for data, RETURN for status
-- - Always initialize OUTPUT parameters
-- - Check RETURN codes to handle errors gracefully
