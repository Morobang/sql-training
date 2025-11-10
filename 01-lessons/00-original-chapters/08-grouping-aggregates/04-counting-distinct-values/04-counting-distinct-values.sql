/*
============================================================================
Lesson 08.04 - Counting Distinct Values
============================================================================

Description:
Master the COUNT(DISTINCT) function to find unique values, eliminate
duplicates, and perform accurate counting in your analysis.

Topics Covered:
• COUNT vs COUNT(DISTINCT)
• Finding unique values
• Counting multiple distinct columns
• Deduplication strategies
• Performance considerations

Prerequisites:
• Lessons 08.01-08.03

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: COUNT vs COUNT(DISTINCT)
============================================================================
*/

-- Example 1.1: Basic COUNT
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(CustomerID) AS NonNullCustomers,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

-- Example 1.2: Visual demonstration
CREATE TABLE #SampleData (
    ID INT,
    Category VARCHAR(10)
);

INSERT INTO #SampleData VALUES
(1, 'A'),
(2, 'B'),
(3, 'A'),
(4, 'B'),
(5, 'A'),
(6, NULL);

SELECT 
    COUNT(*) AS TotalRows,              -- 6 (all rows)
    COUNT(Category) AS NonNull,         -- 5 (excludes NULL)
    COUNT(DISTINCT Category) AS Unique; -- 2 ('A' and 'B')

DROP TABLE #SampleData;

-- Example 1.3: The difference matters
SELECT 
    COUNT(CategoryID) AS TotalReferences,          -- How many products have a category
    COUNT(DISTINCT CategoryID) AS UniqueCategories -- How many different categories exist
FROM Products;


/*
============================================================================
PART 2: Finding Unique Values
============================================================================
*/

-- Example 2.1: Count unique customers who ordered
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

-- Example 2.2: Unique values per group
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    CAST(COUNT(*) AS DECIMAL(10,2)) / COUNT(DISTINCT CustomerID) AS OrdersPerCustomer
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Example 2.3: Multiple distinct counts
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT ProductID) AS UniqueProducts,
    COUNT(*) AS TotalOrderLines
FROM OrderDetails;

-- Example 2.4: Unique values in different columns
SELECT 
    COUNT(DISTINCT City) AS UniqueCities,
    COUNT(DISTINCT State) AS UniqueStates,
    COUNT(DISTINCT Country) AS UniqueCountries
FROM Customers;


/*
============================================================================
PART 3: Deduplication Patterns
============================================================================
*/

-- Pattern 3.1: Find duplicate email addresses
SELECT 
    Email,
    COUNT(*) AS Occurrences
FROM Customers
GROUP BY Email
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;

-- Pattern 3.2: Count products per category (unique)
SELECT 
    CategoryID,
    COUNT(DISTINCT ProductID) AS UniqueProducts
FROM Products
GROUP BY CategoryID;

-- Pattern 3.3: Customers with repeat purchases
SELECT 
    CustomerID,
    COUNT(DISTINCT CAST(OrderDate AS DATE)) AS UniqueDays,
    COUNT(*) AS TotalOrders
FROM Orders
GROUP BY CustomerID
HAVING COUNT(DISTINCT CAST(OrderDate AS DATE)) < COUNT(*)
ORDER BY TotalOrders DESC;
-- Shows customers who made multiple orders on same days

-- Pattern 3.4: Unique combinations
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT ProductID) AS UniqueProducts,
    COUNT(DISTINCT CONCAT(CustomerID, '-', ProductID)) AS UniqueCustomerProductPairs
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID;


/*
============================================================================
PART 4: COUNT(DISTINCT) with GROUP BY
============================================================================
*/

-- Example 4.1: Unique customers per product
SELECT 
    ProductID,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS TimesPurchased
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY ProductID
ORDER BY UniqueCustomers DESC;

-- Example 4.2: Product diversity per customer
SELECT 
    CustomerID,
    COUNT(DISTINCT od.ProductID) AS UniqueProductsBought,
    COUNT(*) AS TotalItemsPurchased,
    SUM(od.Quantity) AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY CustomerID
ORDER BY UniqueProductsBought DESC;

-- Example 4.3: Monthly customer acquisition
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Example 4.4: Category reach per customer
SELECT 
    o.CustomerID,
    COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased,
    COUNT(DISTINCT od.ProductID) AS UniqueProducts
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT p.CategoryID) > 1
ORDER BY CategoriesPurchased DESC;


/*
============================================================================
PART 5: Multiple Columns (Limitation and Workaround)
============================================================================
*/

-- Example 5.1: ❌ Can't do COUNT(DISTINCT col1, col2) directly in SQL Server
-- SELECT COUNT(DISTINCT CustomerID, ProductID)  -- ERROR!
-- FROM OrderDetails;

-- Example 5.2: ✅ Workaround - Concatenate columns
SELECT 
    COUNT(DISTINCT CONCAT(CustomerID, '|', ProductID)) AS UniquePairs
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Example 5.3: ✅ Workaround - Subquery with DISTINCT
SELECT COUNT(*) AS UniquePairs
FROM (
    SELECT DISTINCT o.CustomerID, od.ProductID
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
) UniqueCombinations;

