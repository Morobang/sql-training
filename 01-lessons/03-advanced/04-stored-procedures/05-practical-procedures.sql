-- ========================================
-- Practical Stored Procedures
-- ========================================

USE TechStore;
GO

-- Drop existing procedures
DROP PROCEDURE IF EXISTS usp_SearchProducts;
DROP PROCEDURE IF EXISTS usp_GetCustomerDashboard;
DROP PROCEDURE IF EXISTS usp_GenerateMonthlyReport;
DROP PROCEDURE IF EXISTS usp_ReorderInventory;
DROP PROCEDURE IF EXISTS usp_ArchiveOldSales;
DROP PROCEDURE IF EXISTS usp_BulkPriceUpdate;
GO

-- =============================================
-- Pattern 1: Flexible Search (Optional Parameters)
-- =============================================

CREATE PROCEDURE usp_SearchProducts
    @Category NVARCHAR(50) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @SearchTerm NVARCHAR(100) = NULL,
    @InStockOnly BIT = 0,
    @SortBy NVARCHAR(20) = 'Name'  -- 'Name', 'Price', 'Stock'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        StockQuantity,
        CASE 
            WHEN StockQuantity = 0 THEN 'OUT OF STOCK'
            WHEN StockQuantity < 10 THEN 'LOW STOCK'
            ELSE 'IN STOCK'
        END AS StockStatus
    FROM Products
    WHERE (@Category IS NULL OR Category = @Category)
        AND (@MinPrice IS NULL OR Price >= @MinPrice)
        AND (@MaxPrice IS NULL OR Price <= @MaxPrice)
        AND (@SearchTerm IS NULL OR ProductName LIKE '%' + @SearchTerm + '%')
        AND (@InStockOnly = 0 OR StockQuantity > 0)
        AND IsActive = 1
    ORDER BY
        CASE WHEN @SortBy = 'Name' THEN ProductName END,
        CASE WHEN @SortBy = 'Price' THEN Price END,
        CASE WHEN @SortBy = 'Stock' THEN StockQuantity END DESC;
END;
GO

-- Test various search combinations
EXEC usp_SearchProducts @Category = 'Electronics';
EXEC usp_SearchProducts @MinPrice = 50, @MaxPrice = 200;
EXEC usp_SearchProducts @SearchTerm = 'Phone', @InStockOnly = 1;
EXEC usp_SearchProducts @SortBy = 'Price';
GO

-- =============================================
-- Pattern 2: Dashboard Procedure (Multiple Result Sets)
-- =============================================

CREATE PROCEDURE usp_GetCustomerDashboard
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Result Set 1: Customer Profile
    SELECT 
        CustomerID,
        CustomerName,
        State,
        JoinDate,
        TotalPurchases,
        DATEDIFF(DAY, JoinDate, GETDATE()) AS DaysSinceJoined,
        CASE 
            WHEN TotalPurchases >= 1000 THEN 'VIP'
            WHEN TotalPurchases >= 500 THEN 'Gold'
            ELSE 'Standard'
        END AS CustomerTier
    FROM Customers
    WHERE CustomerID = @CustomerID;
    
    -- Result Set 2: Recent Orders (Last 10)
    SELECT TOP 10
        s.SaleID,
        s.SaleDate,
        p.ProductName,
        s.Quantity,
        s.TotalAmount,
        s.PaymentMethod
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
    ORDER BY s.SaleDate DESC;
    
    -- Result Set 3: Purchase Summary by Category
    SELECT 
        p.Category,
        COUNT(s.SaleID) AS OrderCount,
        SUM(s.Quantity) AS TotalItems,
        SUM(s.TotalAmount) AS TotalSpent
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
    GROUP BY p.Category
    ORDER BY TotalSpent DESC;
    
    -- Result Set 4: Monthly Activity (Last 12 months)
    SELECT 
        YEAR(SaleDate) AS Year,
        MONTH(SaleDate) AS Month,
        DATENAME(MONTH, SaleDate) AS MonthName,
        COUNT(SaleID) AS Orders,
        SUM(TotalAmount) AS Spent
    FROM Sales
    WHERE CustomerID = @CustomerID
        AND SaleDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
    ORDER BY Year DESC, Month DESC;
END;
GO

-- View complete customer dashboard
EXEC usp_GetCustomerDashboard @CustomerID = 1;
GO

-- =============================================
-- Pattern 3: Report Generation with Date Range
-- =============================================

