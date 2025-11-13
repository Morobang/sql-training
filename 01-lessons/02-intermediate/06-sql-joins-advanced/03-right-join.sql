-- ========================================
-- RIGHT JOIN: All Records from Right Table
-- ========================================

USE TechStore;

-- RIGHT JOIN (less common, usually LEFT JOIN is preferred)
SELECT 
    c.CustomerName,
    s.SaleID,
    s.TotalAmount
FROM Sales s
RIGHT JOIN Customers c ON s.CustomerID = c.CustomerID;

-- This RIGHT JOIN is equivalent to this LEFT JOIN:
SELECT 
    c.CustomerName,
    s.SaleID,
    s.TotalAmount
FROM Customers c
LEFT JOIN Sales s ON s.CustomerID = c.CustomerID;

-- 💡 Tip: Most developers prefer LEFT JOIN for readability
-- RIGHT JOIN can always be rewritten as LEFT JOIN by swapping table order
