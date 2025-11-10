-- =============================================
-- Lesson 04: UNION Operator
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Combining results from multiple queries using UNION and UNION ALL
-- Estimated Time: 25 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: What is UNION?
-- =============================================
-- UNION combines results from two or more queries
-- Automatically removes DUPLICATE rows

-- Basic UNION example
SELECT ProductName FROM Products WHERE CategoryID = 1
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2;

/*
Visual:
Set A (CategoryID 1):    Set B (CategoryID 2):
┌──────────┐            ┌──────────┐
│ Laptop   │            │ Novel    │
│ Mouse    │            │ Cookbook │
└──────────┘            └──────────┘
        ↓ UNION ↓
┌──────────┐
│ Laptop   │
│ Mouse    │
│ Novel    │
│ Cookbook │
└──────────┘
All unique products from both categories
*/

-- =============================================
-- Part 2: UNION vs UNION ALL
-- =============================================

-- UNION: Removes duplicates (slower)
SELECT ProductName FROM Products WHERE Price > 100
UNION
SELECT ProductName FROM Products WHERE CategoryID = 1;

-- UNION ALL: Keeps duplicates (faster)
SELECT ProductName FROM Products WHERE Price > 100
UNION ALL
SELECT ProductName FROM Products WHERE CategoryID = 1;

-- Example showing the difference
SELECT CategoryID FROM Products WHERE CategoryID = 1
UNION
SELECT CategoryID FROM Products WHERE CategoryID = 1;
-- Result: One row (1) - duplicates removed

SELECT CategoryID FROM Products WHERE CategoryID = 1
UNION ALL
SELECT CategoryID FROM Products WHERE CategoryID = 1;
-- Result: Multiple rows (all 1s) - duplicates kept

-- =============================================
-- Part 3: UNION Requirements
-- =============================================

-- ✅ CORRECT: Same number of columns
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 2;

-- ❌ ERROR: Different number of columns
/*
SELECT ProductID, ProductName, Price FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 2;
-- ERROR: Column count doesn't match
*/

-- ✅ CORRECT: Compatible data types
SELECT ProductID, ProductName FROM Products
UNION
SELECT CategoryID, CategoryName FROM Categories;

-- Column names come from first query
SELECT ProductID AS ID, ProductName AS Name FROM Products
UNION
SELECT CategoryID, CategoryName FROM Categories;
-- Result columns are named: ID, Name

-- =============================================
-- Part 4: Combining Different Tables
-- =============================================

-- Combine customer names and product names into one list
SELECT FirstName + ' ' + LastName AS Name, 'Customer' AS Type
FROM Customers
UNION
SELECT ProductName, 'Product' AS Type
FROM Products
ORDER BY Type, Name;

-- Combine emails from different sources
SELECT Email, 'Customer' AS Source FROM Customers
UNION
SELECT Email, 'Supplier' AS Source FROM Suppliers
WHERE Suppliers.Email IS NOT NULL;

-- =============================================
-- Part 5: UNION with Literals
-- =============================================

-- Add literal values to distinguish sources
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    'Completed' AS Status
FROM Orders
WHERE OrderDate < '2025-01-01'
UNION ALL
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    'Recent' AS Status
FROM Orders
WHERE OrderDate >= '2025-01-01';

-- Create a master list with type indicators
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    Price AS Value,
    'Product' AS ItemType
FROM Products
UNION ALL
SELECT 
    CustomerID,
    FirstName + ' ' + LastName,
    NULL,  -- Customers don't have price
    'Customer'
FROM Customers;

-- =============================================
-- Part 6: UNION ALL for Performance
-- =============================================

-- When you KNOW there are no duplicates, use UNION ALL
-- Example: Monthly data that doesn't overlap

SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
UNION ALL  -- Faster than UNION
SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01'
UNION ALL
SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE OrderDate >= '2025-03-01' AND OrderDate < '2025-04-01';

-- =============================================
-- Part 7: Handling NULLs in UNION
-- =============================================

-- Add NULL for missing columns
SELECT 
    ProductID,
    ProductName,
    Price,
    NULL AS Email  -- Products don't have emails
FROM Products
UNION
SELECT 
    CustomerID,
    FirstName + ' ' + LastName,
    NULL AS Price,  -- Customers don't have prices
    Email
FROM Customers;

-- Use placeholders for missing data
SELECT 
    OrderID AS ID,
    'Order #' + CAST(OrderID AS VARCHAR(10)) AS Description,
    TotalAmount
FROM Orders
UNION
SELECT 
    ProductID,
    ProductName,
    Price
FROM Products;

-- =============================================
-- Part 8: UNION with Filtering
-- =============================================

-- Filter BEFORE union (more efficient)
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1 AND Price > 50  -- Filter here
UNION
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 2 AND Price > 50  -- And here
ORDER BY Price DESC;

-- Filter AFTER union (less efficient)
SELECT ProductName, Price
FROM (
    SELECT ProductName, Price FROM Products WHERE CategoryID = 1
    UNION
    SELECT ProductName, Price FROM Products WHERE CategoryID = 2
) AS CombinedProducts
WHERE Price > 50
ORDER BY Price DESC;

-- =============================================
-- Part 9: UNION with Aggregates
-- =============================================

-- Combine summary data from different periods
SELECT 
    'January 2025' AS Period,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
UNION ALL
SELECT 
    'February 2025',
    COUNT(*),
    SUM(TotalAmount)
