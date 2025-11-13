-- ========================================
-- Practical PIVOT/UNPIVOT Applications
-- ========================================

USE TechStore;

-- =============================================
-- Application 1: Sales Dashboard Report
-- =============================================

-- Monthly sales by category (pivoted view)
SELECT 
    Category,
    ISNULL([November], 0) AS Nov,
    ISNULL([December], 0) AS Dec,
    ISNULL([January], 0) AS Jan,
    ISNULL([November], 0) + ISNULL([December], 0) + ISNULL([January], 0) AS Total
FROM (
    SELECT 
        p.Category,
        DATENAME(MONTH, s.SaleDate) AS Month,
        s.TotalAmount
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([November], [December], [January])
) AS PivotTable
ORDER BY Total DESC;

-- =============================================
-- Application 2: Customer Segmentation Matrix
-- =============================================

-- Customer purchase behavior by category
SELECT 
    CustomerName,
    ISNULL([Electronics], 0) AS ElectronicsPurchases,
    ISNULL([Clothing], 0) AS ClothingPurchases,
    ISNULL([Books], 0) AS BooksPurchases,
    ISNULL([Toys], 0) AS ToysPurchases,
    CASE 
        WHEN (ISNULL([Electronics], 0) + ISNULL([Clothing], 0) + ISNULL([Books], 0) + ISNULL([Toys], 0)) >= 4 
        THEN 'Multi-Category Shopper'
        ELSE 'Single-Category Focus'
    END AS ShopperType
FROM (
    SELECT 
        c.CustomerName,
        p.Category,
        s.TotalAmount
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
    INNER JOIN Products p ON s.ProductID = p.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Category IN ([Electronics], [Clothing], [Books], [Toys])
) AS PivotTable
ORDER BY CustomerName;

-- =============================================
-- Application 3: Inventory Planning Matrix
-- =============================================

-- Stock levels by category and supplier
SELECT 
    Category,
    ISNULL([1], 0) AS Supplier1_Stock,
    ISNULL([2], 0) AS Supplier2_Stock,
    ISNULL([3], 0) AS Supplier3_Stock,
    ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) AS TotalStock
FROM (
    SELECT 
        Category,
        SupplierID,
        StockQuantity
    FROM Products
    WHERE SupplierID IS NOT NULL
) AS SourceData
PIVOT (
    SUM(StockQuantity)
    FOR SupplierID IN ([1], [2], [3])
) AS PivotTable
ORDER BY Category;

-- =============================================
-- Application 4: Year-over-Year Comparison
-- =============================================

-- Create sample data with years
CREATE TABLE #YearlySales (
    ProductID INT,
    Year INT,
    Revenue DECIMAL(10,2)
);

INSERT INTO #YearlySales VALUES
    (1, 2023, 5000), (1, 2024, 6500),
    (2, 2023, 3000), (2, 2024, 3200),
    (3, 2023, 4500), (3, 2024, 5800);

-- PIVOT years for comparison
SELECT 
    p.ProductName,
    ISNULL([2023], 0) AS Revenue2023,
    ISNULL([2024], 0) AS Revenue2024,
    ISNULL([2024], 0) - ISNULL([2023], 0) AS YoYGrowth,
    CASE 
        WHEN ISNULL([2023], 0) > 0 
        THEN CAST((ISNULL([2024], 0) - ISNULL([2023], 0)) * 100.0 / ISNULL([2023], 0) AS DECIMAL(5,2))
        ELSE 0
    END AS GrowthPct
FROM (
    SELECT 
        ys.ProductID,
        ys.Year,
        ys.Revenue
    FROM #YearlySales ys
) AS SourceData
PIVOT (
    SUM(Revenue)
    FOR Year IN ([2023], [2024])
) AS PivotTable
INNER JOIN Products p ON PivotTable.ProductID = p.ProductID
ORDER BY GrowthPct DESC;

DROP TABLE #YearlySales;

-- =============================================
-- Application 5: Normalizing Imported Data
-- =============================================

-- Simulate imported spreadsheet data
CREATE TABLE #ImportedProductData (
    ProductID INT,
    ProductName NVARCHAR(100),
    Jan2024 DECIMAL(10,2),
    Feb2024 DECIMAL(10,2),
    Mar2024 DECIMAL(10,2),
    Apr2024 DECIMAL(10,2)
);

INSERT INTO #ImportedProductData VALUES
    (1, 'Laptop', 1200, 1500, 1800, 2000),
    (2, 'Phone', 800, 900, 850, 1100),
    (3, 'Tablet', 500, 600, 550, 700);

