-- ========================================
-- SUM: Total of Numeric Values
-- ========================================

USE TechStore;

-- Total revenue from all sales
SELECT SUM(TotalAmount) AS TotalRevenue
FROM Sales;

-- Total stock quantity across all products
SELECT SUM(StockQuantity) AS TotalInventory
FROM Products;

-- Sum with WHERE filter
SELECT SUM(TotalAmount) AS PeripheralsRevenue
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE p.Category = 'Peripherals';

-- Sum by group
SELECT 
    PaymentMethod,
    SUM(TotalAmount) AS TotalByPaymentMethod
FROM Sales
GROUP BY PaymentMethod;
