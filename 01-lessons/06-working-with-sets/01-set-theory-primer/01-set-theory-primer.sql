-- =============================================
-- Lesson 01: Set Theory Primer
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Introduction to set theory concepts and how they apply to SQL
-- Estimated Time: 15 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: What is a Set?
-- =============================================
-- A SET is a collection of distinct elements
-- In SQL, a query result is a set of rows

-- Example: Set of all products
SELECT ProductID, ProductName
FROM Products;
/*
This query returns a SET of products
Each row is an element in the set
*/

-- Example: Set of all customers
SELECT CustomerID, FirstName, LastName
FROM Customers;

-- =============================================
-- Part 2: Set Properties
-- =============================================
-- Sets have important properties:
-- 1. Elements are DISTINCT (no duplicates in pure sets)
-- 2. ORDER doesn't matter in mathematical sets
-- 3. Sets can be EMPTY (no elements)

-- DISTINCT removes duplicates
SELECT DISTINCT CategoryID
FROM Products;

-- Same data, different order = same set
SELECT ProductName FROM Products ORDER BY ProductName;
SELECT ProductName FROM Products ORDER BY Price;
-- Different order, but mathematically the same set

-- Empty set example
SELECT ProductID, ProductName
FROM Products
WHERE Price < 0;  -- Returns empty set (no negative prices)

-- =============================================
-- Part 3: Set Membership
-- =============================================
-- An element either IS or IS NOT in a set

-- Check if ProductID 1 exists in Products set
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM Products WHERE ProductID = 1) 
    THEN 'ProductID 1 is IN the set'
    ELSE 'ProductID 1 is NOT IN the set'
END AS MembershipCheck;

-- Check if ProductID 999 exists
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM Products WHERE ProductID = 999) 
    THEN 'ProductID 999 is IN the set'
    ELSE 'ProductID 999 is NOT IN the set'
END AS MembershipCheck;

-- =============================================
-- Part 4: Subset
-- =============================================
-- A SUBSET contains elements that are all in another set

-- All electronics products (subset of all products)
SELECT ProductID, ProductName, CategoryID
FROM Products
WHERE CategoryID = 1;  -- Electronics only (subset)

-- All products (universal set in this context)
SELECT ProductID, ProductName, CategoryID
FROM Products;  -- Complete set

-- =============================================
-- Part 5: Universal Set and Empty Set
-- =============================================

-- Universal set: All products in our database
SELECT ProductID, ProductName
FROM Products;

-- Empty set: No results
SELECT ProductID, ProductName
FROM Products
WHERE 1 = 0;  -- Always false, returns empty set

-- Another empty set example
SELECT ProductID, ProductName
FROM Products
WHERE ProductID IS NULL AND ProductID IS NOT NULL;  -- Impossible condition

-- =============================================
-- Part 6: Cardinality (Size of Set)
-- =============================================
-- CARDINALITY = number of elements in a set

-- Cardinality of Products set
SELECT COUNT(*) AS Cardinality
FROM Products;

-- Cardinality of distinct categories
SELECT COUNT(DISTINCT CategoryID) AS Cardinality
FROM Products;

-- Cardinality of empty set is 0
SELECT COUNT(*) AS Cardinality
FROM Products
WHERE 1 = 0;

-- =============================================
-- Part 7: Venn Diagrams in SQL Context
-- =============================================
/*
Venn Diagram Visualization:

Set A: Products with Price > 100
Set B: Products in CategoryID = 1

    A                    B
  ╭─────╮            ╭─────╮
  │     │            │     │
  │  A  │    A∩B     │  B  │
  │     │  (overlap) │     │
  ╰─────╯            ╰─────╯

Overlap (A ∩ B): Products with Price > 100 AND CategoryID = 1
*/

-- Set A: Products with Price > 100
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Price > 100;

-- Set B: Products in CategoryID = 1
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1;

-- Intersection (A ∩ B): In BOTH sets
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Price > 100 AND CategoryID = 1;

