/*
============================================================================
Lesson 09.08 - Data Manipulation with Subqueries
============================================================================

Description:
Master using subqueries in INSERT, UPDATE, and DELETE statements to
perform dynamic data manipulation based on query results.

Topics Covered:
• INSERT with subqueries
• UPDATE with subqueries
• DELETE with subqueries
• Subqueries in SET clause
• Best practices and safety

Prerequisites:
• Lessons 09.01-09.07
• Chapter 02 (Data manipulation basics)

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: INSERT with Subqueries
============================================================================
*/

-- Example 1.1: INSERT...SELECT basic pattern
CREATE TABLE #ProductBackup (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    BackupDate DATETIME DEFAULT GETDATE()
);

-- Insert using subquery
INSERT INTO #ProductBackup (ProductID, ProductName, Price)
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 100;

SELECT * FROM #ProductBackup;
DROP TABLE #ProductBackup;

-- Example 1.2: INSERT with calculated values
CREATE TABLE #ProductStats (
    ProductID INT,
    ProductName VARCHAR(100),
    PriceCategory VARCHAR(20),
    AboveAverage BIT
);

INSERT INTO #ProductStats
SELECT 
    ProductID,
    ProductName,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END,
    CASE WHEN Price > (SELECT AVG(Price) FROM Products) THEN 1 ELSE 0 END
FROM Products;

SELECT * FROM #ProductStats;
DROP TABLE #ProductStats;

-- Example 1.3: INSERT with JOIN in subquery
CREATE TABLE #CustomerOrderSummary (
    CustomerID INT,
    CustomerName VARCHAR(100),
    TotalOrders INT,
    TotalSpent DECIMAL(10,2)
);

INSERT INTO #CustomerOrderSummary
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID),
    ISNULL(SUM(o.TotalAmount), 0)
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

SELECT * FROM #CustomerOrderSummary;
DROP TABLE #CustomerOrderSummary;

-- Example 1.4: INSERT with filtering subquery
CREATE TABLE #ActiveCustomers (
    CustomerID INT,
    CustomerName VARCHAR(100),
    LastOrderDate DATE
);

INSERT INTO #ActiveCustomers
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID)
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
);

SELECT * FROM #ActiveCustomers;
DROP TABLE #ActiveCustomers;


/*
============================================================================
PART 2: UPDATE with Subqueries
============================================================================
*/

-- Setup test table
CREATE TABLE #PriceUpdate (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    CategoryID INT
);

INSERT INTO #PriceUpdate
SELECT ProductID, ProductName, Price, CategoryID
FROM Products;

-- Example 2.1: UPDATE with scalar subquery in SET
UPDATE #PriceUpdate
SET Price = (SELECT AVG(Price) FROM Products)
WHERE Price IS NULL;
-- Set NULL prices to overall average

-- Example 2.2: UPDATE with correlated subquery
UPDATE #PriceUpdate
SET Price = (
    SELECT AVG(Price)
    FROM Products p
    WHERE p.CategoryID = #PriceUpdate.CategoryID
)
WHERE Price < (
    SELECT AVG(Price) * 0.5
    FROM Products p
    WHERE p.CategoryID = #PriceUpdate.CategoryID
);
-- Update very low prices to category average

-- Example 2.3: UPDATE with EXISTS
UPDATE #PriceUpdate
SET Price = Price * 1.1
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = #PriceUpdate.ProductID
    GROUP BY od.ProductID
    HAVING SUM(od.Quantity) > 100
);
-- 10% increase for high-volume products

-- Example 2.4: UPDATE from another table
UPDATE #PriceUpdate
SET Price = p.Price * 1.15
FROM #PriceUpdate pu
JOIN Products p ON pu.ProductID = p.ProductID
WHERE p.CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING AVG(Price) > 75
);
-- 15% increase for products in premium categories

SELECT * FROM #PriceUpdate ORDER BY ProductID;
DROP TABLE #PriceUpdate;


/*
============================================================================
PART 3: DELETE with Subqueries
============================================================================
*/

-- Setup test table
CREATE TABLE #OrderCleanup (
    OrderID INT,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
);

