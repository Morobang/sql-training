-- ============================================================================
-- CHAPTER 02 - PRACTICE EXERCISES
-- ============================================================================
-- Complete these exercises to test your Chapter 02 knowledge
-- Prerequisites: Run 00-setup/complete-setup.sql first
-- ============================================================================

USE BookStore;
GO

PRINT '========================================';
PRINT 'Chapter 02 - Practice Exercises';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- EXERCISE SET 1: DATA TYPES
-- ============================================================================

PRINT 'Exercise Set 1: Data Types';
PRINT '----------------------------';

-- Exercise 1.1: Create a table for employee information
-- TODO: Create a table named 'Employees' with the following columns:
-- - EmployeeID: Auto-incrementing primary key
-- - FirstName: Unicode text up to 50 characters, required
-- - LastName: Unicode text up to 50 characters, required
-- - Email: ASCII text up to 100 characters, required and unique
-- - HireDate: Date only
-- - Salary: Currency with 2 decimal places, must be positive
-- - DepartmentCode: Fixed 3-character code
-- - IsFullTime: Boolean (bit), default true

-- YOUR CODE HERE:
/*
CREATE TABLE Employees (
    -- Your solution here
);
*/

-- Exercise 1.2: Insert sample employee data
-- TODO: Insert at least 3 employees with different salaries and hire dates

-- YOUR CODE HERE:
/*
INSERT INTO Employees (...) VALUES (...);
*/

PRINT 'Exercise 1 complete - Review your Employees table';
GO

-- ============================================================================
-- EXERCISE SET 2: CONSTRAINTS
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 2: Constraints';
PRINT '----------------------------';

-- Exercise 2.1: Create a courses table with constraints
-- TODO: Create a 'Courses' table with:
-- - CourseID: Primary key, auto-increment
-- - CourseName: Required, unique, up to 100 characters
-- - Credits: Integer between 1 and 6
-- - MaxStudents: Integer, must be at least 5
-- - StartDate: Date
-- - EndDate: Date (must be after StartDate)
-- - Price: Decimal, must be positive

-- YOUR CODE HERE:
/*
CREATE TABLE Courses (
    -- Your solution here
);
*/

-- Exercise 2.2: Test your constraints
-- Try to insert data that violates constraints to see error messages

-- YOUR CODE HERE:
/*
-- Test 1: Try negative credits
INSERT INTO Courses (CourseName, Credits, Price, StartDate, EndDate)
VALUES ('Test Course', -1, 299.99, '2024-01-01', '2024-03-01');

-- Test 2: Try EndDate before StartDate
INSERT INTO Courses (CourseName, Credits, Price, StartDate, EndDate)
VALUES ('Test Course', 3, 299.99, '2024-03-01', '2024-01-01');
*/

PRINT 'Exercise 2 complete - Test constraint violations';
GO

-- ============================================================================
-- EXERCISE SET 3: INSERT OPERATIONS
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 3: INSERT Operations';
PRINT '-----------------------------------';

-- Exercise 3.1: Single row insert
-- TODO: Insert a new customer with all details

-- YOUR CODE HERE:
/*
INSERT INTO Customers (FirstName, LastName, Email, Phone, BirthDate, City, State)
VALUES ('Your', 'Name', 'your.email@example.com', '555-0200', '1995-01-01', 'Seattle', 'WA');
*/

-- Exercise 3.2: Multiple row insert
-- TODO: Insert 3 new products in a single INSERT statement

-- YOUR CODE HERE:
/*
INSERT INTO Products (CategoryID, ProductName, SKU, Price, Cost, StockQuantity)
VALUES 
    (3, 'Product 1', 'SKU-001', 19.99, 10.00, 50),
    (3, 'Product 2', 'SKU-002', 29.99, 15.00, 30),
    (3, 'Product 3', 'SKU-003', 39.99, 20.00, 40);
*/

-- Exercise 3.3: INSERT with OUTPUT
-- TODO: Insert a product and capture the generated ProductID

-- YOUR CODE HERE:
/*
DECLARE @NewProductID INT;

INSERT INTO Products (CategoryID, ProductName, SKU, Price, Cost, StockQuantity)
OUTPUT INSERTED.ProductID, INSERTED.ProductName
VALUES (3, 'New Product', 'SKU-NEW', 49.99, 25.00, 100);
*/

PRINT 'Exercise 3 complete - Review your INSERT statements';
GO

-- ============================================================================
-- EXERCISE SET 4: UPDATE OPERATIONS
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 4: UPDATE Operations';
PRINT '-----------------------------------';

-- Exercise 4.1: Simple UPDATE
-- TODO: Increase the price of all products in category 3 by 10%

-- YOUR CODE HERE:
/*
UPDATE Products
SET Price = Price * 1.10
WHERE CategoryID = 3;
*/

