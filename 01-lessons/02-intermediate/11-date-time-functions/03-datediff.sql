-- ========================================
-- Date Functions: DATEDIFF
-- ========================================

USE TechStore;

-- DATEDIFF: Calculate difference between dates
-- DATEDIFF(datepart, startdate, enddate)

-- Days between dates
SELECT 
    SaleDate,
    GETDATE() AS Today,
    DATEDIFF(DAY, SaleDate, GETDATE()) AS DaysAgo
FROM Sales;

-- Months between dates
SELECT 
    JoinDate,
    DATEDIFF(MONTH, JoinDate, GETDATE()) AS MonthsSinceJoined
FROM Customers;

-- Years between dates
SELECT 
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsEmployed
FROM Employees
WHERE HireDate IS NOT NULL;

-- Practical: Find recent sales
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    DATEDIFF(DAY, SaleDate, GETDATE()) AS DaysAgo
FROM Sales
WHERE DATEDIFF(DAY, SaleDate, GETDATE()) <= 7
ORDER BY SaleDate DESC;