INSERT INTO #OrderCleanup
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Orders;

-- Example 3.1: DELETE with simple subquery
DELETE FROM #OrderCleanup
WHERE TotalAmount < (SELECT AVG(TotalAmount) FROM Orders);
-- Delete below-average orders

-- Example 3.2: DELETE with correlated subquery
DELETE FROM #OrderCleanup
WHERE TotalAmount < (
    SELECT AVG(TotalAmount)
    FROM Orders o
    WHERE o.CustomerID = #OrderCleanup.CustomerID
);
-- Delete orders below customer's own average

-- Example 3.3: DELETE with NOT EXISTS
DELETE FROM #OrderCleanup
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.OrderID = #OrderCleanup.OrderID
);
-- Delete orders with no line items

-- Example 3.4: DELETE with IN
DELETE FROM #OrderCleanup
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Customers
    WHERE Country = 'Test'
);
-- Delete test customer orders

-- Example 3.5: DELETE with complex subquery
DELETE FROM #OrderCleanup
WHERE OrderID IN (
    SELECT o.OrderID
    FROM Orders o
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE od.OrderDetailID IS NULL
    AND o.OrderDate < DATEADD(YEAR, -2, GETDATE())
);
-- Delete old empty orders

SELECT COUNT(*) AS RemainingOrders FROM #OrderCleanup;
DROP TABLE #OrderCleanup;


/*
============================================================================
PART 4: Complex UPDATE Scenarios
============================================================================
*/

-- Scenario 4.1: Update based on ranking
CREATE TABLE #ProductRanking (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    PriceRank INT NULL
);

INSERT INTO #ProductRanking
SELECT ProductID, ProductName, Price, NULL
FROM Products;

UPDATE #ProductRanking
SET PriceRank = (
    SELECT COUNT(*) + 1
    FROM Products p
    WHERE p.Price > #ProductRanking.Price
);

SELECT * FROM #ProductRanking ORDER BY PriceRank;
DROP TABLE #ProductRanking;

-- Scenario 4.2: Conditional update with multiple subqueries
CREATE TABLE #ProductUpdate (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    Stock INT,
    Status VARCHAR(20)
);

INSERT INTO #ProductUpdate
SELECT ProductID, ProductName, Price, Stock, NULL
FROM Products;

UPDATE #ProductUpdate
SET Status = CASE
    WHEN Stock = 0 THEN 'Out of Stock'
    WHEN Stock < (SELECT AVG(Stock) FROM Products) THEN 'Low Stock'
    WHEN Price > (SELECT AVG(Price) FROM Products) THEN 'Premium'
    ELSE 'Standard'
END;

SELECT * FROM #ProductUpdate;
DROP TABLE #ProductUpdate;

-- Scenario 4.3: Update from aggregated subquery
CREATE TABLE #CustomerStatus (
    CustomerID INT,
    CustomerName VARCHAR(100),
    TotalSpent DECIMAL(10,2) NULL,
    OrderCount INT NULL,
    CustomerTier VARCHAR(20) NULL
);

INSERT INTO #CustomerStatus
SELECT CustomerID, CustomerName, NULL, NULL, NULL
FROM Customers;

-- First, populate aggregates
UPDATE #CustomerStatus
SET 
    TotalSpent = ISNULL((SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = cs.CustomerID), 0),
    OrderCount = (SELECT COUNT(*) FROM Orders WHERE CustomerID = cs.CustomerID)
FROM #CustomerStatus cs;

-- Then, set tier based on those values
UPDATE #CustomerStatus
SET CustomerTier = CASE
    WHEN TotalSpent >= 10000 THEN 'VIP'
    WHEN TotalSpent >= 5000 THEN 'Gold'
    WHEN TotalSpent >= 1000 THEN 'Silver'
    WHEN OrderCount > 0 THEN 'Bronze'
    ELSE 'New'
END;

SELECT * FROM #CustomerStatus ORDER BY TotalSpent DESC;
DROP TABLE #CustomerStatus;


/*
============================================================================
PART 5: Safety and Best Practices
============================================================================
*/

