/*
============================================================================
Lesson 09.02 - Subquery Types
============================================================================

Description:
Understand the different types of subqueries based on what they return:
scalar, row, column, and table subqueries.

Topics Covered:
• Scalar subqueries (single value)
• Row subqueries (single row, multiple columns)
• Column subqueries (multiple rows, single column)
• Table subqueries (multiple rows and columns)
• Choosing the right type

Prerequisites:
• Lesson 09.01

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Scalar Subqueries (Single Value)
============================================================================
Returns: ONE row, ONE column
Used with: =, >, <, >=, <=, <> operators
*/

-- Example 1.1: Basic scalar subquery
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
-- Subquery returns: 55.75 (single number)

-- Example 1.2: Scalar in SELECT clause
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS Difference
FROM Products;
-- Each subquery returns a single value used for every row

-- Example 1.3: Scalar in comparison
SELECT OrderID, TotalAmount
FROM Orders
WHERE TotalAmount = (SELECT MAX(TotalAmount) FROM Orders);
-- Finds the order(s) with maximum amount

-- Example 1.4: Multiple scalar subqueries
SELECT 
    ProductName,
    Price,
    (SELECT MIN(Price) FROM Products) AS MinPrice,
    (SELECT MAX(Price) FROM Products) AS MaxPrice,
    (SELECT AVG(Price) FROM Products) AS AvgPrice
FROM Products;

-- Example 1.5: ❌ ERROR if subquery returns multiple values
-- SELECT ProductName
-- FROM Products
-- WHERE CategoryID = (SELECT CategoryID FROM Categories);  -- ERROR!
-- This subquery returns multiple CategoryIDs, can't use with =


/*
============================================================================
PART 2: Row Subqueries (Single Row, Multiple Columns)
============================================================================
Returns: ONE row, MULTIPLE columns
Used with: Tuple comparison (col1, col2) = (val1, val2)
*/

-- Example 2.1: Row subquery comparison
SELECT ProductName, Price, Stock
FROM Products
WHERE (Price, Stock) = (
    SELECT MAX(Price), MIN(Stock)
    FROM Products
);
-- Finds product(s) with max price AND min stock

-- Example 2.2: Multiple column matching
SELECT *
FROM Orders
WHERE (CustomerID, TotalAmount) = (
    SELECT TOP 1 CustomerID, MAX(TotalAmount)
    FROM Orders
    GROUP BY CustomerID
    ORDER BY MAX(TotalAmount) DESC
);
-- Finds order matching top customer and their max amount

-- Example 2.3: Row subquery with expressions
SELECT ProductName, Price, Stock
FROM Products
WHERE (CategoryID, Price) = (
    SELECT CategoryID, MAX(Price)
    FROM Products
    WHERE Stock > 0
    GROUP BY CategoryID
    HAVING CategoryID = 1
);

-- Note: Row subqueries less common in SQL Server than other databases


/*
============================================================================
PART 3: Column Subqueries (Multiple Rows, Single Column)
============================================================================
Returns: MULTIPLE rows, ONE column
Used with: IN, NOT IN, ANY, ALL operators
*/

-- Example 3.1: Basic column subquery with IN
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE CategoryName LIKE '%Electronics%'
);
-- Subquery returns list of CategoryIDs: (1, 3, 5)

-- Example 3.2: NOT IN for exclusion
SELECT CustomerName
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID
    FROM Orders
);
-- Finds customers who never ordered

-- Example 3.3: Column subquery with ANY
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1
);
-- Finds products more expensive than ANY product in category 1
-- (essentially greater than the minimum)

-- Example 3.4: Column subquery with ALL
SELECT ProductName, Price
FROM Products
WHERE Price > ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1
);
-- Finds products more expensive than ALL products in category 1
-- (essentially greater than the maximum)


/*
============================================================================
PART 4: Table Subqueries (Multiple Rows and Columns)
============================================================================
Returns: MULTIPLE rows, MULTIPLE columns
Used in: FROM clause (derived tables), INSERT, EXISTS
*/

