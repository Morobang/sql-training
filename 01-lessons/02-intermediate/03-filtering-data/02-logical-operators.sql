-- ========================================
-- Logical Operators: AND, OR, NOT
-- ========================================

USE TechStore;

-- AND: Both conditions must be true
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Peripherals' AND Price < 100;

-- OR: Either condition can be true
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Peripherals' OR Category = 'Storage';

-- NOT: Negates a condition
SELECT ProductName, Category
FROM Products
WHERE NOT Category = 'Accessories';

-- Combining AND and OR (use parentheses!)
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE (Price > 100 OR StockQuantity < 30) AND IsActive = 1;