-- Safety 5.1: ⚠️ Always test with SELECT first!
-- ❌ DON'T immediately DELETE:
-- DELETE FROM Products WHERE ...

-- ✅ Test with SELECT first:
SELECT * FROM Products
WHERE Price < (SELECT AVG(Price) FROM Products);
-- Verify results, THEN:
-- DELETE FROM Products WHERE Price < (SELECT AVG(Price) FROM Products);

-- Safety 5.2: ✅ Use transactions for safety
BEGIN TRANSACTION;

DELETE FROM Orders
WHERE CustomerID IN (
    SELECT CustomerID FROM Customers WHERE Test = 1
);

-- Check results
SELECT COUNT(*) FROM Orders;

-- If good:
COMMIT;
-- If bad:
-- ROLLBACK;

-- Safety 5.3: ✅ Use WHERE EXISTS instead of WHERE IN when possible
-- Safer with NULL values
DELETE FROM Products
WHERE EXISTS (
    SELECT 1 FROM DiscontinuedProducts WHERE ProductID = Products.ProductID
);

-- Safety 5.4: ⚠️ Watch for unintended cascades
-- If you have foreign keys, deletes may cascade
-- Check dependencies first:
SELECT 
    COUNT(*) AS OrdersToDelete,
    COUNT(DISTINCT od.OrderDetailID) AS DetailsToDelete
FROM Orders o
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.CustomerID IN (SELECT CustomerID FROM CustomersToDelete);


/*
============================================================================
PART 6: Performance Optimization
============================================================================
*/

-- Optimization 6.1: ✅ Batch large operations
DECLARE @BatchSize INT = 1000;
WHILE 1 = 1
BEGIN
    DELETE TOP (@BatchSize) FROM Orders
    WHERE OrderDate < '2020-01-01';
    
    IF @@ROWCOUNT < @BatchSize BREAK;
END;

-- Optimization 6.2: ✅ Use set-based instead of cursor/loop
-- ❌ Slow row-by-row:
-- DECLARE cursor...
-- UPDATE one row at a time

-- ✅ Fast set-based:
UPDATE Products
SET Price = Price * 1.1
WHERE CategoryID IN (SELECT CategoryID FROM PremiumCategories);

-- Optimization 6.3: ✅ Index columns used in subqueries
-- CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
-- CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);

-- Optimization 6.4: ⚠️ Avoid correlated subqueries in SET when possible
-- Slow:
UPDATE Products
SET Price = (
    SELECT AVG(od.UnitPrice)
    FROM OrderDetails od
    WHERE od.ProductID = Products.ProductID
);

-- Faster:
UPDATE p
SET p.Price = avgPrice.AvgPrice
FROM Products p
JOIN (
    SELECT ProductID, AVG(UnitPrice) AS AvgPrice
    FROM OrderDetails
    GROUP BY ProductID
) avgPrice ON p.ProductID = avgPrice.ProductID;


/*
============================================================================
PART 7: Real-World Examples
============================================================================
*/

-- Example 7.1: Archive old records
CREATE TABLE #OrderArchive (
    OrderID INT,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2),
    ArchivedDate DATETIME
);

-- Copy to archive
INSERT INTO #OrderArchive
SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount,
    GETDATE()
FROM Orders
WHERE OrderDate < DATEADD(YEAR, -2, GETDATE());

-- Delete from main table (would do this in production)
-- DELETE FROM Orders WHERE OrderID IN (SELECT OrderID FROM #OrderArchive);

DROP TABLE #OrderArchive;

-- Example 7.2: Update inventory based on sales
UPDATE Products
SET Stock = Stock - ISNULL((
    SELECT SUM(od.Quantity)
    FROM OrderDetails od
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE od.ProductID = Products.ProductID
    AND o.OrderDate >= CAST(GETDATE() AS DATE)
), 0)
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE od.ProductID = Products.ProductID
    AND o.OrderDate >= CAST(GETDATE() AS DATE)
);