-- Example 4.1: Table subquery in FROM clause (derived table)
SELECT *
FROM (
    SELECT ProductName, Price, Stock, Price * Stock AS InventoryValue
    FROM Products
    WHERE Stock > 0
) AS InStockProducts
WHERE InventoryValue > 1000
ORDER BY InventoryValue DESC;

-- Example 4.2: Table subquery with aggregation
SELECT CategoryName, AvgPrice, ProductCount
FROM (
    SELECT 
        CategoryID,
        AVG(Price) AS AvgPrice,
        COUNT(*) AS ProductCount
    FROM Products
    GROUP BY CategoryID
) AS CategoryStats
JOIN Categories c ON CategoryStats.CategoryID = c.CategoryID
WHERE AvgPrice > 50;

-- Example 4.3: Table subquery with EXISTS
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT *  -- Can be SELECT 1 or SELECT *
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.TotalAmount > 1000
);
-- Finds customers with at least one large order

-- Example 4.4: Table subquery in INSERT
CREATE TABLE #HighValueProducts (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    InventoryValue DECIMAL(10,2)
);

INSERT INTO #HighValueProducts
SELECT 
    ProductID,
    ProductName,
    Price,
    Price * Stock AS InventoryValue
FROM Products
WHERE Price * Stock > 1000;

SELECT * FROM #HighValueProducts;
DROP TABLE #HighValueProducts;


/*
============================================================================
PART 5: Comparison of Types
============================================================================
*/

-- Comparison 5.1: Visual representation
/*
SCALAR (1 row, 1 column):
    +-------+
    | 55.75 |
    +-------+

ROW (1 row, multiple columns):
    +----+-------+-------+
    | 1  | 99.99 | 10    |
    +----+-------+-------+

COLUMN (multiple rows, 1 column):
    +----+
    | 1  |
    | 3  |
    | 5  |
    +----+

TABLE (multiple rows and columns):
    +----+----------+-------+
    | 1  | Product1 | 29.99 |
    | 2  | Product2 | 49.99 |
    | 3  | Product3 | 19.99 |
    +----+----------+-------+
*/

-- Comparison 5.2: Examples of each type
-- SCALAR:
SELECT COUNT(*) FROM (
    SELECT AVG(Price) AS AvgPrice FROM Products  -- Returns: 55.75
) AS ScalarExample;

-- COLUMN:
SELECT * FROM (
    SELECT CategoryID FROM Categories WHERE Active = 1  -- Returns: 1, 2, 3
) AS ColumnExample;

-- TABLE:
SELECT * FROM (
    SELECT ProductID, ProductName, Price FROM Products WHERE Stock > 0
) AS TableExample;


/*
============================================================================
PART 6: Choosing the Right Type
============================================================================
*/

-- Scenario 6.1: Need single value for comparison → SCALAR
SELECT ProductName FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- Scenario 6.2: Need to match against list → COLUMN
SELECT ProductName FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM Categories WHERE Featured = 1);

-- Scenario 6.3: Need multiple columns for complex logic → TABLE/ROW
SELECT * FROM (
    SELECT 
        ProductName,
        Price,
        Stock,
        Price * Stock AS Value,
        CASE WHEN Stock < 10 THEN 'Low' ELSE 'OK' END AS StockStatus
    FROM Products
) Derived
WHERE Value > 100 AND StockStatus = 'Low';

-- Scenario 6.4: Check existence → TABLE with EXISTS
SELECT CustomerName FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);


/*
============================================================================
PART 7: Common Patterns by Type
============================================================================
*/

-- Pattern 7.1: Scalar - Compare to aggregate
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

SELECT ProductName, Price
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

-- Pattern 7.2: Column - Filter by list
SELECT * FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM TopCategories);

SELECT * FROM Customers
WHERE CustomerID NOT IN (SELECT CustomerID FROM VIPCustomers);

-- Pattern 7.3: Table - Derived calculations
SELECT * FROM (
    SELECT 
        CategoryID,
        COUNT(*) AS ProductCount,
        AVG(Price) AS AvgPrice,
        SUM(Stock) AS TotalStock
    FROM Products
    GROUP BY CategoryID
) Stats
WHERE ProductCount > 10;

