-- ========================================
-- Practical Subquery Examples
-- ========================================

USE TechStore;

-- 1. Find VIP customers (top 20% spenders)
SELECT 
    CustomerName,
    TotalSpent,
    'VIP' AS Tier
FROM (
    SELECT 
        c.CustomerName,
        SUM(s.TotalAmount) AS TotalSpent
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerName
) AS CustomerSpending
WHERE TotalSpent >= (
    SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY TotalSpent)
    FROM (
        SELECT SUM(TotalAmount) AS TotalSpent
        FROM Sales
        GROUP BY CustomerID
    ) AS Spending
)
ORDER BY TotalSpent DESC;

-- 2. Products performing better than category median
SELECT 
    ProductName,
    Category,
    SalesCount,
    CategoryMedian
FROM (
    SELECT 
        p.ProductName,
        p.Category,
        COUNT(s.SaleID) AS SalesCount,
        (SELECT AVG(SaleCount)
         FROM (
             SELECT COUNT(*) AS SaleCount
             FROM Sales s2
             INNER JOIN Products p2 ON s2.ProductID = p2.ProductID
             WHERE p2.Category = p.Category
             GROUP BY s2.ProductID
         ) AS CategorySales) AS CategoryMedian
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductName, p.Category
) AS ProductPerformance
WHERE SalesCount > CategoryMedian
ORDER BY Category, SalesCount DESC;

-- 3. Second-highest paid employee per department
SELECT 
    DepartmentID,
    EmployeeID,
    Salary
FROM (
    SELECT 
        DepartmentID,
        EmployeeID,
        Salary,
        RANK() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS SalaryRank
    FROM Employees
) AS RankedEmployees
WHERE SalaryRank = 2;

-- 4. Customers with recent activity (last 30 days)
SELECT 
    c.CustomerName,
    c.City,
    LastPurchase,
    DaysSinceLastPurchase
FROM Customers c
INNER JOIN (
    SELECT 
        CustomerID,
        MAX(SaleDate) AS LastPurchase,
        DATEDIFF(DAY, MAX(SaleDate), GETDATE()) AS DaysSinceLastPurchase
    FROM Sales
    GROUP BY CustomerID
) AS RecentActivity ON c.CustomerID = RecentActivity.CustomerID
WHERE DaysSinceLastPurchase <= 30
ORDER BY LastPurchase DESC;

-- 5. Products with inventory alerts
SELECT 
    ProductName,
    Category,
    StockQuantity,
    AverageSalesPerDay,
    DaysUntilStockout
FROM (
    SELECT 
        p.ProductName,
        p.Category,
        p.StockQuantity,
        (SELECT AVG(DailySales)
         FROM (
             SELECT 
                 CAST(SaleDate AS DATE) AS SaleDay,
                 SUM(Quantity) AS DailySales
             FROM Sales
             WHERE ProductID = p.ProductID
             GROUP BY CAST(SaleDate AS DATE)
         ) AS DailySalesData) AS AverageSalesPerDay,
        CASE 
            WHEN (SELECT AVG(DailySales)
                  FROM (
                      SELECT SUM(Quantity) AS DailySales
                      FROM Sales
                      WHERE ProductID = p.ProductID
                      GROUP BY CAST(SaleDate AS DATE)
                  ) AS DailySalesData) > 0
            THEN p.StockQuantity / (SELECT AVG(DailySales)
                                    FROM (
                                        SELECT SUM(Quantity) AS DailySales
                                        FROM Sales
                                        WHERE ProductID = p.ProductID
                                        GROUP BY CAST(SaleDate AS DATE)
                                    ) AS DailySalesData)
            ELSE NULL
        END AS DaysUntilStockout
    FROM Products p
) AS InventoryAnalysis
WHERE DaysUntilStockout IS NOT NULL AND DaysUntilStockout < 30
ORDER BY DaysUntilStockout;
