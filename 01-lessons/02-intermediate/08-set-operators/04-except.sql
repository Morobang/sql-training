-- ========================================
-- EXCEPT: Find Differences
-- ========================================

USE TechStore;

-- Find customer cities that don't have departments
SELECT City FROM Customers
EXCEPT
SELECT Location AS City FROM Departments;

-- Find department locations that don't have customers
SELECT Location AS City FROM Departments
EXCEPT
SELECT City FROM Customers;

-- Note: Order matters!
-- A EXCEPT B = rows in A but not in B
-- B EXCEPT A = rows in B but not in A