-- Pattern 7.4: Table - Complex filtering
SELECT * FROM (
    SELECT 
        o.OrderID,
        o.TotalAmount,
        DATEDIFF(DAY, o.OrderDate, GETDATE()) AS DaysSince,
        CASE WHEN o.TotalAmount > 500 THEN 'High' ELSE 'Normal' END AS OrderTier
    FROM Orders o
) OrderAnalysis
WHERE DaysSince < 30 AND OrderTier = 'High';


/*
============================================================================
PART 8: Type Conversion and Casting
============================================================================
*/

-- Example 8.1: Ensuring scalar result with TOP 1
-- Instead of:
-- WHERE CategoryID = (SELECT CategoryID FROM Categories)  -- Might return multiple

-- Use:
WHERE CategoryID = (SELECT TOP 1 CategoryID FROM Categories ORDER BY CategoryID);

-- Example 8.2: Converting column to scalar with aggregate
-- Instead of:
-- WHERE Price > (SELECT Price FROM Products)  -- Multiple values

-- Use:
WHERE Price > (SELECT MAX(Price) FROM Products);  -- Single value

-- Example 8.3: Making table subquery work with IN
SELECT ProductName
FROM Products
WHERE (CategoryID, SupplierID) IN (
    SELECT CategoryID, SupplierID
    FROM PreferredCombinations
);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Write a scalar subquery to find products above average price
2. Write a column subquery to find products in active categories
3. Write a table subquery to get category statistics
4. Use row subquery to find product with max price and min stock
5. Create derived table for products with calculated inventory value

Solutions below ↓
*/

-- Solution 1: Scalar
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
ORDER BY Price DESC;

-- Solution 2: Column
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE Active = 1
);

-- Solution 3: Table
SELECT *
FROM (
    SELECT 
        CategoryID,
        COUNT(*) AS Products,
        AVG(Price) AS AvgPrice,
        MIN(Price) AS MinPrice,
        MAX(Price) AS MaxPrice
    FROM Products
    GROUP BY CategoryID
) CategoryStats
WHERE Products > 5
ORDER BY AvgPrice DESC;

-- Solution 4: Row
SELECT ProductName, Price, Stock
FROM Products
WHERE (Price, Stock) = (
    SELECT MAX(Price), MIN(Stock)
    FROM Products
);

-- Solution 5: Derived table
SELECT ProductName, Price, Stock, InventoryValue
FROM (
    SELECT 
        ProductName,
        Price,
        Stock,
        Price * Stock AS InventoryValue
    FROM Products
) ProductValues
WHERE InventoryValue > 500
ORDER BY InventoryValue DESC;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SCALAR SUBQUERIES:
  • Return: 1 row, 1 column
  • Used with: =, >, <, >=, <=, <>
  • Common: Aggregate comparisons (AVG, MAX, MIN)

✓ ROW SUBQUERIES:
  • Return: 1 row, multiple columns
  • Used with: Tuple comparison (col1, col2) = (val1, val2)
  • Less common in SQL Server

✓ COLUMN SUBQUERIES:
  • Return: Multiple rows, 1 column
  • Used with: IN, NOT IN, ANY, ALL
  • Common: Filtering by lists

✓ TABLE SUBQUERIES:
  • Return: Multiple rows and columns
  • Used in: FROM clause, EXISTS, INSERT
  • Common: Derived tables, complex logic

✓ CHOOSING TYPE:
  • Single value needed → Scalar
  • List for filtering → Column
  • Complex calculations → Table
  • Existence check → Table with EXISTS

✓ OPERATORS BY TYPE:
  • Scalar: =, <>, >, <, >=, <=
  • Column: IN, NOT IN, ANY, ALL
  • Table: FROM, EXISTS, INSERT SELECT

✓ COMMON MISTAKES:
  • Using = when subquery returns multiple values
  • Forgetting TOP 1 when ensuring scalar
  • Not considering NULL in NOT IN

============================================================================
NEXT: Lesson 09.03 - Noncorrelated Subqueries
Master subqueries that execute independently of the outer query.
============================================================================
*/
