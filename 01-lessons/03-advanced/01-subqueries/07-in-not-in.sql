-- ========================================
-- IN and NOT IN with Subqueries
-- ========================================

USE TechStore;

-- 1. Find customers who made purchases
SELECT 
    CustomerName,
    City
FROM Customers
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID
    FROM Sales
);

-- 2. Find customers who have NOT made purchases
SELECT 
    CustomerName,
    JoinDate
FROM Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID
    FROM Sales
    WHERE CustomerID IS NOT NULL  -- Important! NULL breaks NOT IN
);

-- 3. Find products sold in November 2024
SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE ProductID IN (
    SELECT ProductID
    FROM Sales
    WHERE MONTH(SaleDate) = 11
    AND YEAR(SaleDate) = 2024
);

-- 4. Find products NEVER sold
SELECT 
    ProductName,
    Category,
    StockQuantity
FROM Products
WHERE ProductID NOT IN (
    SELECT ProductID
    FROM Sales
    WHERE ProductID IS NOT NULL
);

-- 5. Find customers from states with sales
SELECT 
    CustomerName,
    State
FROM Customers
WHERE State IN (
    SELECT DISTINCT c.State
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
);

-- 6. Find products in top-selling categories
SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE Category IN (
    SELECT TOP 3 p.Category
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.Category
    ORDER BY COUNT(*) DESC
);

-- ⚠️ Warning: NOT IN with NULLs
-- This returns NO rows if subquery contains NULL:
-- SELECT * FROM Products WHERE ProductID NOT IN (SELECT SupplierID FROM Products);

-- ✅ Safe version:
SELECT * FROM Products 
WHERE ProductID NOT IN (
    SELECT SupplierID 
    FROM Products 
    WHERE SupplierID IS NOT NULL
);
