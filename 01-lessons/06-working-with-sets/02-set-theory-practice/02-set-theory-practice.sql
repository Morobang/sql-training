-- =============================================
-- Lesson 02: Set Theory Practice
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Hands-on exercises with set theory concepts
-- Estimated Time: 20 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Exercise 1: Identify Sets
-- =============================================

-- Set A: All products
SELECT ProductID, ProductName FROM Products;

-- Set B: All categories
SELECT CategoryID, CategoryName FROM Categories;

-- Set C: Products in Electronics (CategoryID = 1)
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 1;

-- Question: Is C a subset of A? (Yes - all products in C are in A)

-- =============================================
-- Exercise 2: Calculate Cardinality
-- =============================================

-- Cardinality of Products
SELECT COUNT(*) AS ProductCount FROM Products;

-- Cardinality of Categories
SELECT COUNT(*) AS CategoryCount FROM Categories;

-- Cardinality of Customers
SELECT COUNT(*) AS CustomerCount FROM Customers;

-- Cardinality of Orders
SELECT COUNT(*) AS OrderCount FROM Orders;

-- Cardinality of distinct CategoryIDs in Products
SELECT COUNT(DISTINCT CategoryID) AS DistinctCategories
FROM Products;

-- =============================================
-- Exercise 3: Empty Sets
-- =============================================

-- Empty set: Products with negative price
SELECT * FROM Products WHERE Price < 0;

-- Empty set: Orders before year 2000
SELECT * FROM Orders WHERE YEAR(OrderDate) < 2000;

-- Check if set is empty
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM Products WHERE Price < 0)
    THEN 'Set is NOT empty'
    ELSE 'Set is EMPTY'
END AS SetStatus;

-- =============================================
-- Exercise 4: Set Membership
-- =============================================

-- Is ProductID 1 in the Products set?
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM Products WHERE ProductID = 1)
    THEN 'Product 1 EXISTS'
    ELSE 'Product 1 DOES NOT EXIST'
END;

-- Is 'Electronics' in the Categories set?
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM Categories WHERE CategoryName = 'Electronics')
    THEN 'Electronics category EXISTS'
    ELSE 'Electronics category DOES NOT EXIST'
END;

-- =============================================
-- Exercise 5: Subsets
-- =============================================

-- Universal set: All customers
SELECT CustomerID, FirstName, LastName FROM Customers;

-- Subset 1: Customers with 'gmail.com' email
SELECT CustomerID, FirstName, LastName 
FROM Customers 
WHERE Email LIKE '%@gmail.com';

-- Subset 2: Customers whose name starts with 'J'
SELECT CustomerID, FirstName, LastName 
FROM Customers 
WHERE FirstName LIKE 'J%';

-- Proper subset check (Is subset1 smaller than universal set?)
SELECT 
    (SELECT COUNT(*) FROM Customers WHERE Email LIKE '%@gmail.com') AS SubsetSize,
    (SELECT COUNT(*) FROM Customers) AS UniversalSetSize;

-- =============================================
-- Exercise 6: Complement
-- =============================================

-- Set A: Products in Electronics
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 1;

-- Complement of A: Products NOT in Electronics
SELECT ProductID, ProductName 
FROM Products 
WHERE CategoryID <> 1 OR CategoryID IS NULL;

-- Verify: A + Complement(A) = Universal set
SELECT 
    (SELECT COUNT(*) FROM Products WHERE CategoryID = 1) +
    (SELECT COUNT(*) FROM Products WHERE CategoryID <> 1 OR CategoryID IS NULL) AS Total,
    (SELECT COUNT(*) FROM Products) AS UniversalSet;
-- Should be equal!

-- =============================================
-- Exercise 7: Union Preview
-- =============================================

-- Set A: Customers who ordered in January 2025
SELECT DISTINCT CustomerID 
FROM Orders 
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01';

-- Set B: Customers who ordered in February 2025
SELECT DISTINCT CustomerID 
FROM Orders 
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01';

-- Manual union (using OR)
SELECT DISTINCT CustomerID 
FROM Orders 
WHERE (OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01')
   OR (OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01');

-- =============================================
-- Exercise 8: Intersection Preview
-- =============================================

-- Set A: Products with Price > 100
SELECT ProductID FROM Products WHERE Price > 100;

-- Set B: Products in CategoryID = 1
SELECT ProductID FROM Products WHERE CategoryID = 1;

-- Intersection (manual using AND)
SELECT ProductID 
FROM Products 
WHERE Price > 100 AND CategoryID = 1;

-- =============================================
-- Exercise 9: Difference Preview
-- =============================================

-- Set A: All products
SELECT ProductID FROM Products;

-- Set B: Products that have been ordered
SELECT DISTINCT ProductID FROM OrderDetails;

-- Difference (A - B): Products never ordered
SELECT ProductID 
FROM Products p
WHERE NOT EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID);

-- =============================================
-- Exercise 10: Venn Diagram Practice
-- =============================================

-- Define two sets for practice
DECLARE @SetA TABLE (Value INT);
DECLARE @SetB TABLE (Value INT);

INSERT INTO @SetA VALUES (1), (2), (3), (4), (5);
INSERT INTO @SetB VALUES (4), (5), (6), (7), (8);

-- Set A only (A - B)
SELECT Value FROM @SetA
WHERE Value NOT IN (SELECT Value FROM @SetB);
-- Result: 1, 2, 3

-- Set B only (B - A)
SELECT Value FROM @SetB
WHERE Value NOT IN (SELECT Value FROM @SetA);
-- Result: 6, 7, 8

-- Intersection (A ∩ B)
SELECT Value FROM @SetA
WHERE Value IN (SELECT Value FROM @SetB);
-- Result: 4, 5

-- Union (A ∪ B)
SELECT Value FROM @SetA
UNION
SELECT Value FROM @SetB;
-- Result: 1, 2, 3, 4, 5, 6, 7, 8

/*
Visual Venn Diagram:
        A           B
    ┌─────┐     ┌─────┐
    │ 1,2 │ 4,5 │ 6,7 │
    │  3  │     │  8  │
    └─────┘     └─────┘
       ↑    ↑       ↑
    A only Overlap B only
*/

-- =============================================
-- Summary & Answers
-- =============================================
/*
Answers to Lesson 01 Practice Questions:

1. Cardinality of Products: Run SELECT COUNT(*) FROM Products
2. Distinct categories: SELECT COUNT(DISTINCT CategoryID) FROM Products
3. Empty set of customers: SELECT * FROM Customers WHERE 1 = 0
4. Subset Price > 50: SELECT * FROM Products WHERE Price > 50
5. Complement of CategoryID = 1: 
   SELECT * FROM Products WHERE CategoryID <> 1 OR CategoryID IS NULL

Key Takeaways:
├─ Set = Collection of elements (rows in SQL)
├─ Cardinality = COUNT(*)
├─ Subset = filtered results
├─ Complement = NOT condition
├─ Empty set = WHERE 1 = 0
└─ Membership = EXISTS check

NEXT: Lesson 03 - Set Operators Overview
*/