-- =============================================
-- Part 8: Set Operations Preview
-- =============================================
-- Three main set operations in SQL:
-- 1. UNION (A ∪ B) - All elements from A or B
-- 2. INTERSECT (A ∩ B) - Elements in both A and B
-- 3. EXCEPT (A - B) - Elements in A but not in B

-- We'll cover these in detail in upcoming lessons

-- =============================================
-- Part 9: Visualizing Set Relationships
-- =============================================

-- Create two sets for demonstration
-- Set A: Orders from January 2025
SELECT OrderID, CustomerID, OrderDate
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01';

-- Set B: Orders with TotalAmount > 500
SELECT OrderID, CustomerID, TotalAmount
FROM Orders
WHERE TotalAmount > 500;

-- Customers in Set A (ordered in January)
SELECT DISTINCT CustomerID
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01';

-- Customers in Set B (high-value orders)
SELECT DISTINCT CustomerID
FROM Orders
WHERE TotalAmount > 500;

-- Intersection: Customers who ordered in January AND spent > $500
SELECT DISTINCT CustomerID
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
  AND TotalAmount > 500;

-- =============================================
-- Part 10: Set Equality
-- =============================================
-- Two sets are EQUAL if they contain exactly the same elements

-- Set 1: Products with CategoryID = 1
SELECT ProductID 
FROM Products 
WHERE CategoryID = 1
ORDER BY ProductID;

-- Set 2: Products with CategoryName = 'Electronics'
SELECT p.ProductID
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics'
ORDER BY ProductID;

-- These are equal sets (same elements) if CategoryID 1 = 'Electronics'

-- =============================================
-- Part 11: Complement
-- =============================================
-- COMPLEMENT of set A = all elements NOT in A

-- Set A: Products in CategoryID = 1
SELECT ProductID, ProductName, CategoryID
FROM Products
WHERE CategoryID = 1;

-- Complement of A: Products NOT in CategoryID = 1
SELECT ProductID, ProductName, CategoryID
FROM Products
WHERE CategoryID <> 1 OR CategoryID IS NULL;

-- =============================================
-- Part 12: Practical Examples
-- =============================================

-- Example 1: Find customers who have NEVER ordered
-- Universal set: All customers
-- Set A: Customers who have ordered
-- Complement: Customers NOT in Set A

SELECT c.CustomerID, c.FirstName, c.LastName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- Example 2: Products that have been ordered
SELECT DISTINCT p.ProductID, p.ProductName
FROM Products p
WHERE EXISTS (
    SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID
);

-- Example 3: Products that have NEVER been ordered (complement)
SELECT p.ProductID, p.ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID
);

-- =============================================
-- Summary
-- =============================================
/*
KEY CONCEPTS:

1. SET = Collection of distinct elements
   └─ In SQL: Query result is a set of rows

2. SET PROPERTIES:
   ├─ Distinct (no duplicates)
   ├─ Unordered (mathematically)
   └─ Can be empty

3. SET OPERATIONS (Preview):
   ├─ UNION (A ∪ B) - All from A or B
   ├─ INTERSECT (A ∩ B) - In both A and B
   └─ EXCEPT (A - B) - In A but not in B

4. USEFUL CONCEPTS:
   ├─ Subset: All elements in another set
   ├─ Cardinality: Number of elements
   ├─ Complement: Elements NOT in set
   └─ Empty set: Zero elements

5. SQL KEYWORDS:
   ├─ DISTINCT - Remove duplicates
   ├─ EXISTS - Check membership
   ├─ COUNT(*) - Get cardinality
   └─ WHERE - Define set conditions

NEXT: Lesson 02 - Set Theory Practice
*/

-- =============================================
-- Practice Questions
-- =============================================
/*
1. What is the cardinality of the Products table?
2. How many distinct categories exist?
3. Write a query for the empty set of customers
4. Find the subset of products with Price > 50
5. What is the complement of CategoryID = 1?

Answers in next lesson!
*/
