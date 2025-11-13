-- ========================================
-- Table Aliases: Shorthand for Table Names
-- ========================================

USE TechStore;

-- Without aliases (verbose)
SELECT 
    Sales.SaleID,
    Customers.CustomerName,
    Products.ProductName
FROM Sales
INNER JOIN Customers ON Sales.CustomerID = Customers.CustomerID
INNER JOIN Products ON Sales.ProductID = Products.ProductID;

-- With aliases (clean and readable)
SELECT 
    s.SaleID,
    c.CustomerName,
    p.ProductName
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID;

-- Common aliases:
-- s = Sales
-- c = Customers
-- p = Products
-- e = Employees
-- d = Departments