-- Example 7.3: Clean up orphaned records
DELETE FROM OrderDetails
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.OrderID = OrderDetails.OrderID
);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. INSERT products with above-average prices into a backup table
2. UPDATE products to category average if below 50% of category average
3. DELETE orders from customers who haven't ordered in 2 years
4. INSERT customer summary with total orders and spending
5. UPDATE product status based on stock and sales

Solutions below ↓
*/

-- Solution 1:
CREATE TABLE #ExpensiveProducts (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);

INSERT INTO #ExpensiveProducts
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

DROP TABLE #ExpensiveProducts;

-- Solution 2:
-- (Test table for safety)
CREATE TABLE #PriceUpdate2 (ProductID INT, Price DECIMAL(10,2), CategoryID INT);
INSERT INTO #PriceUpdate2 SELECT ProductID, Price, CategoryID FROM Products;

UPDATE #PriceUpdate2
SET Price = (
    SELECT AVG(Price)
    FROM Products p
    WHERE p.CategoryID = #PriceUpdate2.CategoryID
)
WHERE Price < (
    SELECT AVG(Price) * 0.5
    FROM Products p
    WHERE p.CategoryID = #PriceUpdate2.CategoryID
);

DROP TABLE #PriceUpdate2;

-- Solution 3:
-- (Test table for safety)
CREATE TABLE #OrderCleanup2 (OrderID INT, CustomerID INT, OrderDate DATE);
INSERT INTO #OrderCleanup2 SELECT OrderID, CustomerID, OrderDate FROM Orders;

DELETE FROM #OrderCleanup2
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Orders
    GROUP BY CustomerID
    HAVING MAX(OrderDate) < DATEADD(YEAR, -2, GETDATE())
);

DROP TABLE #OrderCleanup2;

-- Solution 4:
CREATE TABLE #CustomerSummary (
    CustomerID INT,
    CustomerName VARCHAR(100),
    TotalOrders INT,
    TotalSpent DECIMAL(10,2)
);

INSERT INTO #CustomerSummary
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID),
    ISNULL((SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID), 0)
FROM Customers c;

DROP TABLE #CustomerSummary;

-- Solution 5:
CREATE TABLE #ProductStatus (ProductID INT, Status VARCHAR(20));
INSERT INTO #ProductStatus SELECT ProductID, NULL FROM Products;

UPDATE #ProductStatus
SET Status = CASE
    WHEN NOT EXISTS (SELECT 1 FROM OrderDetails WHERE ProductID = ps.ProductID) 
         THEN 'Never Sold'
    WHEN (SELECT Stock FROM Products WHERE ProductID = ps.ProductID) = 0 
         THEN 'Out of Stock'
    WHEN (SELECT Stock FROM Products WHERE ProductID = ps.ProductID) < 10 
         THEN 'Low Stock'
    ELSE 'Available'
END
FROM #ProductStatus ps;

DROP TABLE #ProductStatus;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ INSERT WITH SUBQUERIES:
  • INSERT...SELECT pattern
  • Can include JOINs and WHERE
  • Calculated columns allowed
  • Bulk data copying

✓ UPDATE WITH SUBQUERIES:
  • Subqueries in SET clause
  • Subqueries in WHERE clause
  • Correlated for row-specific updates
  • FROM clause for joins

✓ DELETE WITH SUBQUERIES:
  • Filter with WHERE + subquery
  • EXISTS for existence checks
  • IN for list matching
  • NOT EXISTS for gaps

✓ SAFETY PRACTICES:
  • Test with SELECT first!
  • Use transactions
  • Check row counts
  • Verify with small batches
  • Backup before large operations

✓ PERFORMANCE:
  • Batch large operations
  • Use set-based, not loops
  • Index subquery columns
  • Join often faster than correlated subquery

✓ COMMON PATTERNS:
  • Archive old data
  • Bulk updates from calculations
  • Clean up orphaned records
  • Update based on aggregates
  • Conditional operations

✓ BEST PRACTICES:
  • Always test first
  • Use transactions
  • Consider performance
  • Document complex logic
  • Handle NULL appropriately

============================================================================
NEXT: Lesson 09.09 - When to Use Subqueries
Learn to choose between subqueries, JOINs, and other approaches.
============================================================================
*/
