-- ========================================
-- CASE in SELECT, WHERE, ORDER BY
-- ========================================

USE TechStore;

-- CASE in SELECT (already seen above)
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS PriceLabel
FROM Products;

-- CASE in WHERE clause
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE 
    CASE 
        WHEN Category = 'Peripherals' THEN StockQuantity
        ELSE 0
    END > 30;

-- CASE in ORDER BY
SELECT 
    ProductName,
    Category,
    Price
FROM Products
ORDER BY 
    CASE Category
        WHEN 'Peripherals' THEN 1
        WHEN 'Storage' THEN 2
        WHEN 'Audio' THEN 3
        ELSE 4
    END,
    Price;

-- CASE in aggregate functions
SELECT 
    Category,
    COUNT(*) AS TotalProducts,
    COUNT(CASE WHEN Price > 100 THEN 1 END) AS ExpensiveProducts,
    COUNT(CASE WHEN Price <= 100 THEN 1 END) AS AffordableProducts
FROM Products
GROUP BY Category;
