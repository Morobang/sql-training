/*
============================================================================
Lesson 09.05 - Multicolumn Subqueries
============================================================================

Description:
Learn to use subqueries that compare multiple columns simultaneously,
enabling complex tuple-based filtering and matching.

Topics Covered:
• Tuple comparisons
• Multiple column matching
• Combining with other conditions
• Use cases and patterns
• Performance considerations

Prerequisites:
• Lessons 09.01-09.04

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Multicolumn Subqueries
============================================================================
*/

-- Definition:
-- MULTICOLUMN SUBQUERY = Subquery that returns multiple columns
-- Used with tuple comparison: (col1, col2) = (val1, val2)

-- Example 1.1: Basic multicolumn comparison
SELECT ProductName, Price, Stock
FROM Products
WHERE (Price, Stock) = (
    SELECT MAX(Price), MIN(Stock)
    FROM Products
);
-- Finds product(s) with BOTH max price AND min stock

-- Example 1.2: Without multicolumn (requires multiple conditions)
-- This is NOT the same:
SELECT ProductName, Price, Stock
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products)
  AND Stock = (SELECT MIN(Stock) FROM Products);
-- This works only if the same product has both max price and min stock

-- Example 1.3: Multicolumn ensures matching row
SELECT ProductName, Price, Stock
FROM Products
WHERE (Price, Stock) IN (
    SELECT Price, Stock
    FROM Products
    WHERE CategoryID = 1
);
-- Products with same price-stock combination as any category 1 product


/*
============================================================================
PART 2: Tuple Equality
============================================================================
*/

-- Example 2.1: Two-column tuple
SELECT ProductName, CategoryID, SupplierID
FROM Products
WHERE (CategoryID, SupplierID) = (
    SELECT TOP 1 CategoryID, SupplierID
    FROM Products
    ORDER BY Price DESC
);
-- Products with same category and supplier as most expensive product

-- Example 2.2: Three-column tuple
SELECT OrderID, CustomerID, CAST(OrderDate AS DATE) AS OrderDate
FROM Orders
WHERE (CustomerID, CAST(OrderDate AS DATE), TotalAmount) = (
    SELECT TOP 1 CustomerID, CAST(OrderDate AS DATE), MAX(TotalAmount)
    FROM Orders
    GROUP BY CustomerID, CAST(OrderDate AS DATE)
    ORDER BY MAX(TotalAmount) DESC
);

-- Example 2.3: Tuple with IN (multiple matches)
SELECT ProductName, Price, Stock
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID
    FROM Products
    WHERE Price > 100
    GROUP BY CategoryID, SupplierID
);
-- Products sharing category-supplier with any product over $100


/*
============================================================================
PART 3: Practical Use Cases
============================================================================
*/

-- Use Case 3.1: Find duplicates
SELECT ProductName, Price, Stock
FROM Products p1
WHERE (Price, Stock) IN (
    SELECT Price, Stock
    FROM Products
    GROUP BY Price, Stock
    HAVING COUNT(*) > 1
)
ORDER BY Price, Stock;
-- Products with duplicate price-stock combinations

-- Use Case 3.2: Latest record per group
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Orders o1
WHERE (CustomerID, OrderDate) IN (
    SELECT CustomerID, MAX(OrderDate)
    FROM Orders
    GROUP BY CustomerID
);
-- Most recent order for each customer

-- Use Case 3.3: Matching combinations
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE (p.CategoryID, p.Price) IN (
    SELECT CategoryID, MAX(Price)
    FROM Products
    GROUP BY CategoryID
);
-- Most expensive product in each category

-- Use Case 3.4: Cross-reference matching
CREATE TABLE #PreferredCombinations (
    CategoryID INT,
    SupplierID INT
);
INSERT INTO #PreferredCombinations VALUES (1, 1), (2, 3), (3, 2);

SELECT ProductName, CategoryID, SupplierID
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID
    FROM #PreferredCombinations
);

DROP TABLE #PreferredCombinations;


/*
============================================================================
PART 4: Combining with Other Conditions
============================================================================
*/

-- Example 4.1: Multicolumn + additional WHERE
SELECT ProductName, Price, Stock, CategoryID
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID
    FROM Products
    WHERE Price > 50
    GROUP BY CategoryID, SupplierID
)
AND Stock > 0;
-- In-stock products with same category-supplier as products over $50

-- Example 4.2: Multicolumn with NOT IN
SELECT ProductName, CategoryID, SupplierID
FROM Products
WHERE (CategoryID, SupplierID) NOT IN (
    SELECT CategoryID, SupplierID
    FROM Products
    WHERE Discontinued = 1
);
-- Products with category-supplier different from discontinued products

