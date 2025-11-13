-- ========================================
-- Searched CASE Expression
-- ========================================

USE TechStore;

-- Searched CASE: Evaluate multiple conditions
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price >= 50 AND Price < 150 THEN 'Mid-Range'
        WHEN Price >= 150 THEN 'Premium'
        ELSE 'Unknown'
    END AS PriceCategory
FROM Products;

-- Inventory status
SELECT 
    ProductName,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'Out of Stock'
        WHEN StockQuantity < 20 THEN 'Low Stock'
        WHEN StockQuantity >= 20 AND StockQuantity < 60 THEN 'In Stock'
        ELSE 'High Stock'
    END AS InventoryStatus
FROM Products;

-- Customer tier
SELECT 
    CustomerName,
    TotalPurchases,
    CASE 
        WHEN TotalPurchases >= 1000 THEN 'VIP'
        WHEN TotalPurchases >= 500 THEN 'Gold'
        WHEN TotalPurchases >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerTier
FROM Customers;
