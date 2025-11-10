-- ========================================
-- Basic DELETE: Remove a Single Row
-- ========================================

USE TechStore;

-- Before: See all customers
SELECT * FROM Customers;

-- Delete customer 5 (James Martinez)
DELETE FROM Customers
WHERE CustomerID = 5;

-- After: Verify customer 5 is gone
SELECT * FROM Customers;