-- Example 4.3: Nested multicolumn subqueries
SELECT ProductName, Price, CategoryID
FROM Products
WHERE (CategoryID, Price) IN (
    SELECT CategoryID, MAX(Price)
    FROM Products
    WHERE ProductID IN (
        SELECT ProductID
        FROM OrderDetails
        GROUP BY ProductID
        HAVING SUM(Quantity) > 10
    )
    GROUP BY CategoryID
);
-- Top-priced products in categories with high-volume products


/*
============================================================================
PART 5: Alternative Approaches
============================================================================
*/

-- Approach 5.1: Using JOIN instead of multicolumn subquery
-- ❌ Multicolumn subquery:
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE (p.CategoryID, p.Price) IN (
    SELECT CategoryID, MAX(Price)
    FROM Products
    GROUP BY CategoryID
);

-- ✅ JOIN alternative (often more readable):
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
JOIN (
    SELECT CategoryID, MAX(Price) AS MaxPrice
    FROM Products
    GROUP BY CategoryID
) MaxPrices ON p.CategoryID = MaxPrices.CategoryID 
           AND p.Price = MaxPrices.MaxPrice;

-- Approach 5.2: Using window functions
-- ✅ Modern approach with ROW_NUMBER:
SELECT ProductName, Price, CategoryID
FROM (
    SELECT 
        ProductName,
        Price,
        CategoryID,
        ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS rn
    FROM Products
) Ranked
WHERE rn = 1;
-- Most expensive product per category (cleaner!)

-- Approach 5.3: Using EXISTS
SELECT p1.ProductName, p1.Price, p1.Stock
FROM Products p1
WHERE EXISTS (
    SELECT 1
    FROM Products p2
    WHERE p2.Price = (SELECT MAX(Price) FROM Products)
      AND p2.Stock = (SELECT MIN(Stock) FROM Products)
      AND p1.Price = p2.Price
      AND p1.Stock = p2.Stock
);


/*
============================================================================
PART 6: Complex Scenarios
============================================================================
*/

-- Scenario 6.1: Order matching
-- Find orders with same customer-amount as best orders
SELECT o1.OrderID, o1.CustomerID, o1.TotalAmount, o1.OrderDate
FROM Orders o1
WHERE (o1.CustomerID, o1.TotalAmount) IN (
    SELECT CustomerID, MAX(TotalAmount)
    FROM Orders
    GROUP BY CustomerID
);

-- Scenario 6.2: Product category analysis
WITH CategoryStats AS (
    SELECT 
        CategoryID,
        AVG(Price) AS AvgPrice,
        AVG(Stock) AS AvgStock
    FROM Products
    GROUP BY CategoryID
)
SELECT p.ProductName, p.Price, p.Stock, p.CategoryID
FROM Products p
WHERE (p.Price, p.Stock) IN (
    SELECT ROUND(AvgPrice, 0), ROUND(AvgStock, 0)
    FROM CategoryStats
);
-- Products near category averages

-- Scenario 6.3: Time-based matching
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Orders o1
WHERE (YEAR(OrderDate), MONTH(OrderDate), CustomerID) IN (
    SELECT YEAR(OrderDate), MONTH(OrderDate), CustomerID
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate), CustomerID
    HAVING COUNT(*) > 1
);
-- Customers with multiple orders in same month


/*
============================================================================
PART 7: Performance Considerations
============================================================================
*/

-- Performance 7.1: Index multicolumn combinations
-- CREATE INDEX IX_Products_Category_Supplier ON Products(CategoryID, SupplierID);
SELECT ProductName
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID FROM PreferredCombos
);

-- Performance 7.2: ✅ JOIN often faster than multicolumn IN
-- Slower:
WHERE (Col1, Col2) IN (SELECT Col1, Col2 FROM LargeTable)

-- Faster:
JOIN (SELECT DISTINCT Col1, Col2 FROM LargeTable) t 
  ON Table.Col1 = t.Col1 AND Table.Col2 = t.Col2

-- Performance 7.3: ⚠️ NULL handling
CREATE TABLE #TestNull (Col1 INT, Col2 INT);
INSERT INTO #TestNull VALUES (1, 2), (NULL, 3);

-- Returns unexpected results with NULL:
SELECT * FROM Products
WHERE (CategoryID, SupplierID) NOT IN (
    SELECT Col1, Col2 FROM #TestNull
);
-- Filter NULL!

DROP TABLE #TestNull;

-- Performance 7.4: Limit columns in tuple
-- ❌ Too many columns (slower):
WHERE (Col1, Col2, Col3, Col4, Col5) IN (SELECT ...)

-- ✅ Fewer columns when possible:
WHERE (Col1, Col2) IN (SELECT ...) AND Col3 = X


