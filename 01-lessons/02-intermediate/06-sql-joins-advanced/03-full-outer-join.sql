-- ========================================
-- FULL OUTER JOIN: All Records from Both Tables
-- ========================================

USE TechStore;

-- All customers and all sales (even unmatched)
SELECT 
    c.CustomerName,
    c.State,
    s.SaleID,
    s.TotalAmount,
    s.SaleDate
FROM Customers c
FULL OUTER JOIN Sales s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerName;

-- Find orphaned records (customers with no sales OR sales with no customer)
SELECT 
    c.CustomerName,
    s.SaleID,
    CASE 
        WHEN c.CustomerID IS NULL THEN 'Sale with no customer'
        WHEN s.SaleID IS NULL THEN 'Customer with no sales'
        ELSE 'Matched'
    END AS Status
FROM Customers c
FULL OUTER JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.CustomerID IS NULL OR s.SaleID IS NULL;
