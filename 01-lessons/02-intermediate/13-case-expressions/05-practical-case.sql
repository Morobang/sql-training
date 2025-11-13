-- ========================================
-- Practical CASE Examples
-- ========================================

USE TechStore;

-- 1. Sales report with performance labels
SELECT 
    SaleID,
    TotalAmount,
    CASE 
        WHEN TotalAmount >= 500 THEN 'Excellent Sale'
        WHEN TotalAmount >= 200 THEN 'Good Sale'
        WHEN TotalAmount >= 100 THEN 'Average Sale'
        ELSE 'Small Sale'
    END AS Performance,
    CASE 
        WHEN TotalAmount >= 200 THEN TotalAmount * 0.10
        ELSE 0
    END AS Commission
FROM Sales;

-- 2. Product recommendation
SELECT 
    ProductName,
    Price,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'Cannot Order - Out of Stock'
        WHEN StockQuantity < 10 THEN 'Order Soon - Low Stock'
        WHEN Price < 50 AND StockQuantity > 50 THEN 'Great Deal!'
        ELSE 'Available'
    END AS Recommendation
FROM Products
WHERE IsActive = 1;

-- 3. Conditional aggregation (pivot-like)
SELECT 
    Category,
    SUM(CASE WHEN Price < 100 THEN 1 ELSE 0 END) AS Under100,
    SUM(CASE WHEN Price BETWEEN 100 AND 200 THEN 1 ELSE 0 END) AS Between100And200,
    SUM(CASE WHEN Price > 200 THEN 1 ELSE 0 END) AS Over200
FROM Products
GROUP BY Category;