/*
============================================================================
PART 8: Limitations and Alternatives
============================================================================
*/

-- Limitation 8.1: SQL Server tuple syntax limitations
-- Some databases support: WHERE (a, b) > (x, y)
-- SQL Server requires separate comparisons:
WHERE a > x OR (a = x AND b > y)

-- Limitation 8.2: Complex tuple expressions
-- ❌ Not directly supported:
-- WHERE (Price * 1.1, Stock - 5) IN (SELECT ...)

-- ✅ Use derived table:
WHERE (Price, Stock) IN (
    SELECT Price / 1.1, Stock + 5 FROM ...
)

-- Alternative 8.1: Use JOIN for complex matching
SELECT p.*
FROM Products p
JOIN (
    SELECT CategoryID, SupplierID, MAX(Price) AS MaxPrice
    FROM Products
    GROUP BY CategoryID, SupplierID
) t ON p.CategoryID = t.CategoryID 
   AND p.SupplierID = t.SupplierID 
   AND p.Price = t.MaxPrice;

-- Alternative 8.2: Use window functions
SELECT ProductName, Price, CategoryID
FROM (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS PriceRank
    FROM Products
) Ranked
WHERE PriceRank = 1;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find products with same price and category as top-selling products
2. Get most recent order for each customer (CustomerID, MAX(OrderDate))
3. Find duplicate price-stock combinations
4. Products with category-supplier matching any $100+ product
5. Compare: Multicolumn subquery vs JOIN vs window function

Solutions below ↓
*/

-- Solution 1:
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE (p.Price, p.CategoryID) IN (
    SELECT p2.Price, p2.CategoryID
    FROM Products p2
    JOIN OrderDetails od ON p2.ProductID = od.ProductID
    GROUP BY p2.ProductID, p2.Price, p2.CategoryID
    ORDER BY SUM(od.Quantity) DESC
);

-- Solution 2:
SELECT o.OrderID, o.CustomerID, o.OrderDate, o.TotalAmount
FROM Orders o
WHERE (o.CustomerID, o.OrderDate) IN (
    SELECT CustomerID, MAX(OrderDate)
    FROM Orders
    GROUP BY CustomerID
);

-- Solution 3:
SELECT p1.ProductName, p1.Price, p1.Stock
FROM Products p1
WHERE (p1.Price, p1.Stock) IN (
    SELECT Price, Stock
    FROM Products
    GROUP BY Price, Stock
    HAVING COUNT(*) > 1
)
ORDER BY p1.Price, p1.Stock;

-- Solution 4:
SELECT ProductName, CategoryID, SupplierID, Price
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID
    FROM Products
    WHERE Price >= 100
);

-- Solution 5:
-- A) Multicolumn subquery
SELECT ProductName, Price, CategoryID
FROM Products
WHERE (CategoryID, Price) IN (
    SELECT CategoryID, MAX(Price)
    FROM Products
    GROUP BY CategoryID
);

-- B) JOIN
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
JOIN (
    SELECT CategoryID, MAX(Price) AS MaxPrice
    FROM Products
    GROUP BY CategoryID
) m ON p.CategoryID = m.CategoryID AND p.Price = m.MaxPrice;

-- C) Window function
SELECT ProductName, Price, CategoryID
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS PriceRank
    FROM Products
) Ranked
WHERE PriceRank = 1;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ MULTICOLUMN SUBQUERIES:
  • Compare multiple columns as tuple
  • Syntax: (col1, col2) = (val1, val2)
  • Ensures matching combinations
  • Works with IN, NOT IN, =

✓ USE CASES:
  • Find duplicates
  • Latest record per group
  • Matching combinations
  • Complex filtering

✓ OPERATORS:
  • = : Single tuple match
  • IN : Multiple tuple matches
  • NOT IN : Exclusion (watch NULL!)

✓ ALTERNATIVES:
  • JOIN often clearer and faster
  • Window functions more modern
  • Derived tables for complex logic
  • EXISTS for existence checks

✓ PERFORMANCE:
  • Index column combinations
  • JOIN often faster than IN
  • Limit columns in tuple
  • Watch for NULL issues

✓ BEST PRACTICES:
  • Use when tuple matching needed
  • Consider JOIN for readability
  • Window functions for ranking
  • Filter NULL in NOT IN
  • Index composite columns

✓ LIMITATIONS:
  • SQL Server syntax restrictions
  • Complex expressions need workarounds
  • Can be less readable
  • Performance varies

============================================================================
NEXT: Lesson 09.06 - Correlated Subqueries
Learn subqueries that reference the outer query for row-by-row processing.
============================================================================
*/