-- Exercise 4.2: UPDATE with calculated columns
-- TODO: Update orders status to 'Shipped' for all pending orders older than 3 days

-- YOUR CODE HERE:
/*
UPDATE Orders
SET OrderStatus = 'Shipped',
    ShippedDate = GETDATE()
WHERE OrderStatus = 'Pending' 
  AND OrderDate < DATEADD(DAY, -3, GETDATE());
*/

-- Exercise 4.3: UPDATE with JOIN
-- TODO: Update product stock quantity based on inventory table
-- Add warehouse quantities to product stock

-- YOUR CODE HERE:
/*
UPDATE p
SET p.StockQuantity = p.StockQuantity + ISNULL(i.TotalWarehouseQty, 0)
FROM Products p
LEFT JOIN (
    SELECT ProductID, SUM(Quantity) AS TotalWarehouseQty
    FROM Inventory
    GROUP BY ProductID
) i ON p.ProductID = i.ProductID;
*/

PRINT 'Exercise 4 complete - Review your UPDATE statements';
GO

-- ============================================================================
-- EXERCISE SET 5: DELETE OPERATIONS
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 5: DELETE Operations';
PRINT '-----------------------------------';

-- Exercise 5.1: DELETE with WHERE clause
-- TODO: Delete all inactive customers who have never placed an order

-- YOUR CODE HERE:
/*
DELETE FROM Customers
WHERE IsActive = 0 
  AND CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Orders);
*/

-- Exercise 5.2: DELETE with JOIN
-- TODO: Delete order details for cancelled orders

-- YOUR CODE HERE:
/*
DELETE od
FROM OrderDetails od
INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderStatus = 'Cancelled';
*/

-- Exercise 5.3: Implement soft delete
-- TODO: Instead of deleting, update IsActive to 0 for old reviews (older than 2 years)

-- YOUR CODE HERE:
/*
-- First, add IsActive column if needed
ALTER TABLE Reviews
ADD IsActive BIT DEFAULT 1;

-- Then "soft delete"
UPDATE Reviews
SET IsActive = 0
WHERE ReviewDate < DATEADD(YEAR, -2, GETDATE());
*/

PRINT 'Exercise 5 complete - Review your DELETE statements';
GO

-- ============================================================================
-- EXERCISE SET 6: WORKING WITH DATES
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 6: Working with Dates';
PRINT '------------------------------------';

-- Exercise 6.1: Calculate customer age
-- TODO: Select customers with their ages

-- YOUR CODE HERE:
/*
SELECT 
    FirstName,
    LastName,
    BirthDate,
    DATEDIFF(YEAR, BirthDate, GETDATE()) AS Age
FROM Customers
WHERE BirthDate IS NOT NULL
ORDER BY Age DESC;
*/

-- Exercise 6.2: Orders in the last 30 days
-- TODO: Get all orders placed in the last 30 days with customer info

-- YOUR CODE HERE:
/*
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderDate,
    DATEDIFF(DAY, o.OrderDate, GETDATE()) AS DaysAgo,
    o.Total
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY o.OrderDate DESC;
*/

-- Exercise 6.3: Monthly sales summary
-- TODO: Get total sales by month for the current year

-- YOUR CODE HERE:
/*
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    DATENAME(MONTH, OrderDate) AS MonthName,
    COUNT(OrderID) AS TotalOrders,
    SUM(Total) AS TotalSales,
    AVG(Total) AS AverageSale
FROM Orders
WHERE YEAR(OrderDate) = YEAR(GETDATE())
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY Year, Month;
*/

PRINT 'Exercise 6 complete - Review your date queries';
GO

-- ============================================================================
-- EXERCISE SET 7: ADVANCED CHALLENGES
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 7: Advanced Challenges';
PRINT '-------------------------------------';

-- Challenge 7.1: Product Performance Report
-- TODO: Create a query showing:
-- - Product name
-- - Total quantity sold
-- - Total revenue
-- - Average rating
-- - Number of reviews
-- Sort by revenue descending

-- YOUR CODE HERE:
/*
SELECT 
    p.ProductName,
    ISNULL(SUM(od.Quantity), 0) AS TotalQuantitySold,
    ISNULL(SUM(od.LineTotal), 0) AS TotalRevenue,
    AVG(r.Rating) AS AverageRating,
    COUNT(DISTINCT r.ReviewID) AS ReviewCount
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
LEFT JOIN Reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalRevenue DESC;
*/

-- Challenge 7.2: Customer Lifetime Value
-- TODO: Calculate each customer's total spending and order count
-- Include customers who haven't ordered yet (show 0)