-- Example 5.4: ✅ Workaround - CHECKSUM or HASHBYTES
SELECT 
    COUNT(DISTINCT CHECKSUM(CustomerID, ProductID)) AS ApproxUniquePairs
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Note: CHECKSUM can have collisions (rare), use for approximation


/*
============================================================================
PART 6: Performance Considerations
============================================================================
*/

-- Performance 6.1: COUNT(*) is faster than COUNT(DISTINCT)
-- COUNT(*): Just counts rows
-- COUNT(DISTINCT): Must sort/hash to find unique values

-- Example 6.2: Indexing helps COUNT(DISTINCT)
-- CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
SELECT COUNT(DISTINCT CustomerID) FROM Orders;
-- Index on CustomerID speeds this up

-- Example 6.3: Filter before DISTINCT when possible
-- ✅ GOOD: Filter first
SELECT COUNT(DISTINCT CustomerID)
FROM Orders
WHERE OrderDate >= '2025-01-01';

-- ❌ LESS EFFICIENT: Count all, then filter groups
SELECT COUNT(DISTINCT CustomerID)
FROM Orders
GROUP BY YEAR(OrderDate)
HAVING YEAR(OrderDate) = 2025;


/*
============================================================================
PART 7: Real-World Scenarios
============================================================================
*/

-- Scenario 7.1: Customer engagement metrics
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS ActiveCustomers,
    CAST(COUNT(*) AS DECIMAL(10,2)) / COUNT(DISTINCT CustomerID) AS AvgOrdersPerCustomer,
    SUM(TotalAmount) AS Revenue,
    SUM(TotalAmount) / COUNT(DISTINCT CustomerID) AS RevenuePerCustomer
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Scenario 7.2: Product popularity analysis
SELECT 
    p.ProductName,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS TimesPurchased,
    SUM(od.Quantity) AS TotalQuantitySold,
    CAST(COUNT(DISTINCT o.CustomerID) AS DECIMAL(10,2)) / 
        (SELECT COUNT(*) FROM Customers) * 100 AS CustomerPenetration
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName
ORDER BY UniqueCustomers DESC;

-- Scenario 7.3: Cross-sell opportunity
SELECT 
    o.CustomerID,
    COUNT(DISTINCT p.CategoryID) AS CategoriesBought,
    (SELECT COUNT(DISTINCT CategoryID) FROM Products) AS TotalCategories,
    (SELECT COUNT(DISTINCT CategoryID) FROM Products) - 
        COUNT(DISTINCT p.CategoryID) AS UntappedCategories
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT p.CategoryID) < (SELECT COUNT(DISTINCT CategoryID) FROM Products)
ORDER BY UntappedCategories DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Count unique customers who placed orders
2. Find products purchased by more than 10 unique customers
3. Count unique products sold each month
4. Find customers who bought from multiple categories
5. Calculate customer retention (repeat buyers)

Solutions below ↓
*/

-- Solution 1:
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

-- Solution 2:
SELECT 
    od.ProductID,
    p.ProductName,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY od.ProductID, p.ProductName
HAVING COUNT(DISTINCT o.CustomerID) > 10
ORDER BY UniqueCustomers DESC;

-- Solution 3:
SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    COUNT(DISTINCT od.ProductID) AS UniqueProducts
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY Year, Month;

-- Solution 4:
SELECT 
    o.CustomerID,
    COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased,
    COUNT(DISTINCT od.ProductID) AS UniqueProducts
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT p.CategoryID) > 1
ORDER BY CategoriesPurchased DESC;

-- Solution 5:
SELECT 
    'Total Customers' AS Metric,
    COUNT(DISTINCT CustomerID) AS Count
FROM Customers
UNION ALL
SELECT 
    'Customers Who Ordered',
    COUNT(DISTINCT CustomerID)
FROM Orders
UNION ALL
SELECT 
    'Repeat Customers',
    COUNT(DISTINCT CustomerID)
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 1;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ COUNT VARIATIONS:
  • COUNT(*): All rows
  • COUNT(column): Non-NULL values
  • COUNT(DISTINCT column): Unique non-NULL values

✓ USE CASES:
  • Find number of unique customers
  • Detect duplicates
  • Calculate diversity metrics
  • Measure customer engagement

✓ WORKAROUNDS:
  • Concatenate for multiple columns
  • Use subquery with DISTINCT
  • CHECKSUM for approximation

✓ PERFORMANCE:
  • COUNT(DISTINCT) is slower than COUNT(*)
  • Index the column being counted
  • Filter early with WHERE

✓ BEST PRACTICES:
  • Use DISTINCT only when needed
  • Consider indexes for performance
  • Handle NULL values appropriately
  • Validate results with sample queries

============================================================================
NEXT: Lesson 08.05 - Using Expressions
Learn to group by calculated columns and expressions.
============================================================================
*/
