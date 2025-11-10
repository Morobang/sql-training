-- ========================================
-- UNION ALL: Combine Results (Keep Duplicates)
-- ========================================

USE TechStore;

-- Keep all cities even if duplicated
SELECT City FROM Customers
UNION ALL
SELECT Location AS City FROM Departments;

-- Count total entries including duplicates
SELECT City, COUNT(*) AS Count
FROM (
    SELECT City FROM Customers
    UNION ALL
    SELECT Location AS City FROM Departments
) AS AllCities
GROUP BY City;

-- UNION vs UNION ALL:
-- UNION: Slower (removes duplicates), unique results
-- UNION ALL: Faster (keeps duplicates), all results