CREATE PROCEDURE usp_GenerateMonthlyReport
    @Year INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    
    -- Header Info
    SELECT 
        @Year AS ReportYear,
        @Month AS ReportMonth,
        DATENAME(MONTH, @StartDate) AS MonthName,
        @StartDate AS PeriodStart,
        @EndDate AS PeriodEnd;
    
    -- Sales Summary
    SELECT 
        COUNT(DISTINCT SaleID) AS TotalOrders,
        COUNT(DISTINCT CustomerID) AS UniqueCustomers,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue,
        MAX(TotalAmount) AS LargestOrder,
        MIN(TotalAmount) AS SmallestOrder
    FROM Sales
    WHERE SaleDate BETWEEN @StartDate AND @EndDate;
    
    -- Daily Breakdown
    SELECT 
        CAST(SaleDate AS DATE) AS Date,
        COUNT(SaleID) AS Orders,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    WHERE SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY CAST(SaleDate AS DATE)
    ORDER BY Date;
    
    -- Category Performance
    SELECT 
        p.Category,
        COUNT(s.SaleID) AS Orders,
        SUM(s.Quantity) AS UnitsSold,
        SUM(s.TotalAmount) AS Revenue,
        SUM(s.TotalAmount) * 100.0 / 
            (SELECT SUM(TotalAmount) FROM Sales WHERE SaleDate BETWEEN @StartDate AND @EndDate) AS RevenuePercent
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.Category
    ORDER BY Revenue DESC;
    
    -- Top 10 Products
    SELECT TOP 10
        p.ProductID,
        p.ProductName,
        p.Category,
        COUNT(s.SaleID) AS TimesSold,
        SUM(s.Quantity) AS TotalQuantity,
        SUM(s.TotalAmount) AS Revenue
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.SaleDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.ProductID, p.ProductName, p.Category
    ORDER BY Revenue DESC;
END;
GO

-- Generate report for specific month
EXEC usp_GenerateMonthlyReport @Year = 2024, @Month = 1;
GO

-- =============================================
-- Pattern 4: Batch Processing with Transaction
-- =============================================

CREATE PROCEDURE usp_ReorderInventory
    @ReorderThreshold INT = 10,
    @ReorderQuantity INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProductsToReorder TABLE (
        ProductID INT,
        ProductName NVARCHAR(100),
        CurrentStock INT,
        QuantityToOrder INT
    );
    
    -- Identify products needing reorder
    INSERT INTO @ProductsToReorder
    SELECT 
        ProductID,
        ProductName,
        StockQuantity,
        @ReorderQuantity
    FROM Products
    WHERE StockQuantity <= @ReorderThreshold
        AND IsActive = 1;
    
    -- Show reorder list
    SELECT 
        ProductID,
        ProductName,
        CurrentStock,
        QuantityToOrder,
        CurrentStock + QuantityToOrder AS NewStock
    FROM @ProductsToReorder;
    
    -- Simulate reorder (update stock)
    BEGIN TRANSACTION;
    
    BEGIN TRY
        UPDATE p
        SET StockQuantity = StockQuantity + r.QuantityToOrder
        FROM Products p
        INNER JOIN @ProductsToReorder r ON p.ProductID = r.ProductID;
        
        COMMIT TRANSACTION;
        
        PRINT 'Reorder completed for ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' products';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Reorder failed: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

-- Execute reorder process
EXEC usp_ReorderInventory @ReorderThreshold = 20, @ReorderQuantity = 50;
GO

-- =============================================
-- Pattern 5: Data Archival with Cleanup
-- =============================================

CREATE PROCEDURE usp_ArchiveOldSales
    @ArchiveDays INT = 365,
    @DeleteAfterArchive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATE = DATEADD(DAY, -@ArchiveDays, GETDATE());
    DECLARE @ArchivedCount INT;
    
    -- Show what will be archived
    SELECT 
        YEAR(SaleDate) AS Year,
        COUNT(*) AS SalesCount,
        SUM(TotalAmount) AS TotalRevenue
    FROM Sales
    WHERE SaleDate < @CutoffDate
    GROUP BY YEAR(SaleDate)
    ORDER BY Year;
    
    -- Count records
    SELECT @ArchivedCount = COUNT(*)
    FROM Sales
    WHERE SaleDate < @CutoffDate;
    
    PRINT 'Found ' + CAST(@ArchivedCount AS NVARCHAR(10)) + ' sales records older than ' + CAST(@ArchiveDays AS NVARCHAR(10)) + ' days';
    PRINT 'Cutoff date: ' + CAST(@CutoffDate AS NVARCHAR(20));
    
    -- Note: In production, you would:
    -- 1. Copy to archive table
    -- 2. Verify archive
    -- 3. Delete if @DeleteAfterArchive = 1
    
    /*
    -- Example archive logic:
    INSERT INTO SalesArchive SELECT * FROM Sales WHERE SaleDate < @CutoffDate;
    
    IF @DeleteAfterArchive = 1
    BEGIN
        DELETE FROM Sales WHERE SaleDate < @CutoffDate;
        PRINT 'Deleted ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' archived records';
    END;
    */
    
    PRINT 'Archive simulation complete';
    RETURN 0;
