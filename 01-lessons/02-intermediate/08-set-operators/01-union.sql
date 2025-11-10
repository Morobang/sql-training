-- ========================================
-- UNION: Combine Results (Remove Duplicates)
-- ========================================

USE TechStore;

-- Combine customer cities and employee cities
SELECT City FROM Customers
UNION
SELECT Location AS City FROM Departments;

-- All payment methods and categories in one list
SELECT PaymentMethod AS Item, 'Payment' AS Type FROM Sales
UNION
SELECT Category AS Item, 'Category' AS Type FROM Products
ORDER BY Type, Item;

-- UNION removes duplicates automatically
SELECT City FROM Customers
UNION
SELECT City FROM Customers;  -- Duplicates removed
