-- ============================================
-- Lesson 7.3: SELECT with Column Aliases
-- ============================================

USE TechStore;

-- Rename columns in the output
SELECT 
    ProductName AS Product,
    Price AS Cost
FROM Products;

-- ============================================
-- AS gives columns a different name in results
-- The actual table column names don't change
-- ============================================
