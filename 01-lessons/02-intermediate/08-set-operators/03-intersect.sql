-- ========================================
-- INTERSECT: Find Common Rows
-- ========================================

USE TechStore;

-- Find cities that have both customers and departments
SELECT City FROM Customers
INTERSECT
SELECT Location AS City FROM Departments;

-- Note: INTERSECT returns only rows that appear in BOTH queries
-- If no common rows, result is empty
