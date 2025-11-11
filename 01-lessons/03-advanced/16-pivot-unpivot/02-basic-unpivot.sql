-- ========================================
-- UNPIVOT: Basic Examples
-- ========================================

USE TechStore;

-- =============================================
-- Setup: Create sample pivoted data
-- =============================================

CREATE TABLE #MonthlySales (
    Category NVARCHAR(50),
    January DECIMAL(10,2),
    February DECIMAL(10,2),
    March DECIMAL(10,2),
    April DECIMAL(10,2)
);

INSERT INTO #MonthlySales VALUES
    ('Electronics', 1500.00, 2000.00, 1800.00, 2200.00),
    ('Clothing', 800.00, 900.00, 1100.00, 950.00),
    ('Books', 400.00, 500.00, 450.00, 600.00);

SELECT * FROM #MonthlySales;

-- =============================================
-- Example 1: Basic UNPIVOT
-- =============================================

-- Transform columns into rows
SELECT 
    Category,
    Month,
    Revenue
FROM #MonthlySales
UNPIVOT (
    Revenue FOR Month IN ([January], [February], [March], [April])
) AS UnpivotTable
ORDER BY Category, Month;

-- 💡 UNPIVOT normalizes data: columns become rows

-- =============================================
-- Example 2: Product Metrics Unpivot
-- =============================================

-- Create sample wide-format data
CREATE TABLE #ProductMetrics (
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2),
    Cost DECIMAL(10,2),
    Stock INT
);

INSERT INTO #ProductMetrics VALUES
    ('Laptop', 899.99, 500.00, 15),
    ('Phone', 599.99, 350.00, 30),
    ('Tablet', 399.99, 250.00, 20);

SELECT * FROM #ProductMetrics;

-- UNPIVOT metrics into single column
SELECT 
    ProductName,
    MetricName,
    MetricValue
FROM #ProductMetrics
UNPIVOT (
    MetricValue FOR MetricName IN ([Price], [Cost], [Stock])
) AS UnpivotTable
ORDER BY ProductName, MetricName;

-- =============================================
-- Example 3: Customer Purchase Channels
-- =============================================

CREATE TABLE #CustomerChannels (
    CustomerName NVARCHAR(100),
    Online INT,
    InStore INT,
    Phone INT
);

INSERT INTO #CustomerChannels VALUES
    ('John Smith', 5, 2, 1),
    ('Jane Doe', 3, 4, 0),
    ('Bob Johnson', 1, 1, 2);

SELECT * FROM #CustomerChannels;

-- UNPIVOT channels
SELECT 
    CustomerName,
    Channel,
    OrderCount
FROM #CustomerChannels
UNPIVOT (
    OrderCount FOR Channel IN ([Online], [InStore], [Phone])
) AS UnpivotTable
WHERE OrderCount > 0  -- Filter out zeros
ORDER BY CustomerName, Channel;

-- =============================================
-- Example 4: Quarterly Revenue Unpivot
-- =============================================

CREATE TABLE #QuarterlyRevenue (
    Year INT,
    Q1 DECIMAL(10,2),
    Q2 DECIMAL(10,2),
    Q3 DECIMAL(10,2),
    Q4 DECIMAL(10,2)
);

INSERT INTO #QuarterlyRevenue VALUES
    (2023, 10000.00, 12000.00, 11500.00, 15000.00),
    (2024, 13000.00, 14500.00, 16000.00, NULL);

SELECT * FROM #QuarterlyRevenue;

-- UNPIVOT quarters
SELECT 
    Year,
    Quarter,
    Revenue
FROM #QuarterlyRevenue
UNPIVOT (
    Revenue FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS UnpivotTable
ORDER BY Year, Quarter;

-- Note: NULL values are excluded from UNPIVOT results

-- =============================================
-- Example 5: Alternative to UNPIVOT using UNION
-- =============================================

-- UNPIVOT can also be done with UNION (more flexible but verbose)
SELECT Category, 'January' AS Month, January AS Revenue FROM #MonthlySales
UNION ALL
SELECT Category, 'February', February FROM #MonthlySales
UNION ALL
SELECT Category, 'March', March FROM #MonthlySales
UNION ALL
SELECT Category, 'April', April FROM #MonthlySales
ORDER BY Category, Month;

-- Compare with UNPIVOT (cleaner syntax)
SELECT Category, Month, Revenue
FROM #MonthlySales
UNPIVOT (Revenue FOR Month IN ([January], [February], [March], [April])) AS U
ORDER BY Category, Month;

-- =============================================
-- Example 6: UNPIVOT with Multiple Value Columns
-- =============================================

CREATE TABLE #ProductComparison (
    Category NVARCHAR(50),
    Price2023 DECIMAL(10,2),
    Price2024 DECIMAL(10,2),
    Stock2023 INT,
    Stock2024 INT
);

INSERT INTO #ProductComparison VALUES
    ('Electronics', 800.00, 850.00, 50, 45),
    ('Clothing', 60.00, 65.00, 100, 120);

-- UNPIVOT years for prices
SELECT 
    Category,
    Year,
    Price
FROM #ProductComparison
UNPIVOT (
    Price FOR Year IN ([Price2023], [Price2024])
) AS UnpivotTable;

-- UNPIVOT years for stock
SELECT 
    Category,
    Year,
    Stock
FROM #ProductComparison
UNPIVOT (
    Stock FOR Year IN ([Stock2023], [Stock2024])
) AS UnpivotTable;

-- =============================================
-- Example 7: Real-World Use Case - Normalizing Survey Data
-- =============================================

CREATE TABLE #SurveyResponses (
    RespondentID INT,
    RespondentName NVARCHAR(100),
    Question1_Rating INT,
    Question2_Rating INT,
    Question3_Rating INT
);

INSERT INTO #SurveyResponses VALUES
    (1, 'Alice', 5, 4, 5),
    (2, 'Bob', 4, 5, 4),
    (3, 'Charlie', 3, 3, 4);

SELECT * FROM #SurveyResponses;

-- UNPIVOT into normalized format
SELECT 
    RespondentID,
    RespondentName,
    Question,
    Rating
FROM #SurveyResponses
UNPIVOT (
    Rating FOR Question IN ([Question1_Rating], [Question2_Rating], [Question3_Rating])
) AS UnpivotTable
ORDER BY RespondentID, Question;

-- Now data is normalized and easier to analyze
SELECT 
    Question,
    AVG(CAST(Rating AS FLOAT)) AS AvgRating,
    MIN(Rating) AS MinRating,
    MAX(Rating) AS MaxRating
FROM #SurveyResponses
UNPIVOT (
    Rating FOR Question IN ([Question1_Rating], [Question2_Rating], [Question3_Rating])
) AS UnpivotTable
GROUP BY Question;

-- =============================================
-- Clean up
-- =============================================
DROP TABLE #MonthlySales;
DROP TABLE #ProductMetrics;
DROP TABLE #CustomerChannels;
DROP TABLE #QuarterlyRevenue;
DROP TABLE #ProductComparison;
DROP TABLE #SurveyResponses;

-- 💡 Key Points:
-- - UNPIVOT transforms columns into rows (opposite of PIVOT)
-- - Converts wide-format data to long-format (normalized)
-- - NULL values are automatically excluded
-- - Column names must be explicitly listed
-- - Alternative: UNION ALL (more flexible but verbose)
-- - Great for normalizing imported data
