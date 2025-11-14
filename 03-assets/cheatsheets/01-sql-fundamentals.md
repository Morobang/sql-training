# SQL Fundamentals Cheatsheet

Quick reference for essential SQL commands and syntax.

---

## 📋 Table of Contents

1. [Data Types](#data-types)
2. [SELECT Queries](#select-queries)
3. [WHERE Conditions](#where-conditions)
4. [JOIN Operations](#join-operations)
5. [Aggregate Functions](#aggregate-functions)
6. [GROUP BY & HAVING](#group-by--having)
7. [Subqueries](#subqueries)
8. [Common Table Expressions (CTEs)](#common-table-expressions-ctes)
9. [Window Functions](#window-functions)
10. [Data Manipulation](#data-manipulation)
11. [Data Definition](#data-definition)
12. [Transactions](#transactions)

---

## Data Types

### String Types
```sql
CHAR(n)           -- Fixed-length string (max 8000)
VARCHAR(n)        -- Variable-length string (max 8000)
NVARCHAR(n)       -- Unicode variable-length (max 4000)
TEXT              -- Large text (deprecated, use VARCHAR(MAX))
VARCHAR(MAX)      -- Up to 2GB
```

### Numeric Types
```sql
INT               -- Integer: -2,147,483,648 to 2,147,483,647
BIGINT            -- Large integer: ±9 quintillion
DECIMAL(p,s)      -- Fixed precision: DECIMAL(10,2) = 12345678.90
NUMERIC(p,s)      -- Same as DECIMAL
FLOAT             -- Approximate numeric (floating point)
MONEY             -- Currency: -922,337,203,685,477.5808 to +922...
```

### Date/Time Types
```sql
DATE              -- Date only: 2025-11-14
TIME              -- Time only: 14:30:00
DATETIME          -- Date and time: 2025-11-14 14:30:00
DATETIME2         -- More precise datetime (preferred)
DATETIMEOFFSET    -- Datetime with timezone
```

### Other Types
```sql
BIT               -- Boolean: 0 or 1
UNIQUEIDENTIFIER  -- GUID: 6F9619FF-8B86-D011-B42D-00C04FC964FF
BINARY(n)         -- Fixed-length binary data
VARBINARY(n)      -- Variable-length binary data
XML               -- XML data
JSON (via NVARCHAR) -- JSON data (use FOR JSON, OPENJSON)
```

---

## SELECT Queries

### Basic SELECT
```sql
-- Select all columns
SELECT * FROM Customers;

-- Select specific columns
SELECT FirstName, LastName, Email FROM Customers;

-- Column aliases
SELECT 
    FirstName AS first_name,
    LastName AS last_name,
    City + ', ' + State AS location
FROM Customers;

-- DISTINCT (remove duplicates)
SELECT DISTINCT City FROM Customers;

-- TOP (limit results)
SELECT TOP 10 * FROM Orders ORDER BY OrderDate DESC;
SELECT TOP 10 PERCENT * FROM Orders;
```

### Calculated Columns
```sql
SELECT 
    ProductName,
    Price,
    Price * 0.9 AS sale_price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 200 THEN 'Standard'
        ELSE 'Premium'
    END AS price_category
FROM Products;
```

---

## WHERE Conditions

### Comparison Operators
```sql
WHERE Price = 99.99              -- Equal
WHERE Price <> 99.99             -- Not equal
WHERE Price != 99.99             -- Not equal (alternative)
WHERE Price > 100                -- Greater than
WHERE Price < 100                -- Less than
WHERE Price >= 100               -- Greater than or equal
WHERE Price <= 100               -- Less than or equal
WHERE Price BETWEEN 50 AND 200   -- Range (inclusive)
WHERE City IN ('New York', 'Los Angeles', 'Chicago')  -- List
WHERE Email LIKE '%@gmail.com'   -- Pattern matching
WHERE FirstName IS NULL          -- NULL check
WHERE FirstName IS NOT NULL      -- NOT NULL check
```

### Logical Operators
```sql
-- AND (all conditions must be true)
WHERE Price > 100 AND StockQuantity > 0;

-- OR (at least one condition must be true)
WHERE City = 'New York' OR City = 'Los Angeles';

-- NOT (negate condition)
WHERE NOT (Price > 100);

-- Combining with parentheses
WHERE (City = 'New York' OR City = 'LA') AND Price > 100;
```

### Pattern Matching (LIKE)
```sql
WHERE FirstName LIKE 'J%'        -- Starts with J
WHERE FirstName LIKE '%son'      -- Ends with son
WHERE FirstName LIKE '%oh%'      -- Contains oh
WHERE FirstName LIKE 'J_hn'      -- J, any char, hn (John, Jahn)
WHERE Email LIKE '%@gmail.com'   -- Gmail addresses
WHERE Phone LIKE '[2-9]%'        -- Starts with 2-9
WHERE Code LIKE '[A-Z][A-Z][0-9]%'  -- Two letters, then digit
```

---

## JOIN Operations

### INNER JOIN (only matching rows)
```sql
SELECT 
    o.OrderID,
    c.FirstName,
    c.LastName,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID;
```

### LEFT JOIN (all rows from left table)
```sql
SELECT 
    c.CustomerID,
    c.FirstName,
    COUNT(o.OrderID) AS order_count
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName;
```

### RIGHT JOIN (all rows from right table)
```sql
SELECT 
    p.ProductName,
    o.OrderID
FROM Orders o
RIGHT JOIN Products p ON o.ProductID = p.ProductID;
```

### FULL OUTER JOIN (all rows from both tables)
```sql
SELECT 
    c.CustomerID,
    c.FirstName,
    o.OrderID
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerID = o.CustomerID;
```

### CROSS JOIN (Cartesian product)
```sql
SELECT 
    c.FirstName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p;
```

### SELF JOIN (join table to itself)
```sql
SELECT 
    e1.EmployeeName AS employee,
    e2.EmployeeName AS manager
FROM Employees e1
INNER JOIN Employees e2 ON e1.ManagerID = e2.EmployeeID;
```

### Multiple JOINs
```sql
SELECT 
    o.OrderID,
    c.FirstName,
    p.ProductName,
    o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Products p ON o.ProductID = p.ProductID
WHERE o.OrderDate >= '2025-01-01';
```

---

## Aggregate Functions

```sql
COUNT(*)              -- Count all rows
COUNT(column)         -- Count non-NULL values
COUNT(DISTINCT City)  -- Count unique values

SUM(TotalAmount)      -- Sum of values
AVG(Price)            -- Average
MIN(OrderDate)        -- Minimum value
MAX(OrderDate)        -- Maximum value

-- String aggregation (SQL Server 2017+)
STRING_AGG(ProductName, ', ') WITHIN GROUP (ORDER BY ProductName)

-- Example
SELECT 
    COUNT(*) AS total_orders,
    SUM(TotalAmount) AS total_revenue,
    AVG(TotalAmount) AS avg_order_value,
    MIN(TotalAmount) AS min_order,
    MAX(TotalAmount) AS max_order
FROM Orders
WHERE OrderDate >= '2025-01-01';
```

---

## GROUP BY & HAVING

### GROUP BY (aggregate by groups)
```sql
-- Count orders per customer
SELECT 
    CustomerID,
    COUNT(*) AS order_count,
    SUM(TotalAmount) AS total_spent
FROM Orders
GROUP BY CustomerID;

-- Multiple grouping columns
SELECT 
    City,
    State,
    COUNT(*) AS customer_count
FROM Customers
GROUP BY City, State;
```

### HAVING (filter aggregated results)
```sql
-- Customers with more than 5 orders
SELECT 
    CustomerID,
    COUNT(*) AS order_count
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 5;

-- Cities with average order > $100
SELECT 
    c.City,
    COUNT(o.OrderID) AS order_count,
    AVG(o.TotalAmount) AS avg_order
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.City
HAVING AVG(o.TotalAmount) > 100;
```

### Execution Order
```sql
FROM       -- 1. Get source data
WHERE      -- 2. Filter rows
GROUP BY   -- 3. Group rows
HAVING     -- 4. Filter groups
SELECT     -- 5. Select columns
ORDER BY   -- 6. Sort results
OFFSET/FETCH -- 7. Pagination
```

---

## Subqueries

### Scalar Subquery (returns single value)
```sql
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS avg_price
FROM Products;
```

### IN Subquery (check membership)
```sql
SELECT CustomerID, FirstName
FROM Customers
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID 
    FROM Orders 
    WHERE OrderDate >= '2025-01-01'
);
```

### EXISTS Subquery (check existence)
```sql
SELECT c.CustomerID, c.FirstName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID 
      AND o.TotalAmount > 1000
);
```

### Correlated Subquery
```sql
SELECT 
    p.ProductName,
    p.Price,
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.ProductID = p.ProductID) AS times_ordered
FROM Products p;
```

---

## Common Table Expressions (CTEs)

### Basic CTE
```sql
WITH high_value_customers AS (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS lifetime_value
    FROM Orders
    GROUP BY CustomerID
    HAVING SUM(TotalAmount) > 10000
)
SELECT 
    c.FirstName,
    c.LastName,
    hvc.lifetime_value
FROM high_value_customers hvc
INNER JOIN Customers c ON hvc.CustomerID = c.CustomerID;
```

### Multiple CTEs
```sql
WITH 
order_stats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS order_count,
        SUM(TotalAmount) AS total_spent
    FROM Orders
    GROUP BY CustomerID
),
customer_segments AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN total_spent > 10000 THEN 'VIP'
            WHEN total_spent > 5000 THEN 'Premium'
            ELSE 'Standard'
        END AS segment
    FROM order_stats
)
SELECT * FROM customer_segments;
```

### Recursive CTE (hierarchies)
```sql
WITH employee_hierarchy AS (
    -- Anchor: Top-level employees
    SELECT 
        EmployeeID,
        EmployeeName,
        ManagerID,
        1 AS level
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive: Next level
    SELECT 
        e.EmployeeID,
        e.EmployeeName,
        e.ManagerID,
        eh.level + 1
    FROM Employees e
    INNER JOIN employee_hierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT * FROM employee_hierarchy ORDER BY level, EmployeeName;
```

---

## Window Functions

### ROW_NUMBER (sequential number)
```sql
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS order_number
FROM Orders;
```

### RANK / DENSE_RANK (ranking)
```sql
SELECT 
    ProductName,
    Price,
    RANK() OVER (ORDER BY Price DESC) AS price_rank,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS dense_rank
FROM Products;
```

### LAG / LEAD (access previous/next row)
```sql
SELECT 
    OrderDate,
    TotalAmount,
    LAG(TotalAmount) OVER (ORDER BY OrderDate) AS previous_order,
    LEAD(TotalAmount) OVER (ORDER BY OrderDate) AS next_order
FROM Orders;
```

### Running Totals (SUM OVER)
```sql
SELECT 
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY OrderDate) AS running_total
FROM Orders;
```

### Moving Average
```sql
SELECT 
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY OrderDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day
FROM Orders;
```

---

## Data Manipulation

### INSERT
```sql
-- Insert single row
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@example.com');

-- Insert multiple rows
INSERT INTO Customers (FirstName, LastName, Email)
VALUES 
    ('Jane', 'Smith', 'jane@example.com'),
    ('Bob', 'Johnson', 'bob@example.com');

-- Insert from SELECT
INSERT INTO Customers_Archive
SELECT * FROM Customers WHERE CreatedDate < '2020-01-01';
```

### UPDATE
```sql
-- Update all rows
UPDATE Products
SET Price = Price * 1.1;  -- 10% price increase

-- Update with WHERE
UPDATE Customers
SET City = 'New York', State = 'NY'
WHERE CustomerID = 123;

-- Update with JOIN
UPDATE o
SET o.DiscountAmount = o.TotalAmount * 0.1
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerType = 'VIP';
```

### DELETE
```sql
-- Delete specific rows
DELETE FROM Orders WHERE OrderDate < '2020-01-01';

-- Delete all rows (slower, logged)
DELETE FROM TempTable;

-- TRUNCATE (faster, not logged, resets identity)
TRUNCATE TABLE TempTable;

-- Delete with JOIN
DELETE o
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.IsActive = 0;
```

### MERGE (Upsert)
```sql
MERGE INTO target_table AS target
USING source_table AS source
ON target.CustomerID = source.CustomerID
WHEN MATCHED THEN
    UPDATE SET target.Email = source.Email
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CustomerID, Email) VALUES (source.CustomerID, source.Email)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;
```

---

## Data Definition

### CREATE TABLE
```sql
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
```

### ALTER TABLE
```sql
-- Add column
ALTER TABLE Customers ADD PhoneNumber VARCHAR(20);

-- Drop column
ALTER TABLE Customers DROP COLUMN PhoneNumber;

-- Modify column
ALTER TABLE Customers ALTER COLUMN Email VARCHAR(150);

-- Add constraint
ALTER TABLE Customers ADD CONSTRAINT UQ_Email UNIQUE (Email);

-- Drop constraint
ALTER TABLE Customers DROP CONSTRAINT UQ_Email;
```

### Constraints
```sql
-- Primary Key
PRIMARY KEY

-- Foreign Key
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)

-- Unique
UNIQUE

-- Check
CHECK (Price >= 0)

-- Default
DEFAULT GETDATE()

-- Not Null
NOT NULL
```

### Indexes
```sql
-- Create index
CREATE INDEX IX_Customers_Email ON Customers(Email);

-- Create unique index
CREATE UNIQUE INDEX IX_Customers_Email ON Customers(Email);

-- Composite index
CREATE INDEX IX_Orders_CustomerDate ON Orders(CustomerID, OrderDate);

-- Drop index
DROP INDEX IX_Customers_Email ON Customers;
```

---

## Transactions

### Basic Transaction
```sql
BEGIN TRANSACTION;

    INSERT INTO Orders (CustomerID, TotalAmount)
    VALUES (123, 99.99);
    
    UPDATE Customers
    SET LastOrderDate = GETDATE()
    WHERE CustomerID = 123;

COMMIT;  -- or ROLLBACK;
```

### Try-Catch
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Your SQL operations
        UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
        UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;
    
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    
    -- Error handling
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
```

### Isolation Levels
```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- Dirty reads
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;    -- Default
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;   -- No dirty/non-repeatable
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;      -- Full isolation
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;          -- Optimistic concurrency
```

---

## 🔥 Common Patterns

### Pagination
```sql
-- SQL Server 2012+
SELECT * FROM Orders
ORDER BY OrderDate DESC
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;  -- Skip 20, take 10
```

### Date Formatting
```sql
CONVERT(VARCHAR, OrderDate, 101)  -- 11/14/2025
CONVERT(VARCHAR, OrderDate, 120)  -- 2025-11-14 14:30:00
FORMAT(OrderDate, 'yyyy-MM-dd')   -- 2025-11-14
```

### String Manipulation
```sql
UPPER(FirstName)                  -- JOHN
LOWER(FirstName)                  -- john
LEN(FirstName)                    -- Length
LEFT(FirstName, 3)                -- First 3 chars
RIGHT(FirstName, 3)               -- Last 3 chars
SUBSTRING(Email, 1, 10)           -- Substring
REPLACE(Email, '@', ' AT ')       -- Replace
TRIM(FirstName)                   -- Remove whitespace
CONCAT(FirstName, ' ', LastName)  -- Concatenate
```

### NULL Handling
```sql
ISNULL(column, 'default')         -- Replace NULL
COALESCE(col1, col2, col3, 'default')  -- First non-NULL
NULLIF(col1, col2)                -- NULL if equal
```

---

**Pro Tips**:
- Always use `WHERE` before `ORDER BY` for better performance
- Use `EXISTS` instead of `IN` for subqueries with large datasets
- Index foreign keys and frequently filtered columns
- Avoid `SELECT *` in production code
- Use `EXPLAIN` / `Execution Plan` to optimize slow queries

---

*Last Updated: November 14, 2025*
