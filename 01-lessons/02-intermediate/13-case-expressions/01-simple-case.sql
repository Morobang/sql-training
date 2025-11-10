-- ========================================
-- Simple CASE Expression
-- ========================================

USE TechStore;

-- Simple CASE: Compare one column to multiple values
SELECT 
    ProductName,
    Category,
    CASE Category
        WHEN 'Peripherals' THEN 'Input Devices'
        WHEN 'Storage' THEN 'Data Storage'
        WHEN 'Audio' THEN 'Sound Equipment'
        ELSE 'Other'
    END AS CategoryGroup
FROM Products;

-- Categorize by payment method
SELECT 
    SaleID,
    PaymentMethod,
    TotalAmount,
    CASE PaymentMethod
        WHEN 'Credit Card' THEN 'Card Payment'
        WHEN 'Debit Card' THEN 'Card Payment'
        WHEN 'PayPal' THEN 'Online Payment'
        ELSE 'Other Payment'
    END AS PaymentType
FROM Sales;