FROM Orders
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01'
UNION ALL
SELECT 
    'TOTAL',
    COUNT(*),
    SUM(TotalAmount)
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-03-01'
ORDER BY Period;

-- Category-wise product counts
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
UNION ALL
SELECT 
    'TOTAL',
    COUNT(*)
FROM Products;

-- =============================================
-- Part 10: UNION with Three or More Queries
-- =============================================

-- Combine data from multiple sources
SELECT CustomerID AS ID, FirstName AS Name, 'Customer' AS Type
FROM Customers
WHERE CustomerID <= 3
UNION
SELECT ProductID, ProductName, 'Product'
FROM Products
WHERE ProductID <= 3
UNION
SELECT CategoryID, CategoryName, 'Category'
FROM Categories
ORDER BY Type, Name;

-- Quarterly sales report
SELECT 'Q1' AS Quarter, SUM(TotalAmount) AS Revenue
FROM Orders
WHERE MONTH(OrderDate) IN (1,2,3)
UNION ALL
SELECT 'Q2', SUM(TotalAmount)
FROM Orders
WHERE MONTH(OrderDate) IN (4,5,6)
UNION ALL
SELECT 'Q3', SUM(TotalAmount)
FROM Orders
WHERE MONTH(OrderDate) IN (7,8,9)
UNION ALL
SELECT 'Q4', SUM(TotalAmount)
FROM Orders
WHERE MONTH(OrderDate) IN (10,11,12);

-- =============================================
-- Part 11: ORDER BY with UNION
-- =============================================

-- ❌ WRONG: ORDER BY in individual queries
/*
SELECT ProductName FROM Products WHERE CategoryID = 1 ORDER BY ProductName
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2 ORDER BY ProductName;
-- ERROR: ORDER BY not allowed in individual queries
*/

-- ✅ CORRECT: ORDER BY at the end only
SELECT ProductName FROM Products WHERE CategoryID = 1
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2
ORDER BY ProductName;

-- Sort by column position (not column name)
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    Price
FROM Products
WHERE CategoryID = 1
UNION
SELECT 
    CategoryID,
    CategoryName,
    NULL
FROM Categories
ORDER BY 2;  -- Sort by second column (Name)

-- =============================================
-- Part 12: Real-World Examples
-- =============================================

-- Example 1: Create a contact list
SELECT 
    FirstName + ' ' + LastName AS ContactName,
    Email,
    'Customer' AS ContactType,
    NULL AS CompanyName
FROM Customers
WHERE Email IS NOT NULL
UNION
SELECT 
    ContactName,
    Email,
    'Supplier',
    CompanyName
FROM Suppliers
WHERE Email IS NOT NULL
ORDER BY ContactType, ContactName;

-- Example 2: Audit trail - combine multiple action logs
SELECT 
    OrderID AS RecordID,
    'Order Created' AS ActionType,
    OrderDate AS ActionDate,
    CustomerID AS RelatedID
FROM Orders
UNION ALL
SELECT 
    OrderDetailID,
    'Item Added',
    (SELECT OrderDate FROM Orders o WHERE o.OrderID = od.OrderID),
    ProductID
FROM OrderDetails od
ORDER BY ActionDate DESC;

-- Example 3: Year-over-year comparison
SELECT 
    '2024' AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS Revenue
FROM OrderHistory2024
GROUP BY MONTH(OrderDate)
UNION ALL
SELECT 
    '2025',
    MONTH(OrderDate),
    SUM(TotalAmount)
FROM Orders
GROUP BY MONTH(OrderDate)
ORDER BY Month, Year;

-- =============================================
-- Part 13: Performance Comparison
-- =============================================

-- Measure UNION performance
SET STATISTICS TIME ON;

-- UNION (with duplicate removal)
SELECT ProductName FROM Products
UNION
SELECT ProductName FROM Products;

-- UNION ALL (no duplicate removal)
SELECT ProductName FROM Products
UNION ALL
SELECT ProductName FROM Products;

SET STATISTICS TIME OFF;

-- UNION ALL is typically 2-3x faster!

-- =============================================
-- Summary
-- =============================================
/*
UNION vs UNION ALL:

┌──────────────┬─────────────────┬─────────────────┬────────────┐
│  Operator    │   Duplicates    │   Performance   │  Use When  │
├──────────────┼─────────────────┼─────────────────┼────────────┤
│ UNION        │  Removed        │  Slower (sorts) │ Need unique│
│ UNION ALL    │  Kept           │  Faster         │ No dups OR │
│              │                 │                 │ want all   │
└──────────────┴─────────────────┴─────────────────┴────────────┘

REQUIREMENTS:
✅ Same number of columns
✅ Compatible data types (column by column)
✅ ORDER BY only at the end
✅ Column names from first query

BEST PRACTICES:
├─ Use UNION ALL when possible (faster)
├─ Filter before UNION (not after)
├─ Use meaningful column aliases
├─ Add type/source indicators
└─ Test with COUNT(*) first

NEXT: Lesson 05 - INTERSECT Operator
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Combine all Products and Categories into one list with a Type column
2. Create a report of high-value items (Products > $100 OR Orders > $500)
3. Build a quarterly revenue report using UNION ALL
4. Find all emails from Customers and Suppliers (no duplicates)
5. Compare UNION vs UNION ALL performance on a large dataset

Try these queries before moving to the next lesson!
*/