SELECT * FROM #ImportedProductData;

-- UNPIVOT to normalize for database storage
SELECT 
    ProductID,
    ProductName,
    Month,
    Revenue
FROM #ImportedProductData
UNPIVOT (
    Revenue FOR Month IN ([Jan2024], [Feb2024], [Mar2024], [Apr2024])
) AS UnpivotTable
ORDER BY ProductID, Month;

DROP TABLE #ImportedProductData;

-- =============================================
-- Application 6: Cross-Tab Analysis
-- =============================================

-- Payment method preferences by state
SELECT 
    State,
    ISNULL([Credit Card], 0) AS CreditCard,
    ISNULL([Cash], 0) AS Cash,
    ISNULL([PayPal], 0) AS PayPal,
    -- Calculate preferred method
    CASE 
        WHEN ISNULL([Credit Card], 0) >= ISNULL([Cash], 0) AND ISNULL([Credit Card], 0) >= ISNULL([PayPal], 0) 
        THEN 'Credit Card'
        WHEN ISNULL([Cash], 0) >= ISNULL([PayPal], 0) 
        THEN 'Cash'
        ELSE 'PayPal'
    END AS PreferredMethod
FROM (
    SELECT 
        c.State,
        s.PaymentMethod,
        s.SaleID
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
) AS SourceData
PIVOT (
    COUNT(SaleID)
    FOR PaymentMethod IN ([Credit Card], [Cash], [PayPal])
) AS PivotTable
ORDER BY State;

-- =============================================
-- Application 7: Product Performance Matrix
-- =============================================

-- Products sold across different states
SELECT 
    ProductName,
    ISNULL([CA], 0) AS California,
    ISNULL([NY], 0) AS NewYork,
    ISNULL([TX], 0) AS Texas,
    ISNULL([FL], 0) AS Florida,
    ISNULL([CA], 0) + ISNULL([NY], 0) + ISNULL([TX], 0) + ISNULL([FL], 0) AS TotalSales,
    -- Identify best market
    CASE 
        WHEN ISNULL([CA], 0) >= ISNULL([NY], 0) AND ISNULL([CA], 0) >= ISNULL([TX], 0) AND ISNULL([CA], 0) >= ISNULL([FL], 0) 
        THEN 'CA'
        WHEN ISNULL([NY], 0) >= ISNULL([TX], 0) AND ISNULL([NY], 0) >= ISNULL([FL], 0) 
        THEN 'NY'
        WHEN ISNULL([TX], 0) >= ISNULL([FL], 0) 
        THEN 'TX'
        ELSE 'FL'
    END AS BestMarket
FROM (
    SELECT 
        p.ProductName,
        c.State,
        s.Quantity
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
    INNER JOIN Customers c ON s.CustomerID = c.CustomerID
    WHERE c.State IN ('CA', 'NY', 'TX', 'FL')
) AS SourceData
PIVOT (
    SUM(Quantity)
    FOR State IN ([CA], [NY], [TX], [FL])
) AS PivotTable
ORDER BY TotalSales DESC;

-- =============================================
-- Application 8: PIVOT to UNPIVOT Round-Trip
-- =============================================

-- Step 1: Create pivoted summary
CREATE TABLE #CategoryMonthly (
    Category NVARCHAR(50),
    Nov DECIMAL(10,2),
    Dec DECIMAL(10,2),
    Jan DECIMAL(10,2)
);

INSERT INTO #CategoryMonthly
SELECT 
    Category,
    ISNULL([November], 0),
    ISNULL([December], 0),
    ISNULL([January], 0)
FROM (
    SELECT 
        p.Category,
        DATENAME(MONTH, s.SaleDate) AS Month,
        s.TotalAmount
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([November], [December], [January])
) AS PivotTable;

SELECT * FROM #CategoryMonthly;

-- Step 2: UNPIVOT back to detail format
SELECT 
    Category,
    Month,
    Revenue
FROM #CategoryMonthly
UNPIVOT (
    Revenue FOR Month IN ([Nov], [Dec], [Jan])
) AS UnpivotTable
ORDER BY Category, Month;

DROP TABLE #CategoryMonthly;

-- 💡 Key Practical Uses:
-- - PIVOT: Create cross-tab reports, dashboards, Excel-like views
-- - UNPIVOT: Normalize imported spreadsheet data
-- - Combine both: Transform data for different analysis needs
-- - Use for month-over-month, year-over-year comparisons
-- - Build customer segmentation matrices
-- - Analyze trends across categories, regions, time periods