END;
GO

-- Simulate archival (no actual delete)
EXEC usp_ArchiveOldSales @ArchiveDays = 730, @DeleteAfterArchive = 0;
GO

-- =============================================
-- Pattern 6: Bulk Update with Logging
-- =============================================

CREATE PROCEDURE usp_BulkPriceUpdate
    @Category NVARCHAR(50),
    @AdjustmentPercent DECIMAL(5,2),
    @PreviewOnly BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedProducts TABLE (
        ProductID INT,
        ProductName NVARCHAR(100),
        OldPrice DECIMAL(10,2),
        NewPrice DECIMAL(10,2),
        PriceChange DECIMAL(10,2)
    );
    
    -- Calculate new prices
    INSERT INTO @AffectedProducts
    SELECT 
        ProductID,
        ProductName,
        Price AS OldPrice,
        Price * (1 + @AdjustmentPercent / 100.0) AS NewPrice,
        Price * (@AdjustmentPercent / 100.0) AS PriceChange
    FROM Products
    WHERE Category = @Category
        AND IsActive = 1;
    
    -- Show preview
    SELECT * FROM @AffectedProducts
    ORDER BY ProductName;
    
    -- Summary
    SELECT 
        COUNT(*) AS ProductsAffected,
        SUM(OldPrice) AS TotalOldValue,
        SUM(NewPrice) AS TotalNewValue,
        SUM(PriceChange) AS TotalPriceChange,
        @AdjustmentPercent AS AdjustmentPercent
    FROM @AffectedProducts;
    
    -- Apply changes if not preview mode
    IF @PreviewOnly = 0
    BEGIN
        BEGIN TRANSACTION;
        
        BEGIN TRY
            UPDATE p
            SET Price = a.NewPrice
            FROM Products p
            INNER JOIN @AffectedProducts a ON p.ProductID = a.ProductID;
            
            COMMIT TRANSACTION;
            
            PRINT 'Price update completed for ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' products';
            RETURN 0;
            
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            PRINT 'Price update failed: ' + ERROR_MESSAGE();
            RETURN -1;
        END CATCH;
    END
    ELSE
    BEGIN
        PRINT 'PREVIEW MODE - No changes applied';
        PRINT 'Set @PreviewOnly = 0 to apply changes';
        RETURN 0;
    END;
END;
GO

-- Preview price increase
EXEC usp_BulkPriceUpdate @Category = 'Electronics', @AdjustmentPercent = 10, @PreviewOnly = 1;

-- Apply price increase (uncomment to execute)
-- EXEC usp_BulkPriceUpdate @Category = 'Electronics', @AdjustmentPercent = 10, @PreviewOnly = 0;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP PROCEDURE IF EXISTS usp_SearchProducts;
DROP PROCEDURE IF EXISTS usp_GetCustomerDashboard;
DROP PROCEDURE IF EXISTS usp_GenerateMonthlyReport;
DROP PROCEDURE IF EXISTS usp_ReorderInventory;
DROP PROCEDURE IF EXISTS usp_ArchiveOldSales;
DROP PROCEDURE IF EXISTS usp_BulkPriceUpdate;
*/

-- 💡 Key Points:
-- - Use optional parameters (NULL defaults) for flexible searches
-- - Return multiple result sets for comprehensive dashboards
-- - Use table variables for intermediate results
-- - Preview mode (@PreviewOnly) for bulk operations
-- - Date range validation (DATEFROMPARTS, EOMONTH)
-- - Dynamic ORDER BY with CASE statements
-- - Batch processing with transactions
-- - Always show what will change before applying
-- - Log significant operations
-- - Provide summary statistics with results
