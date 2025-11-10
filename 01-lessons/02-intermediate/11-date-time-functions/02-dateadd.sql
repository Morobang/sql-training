-- ========================================
-- Date Functions: DATEADD
-- ========================================

USE TechStore;

-- DATEADD: Add time interval to date
-- DATEADD(datepart, number, date)

-- Add days
SELECT 
    SaleDate,
    DATEADD(DAY, 7, SaleDate) AS WeekLater
FROM Sales;

-- Add months
SELECT 
    JoinDate,
    DATEADD(MONTH, 1, JoinDate) AS OneMonthLater
FROM Customers;

-- Add years
SELECT 
    JoinDate,
    DATEADD(YEAR, 1, JoinDate) AS Anniversary
FROM Customers;

-- Subtract (use negative numbers)
SELECT 
    SaleDate,
    DATEADD(DAY, -30, SaleDate) AS ThirtyDaysAgo
FROM Sales;

-- Practical: Calculate due dates
SELECT 
    SaleID,
    SaleDate,
    DATEADD(DAY, 30, SaleDate) AS PaymentDue
FROM Sales;
