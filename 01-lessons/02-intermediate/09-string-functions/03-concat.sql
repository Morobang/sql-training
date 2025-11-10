-- ========================================
-- String Functions: CONCAT and CONCAT_WS
-- ========================================

USE TechStore;

-- CONCAT: Combine strings
SELECT 
    CustomerName,
    City,
    State,
    CONCAT(City, ', ', State) AS Location
FROM Customers;

-- Multiple columns
SELECT 
    ProductName,
    Price,
    CONCAT(ProductName, ' - $', Price) AS ProductLabel
FROM Products;

-- CONCAT_WS: Concat with separator
SELECT 
    CustomerName,
    City,
    State,
    CONCAT_WS(', ', CustomerName, City, State) AS FullInfo
FROM Customers;

-- Practical: Create display labels
SELECT 
    SaleID,
    CONCAT('Sale #', SaleID, ' - $', TotalAmount) AS SaleLabel
FROM Sales;