-- YOUR CODE HERE:
/*
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Email,
    COALESCE(COUNT(o.OrderID), 0) AS TotalOrders,
    COALESCE(SUM(o.Total), 0) AS LifetimeValue,
    MAX(o.OrderDate) AS LastOrderDate,
    CASE 
        WHEN MAX(o.OrderDate) IS NULL THEN 'Never Ordered'
        WHEN MAX(o.OrderDate) > DATEADD(MONTH, -3, GETDATE()) THEN 'Active'
        WHEN MAX(o.OrderDate) > DATEADD(MONTH, -12, GETDATE()) THEN 'At Risk'
        ELSE 'Inactive'
    END AS CustomerStatus
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email
ORDER BY LifetimeValue DESC;
*/

-- Challenge 7.3: Inventory Alert System
-- TODO: Create a report of products that need reordering
-- Include: Product info, current stock, reorder level, suggested order quantity

-- YOUR CODE HERE:
/*
SELECT 
    p.ProductID,
    p.ProductName,
    p.SKU,
    p.StockQuantity AS CurrentStock,
    p.ReorderLevel,
    p.ReorderLevel * 2 - p.StockQuantity AS SuggestedOrderQty,
    p.Cost,
    (p.ReorderLevel * 2 - p.StockQuantity) * p.Cost AS EstimatedCost
FROM Products p
WHERE p.StockQuantity <= p.ReorderLevel
  AND p.IsActive = 1
ORDER BY p.StockQuantity ASC;
*/

-- Challenge 7.4: Sales Trend Analysis
-- TODO: Compare sales this month vs last month

-- YOUR CODE HERE:
/*
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(Total) AS MonthTotal,
        COUNT(OrderID) AS OrderCount
    FROM Orders
    WHERE OrderDate >= DATEADD(MONTH, -2, GETDATE())
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    *,
    LAG(MonthTotal) OVER (ORDER BY Year, Month) AS PreviousMonthTotal,
    MonthTotal - LAG(MonthTotal) OVER (ORDER BY Year, Month) AS Difference,
    CASE 
        WHEN LAG(MonthTotal) OVER (ORDER BY Year, Month) IS NOT NULL THEN
            ((MonthTotal - LAG(MonthTotal) OVER (ORDER BY Year, Month)) / 
             LAG(MonthTotal) OVER (ORDER BY Year, Month) * 100)
        ELSE NULL
    END AS PercentChange
FROM MonthlySales
ORDER BY Year, Month;
*/

PRINT 'Exercise 7 complete - Review advanced challenges';
GO

-- ============================================================================
-- EXERCISE SET 8: CREATE YOUR OWN TABLES
-- ============================================================================

PRINT '';
PRINT 'Exercise Set 8: Create Your Own Database';
PRINT '------------------------------------------';

-- Challenge: Design and implement a Library Management System
-- Requirements:
-- 1. Books table (ISBN, title, author, publish date, etc.)
-- 2. Members table (member info, join date, status)
-- 3. Loans table (which member borrowed which book, when)
-- 4. Include appropriate:
--    - Primary keys
--    - Foreign keys
--    - Check constraints
--    - Default values
-- 5. Insert sample data
-- 6. Write queries to:
--    - Find overdue books
--    - Most popular books
--    - Active members

-- YOUR CODE HERE:
/*
-- Your complete library system implementation
*/

PRINT 'Exercise 8 complete - Library system challenge';
GO

-- ============================================================================
-- SOLUTIONS SECTION
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'Exercises Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Solutions available in:';
PRINT '  02-exercises/chapter-02/solutions.sql';
PRINT '';
PRINT 'Remember to:';
PRINT '  1. Test your code before running in production';
PRINT '  2. Use transactions for data modifications';
PRINT '  3. Always SELECT before UPDATE/DELETE';
PRINT '  4. Back up your data regularly';
PRINT '';

-- ============================================================================
-- QUIZ YOURSELF
-- ============================================================================

PRINT 'Quick Knowledge Check:';
PRINT '----------------------';
PRINT '1. What is the difference between CHAR and VARCHAR?';
PRINT '2. When should you use DECIMAL vs FLOAT?';
PRINT '3. What is the difference between DATETIME and DATETIME2?';
PRINT '4. How do you prevent duplicate values in a column?';
PRINT '5. What happens when you DELETE vs TRUNCATE a table?';
PRINT '6. How do you get the last inserted IDENTITY value?';
PRINT '7. What is a CHECK constraint?';
PRINT '8. How do you add a column with a default value?';
PRINT '9. What is the purpose of foreign keys?';
PRINT '10. How do you update one table based on another?';
PRINT '';
PRINT 'Review the chapter material if you need help!';

GO

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================

/*
-- Uncomment to reset the database for a fresh start
USE master;
GO

ALTER DATABASE BookStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE BookStore;
GO

PRINT 'Database cleaned up. Run complete-setup.sql again to start fresh.';
*/
