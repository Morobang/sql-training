-- ========================================
-- CROSS JOIN: Cartesian Product
-- ========================================

USE TechStore;

-- Every product paired with every customer
-- (Usually not what you want, but useful for specific scenarios)
SELECT 
    c.CustomerName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p
ORDER BY c.CustomerName, p.ProductName;

-- Practical use: Generate all possible combinations
-- Example: Every category with every payment method
SELECT DISTINCT
    p.Category,
    s.PaymentMethod
FROM Products p
CROSS JOIN Sales s
ORDER BY p.Category, s.PaymentMethod;

-- ⚠️ Warning: CROSS JOIN creates rows = (Table1 rows × Table2 rows)
-- 5 customers × 10 products = 50 rows!
