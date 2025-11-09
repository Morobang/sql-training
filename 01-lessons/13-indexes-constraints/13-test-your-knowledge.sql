/*
================================================================================
LESSON 13.13: TEST YOUR KNOWLEDGE - INDEXES AND CONSTRAINTS
================================================================================

Welcome to the comprehensive assessment for Chapter 13!

This test covers all topics from the chapter:
- Index fundamentals and types
- Creating and designing indexes
- Primary key, foreign key, unique constraints
- Check and default constraints
- Index maintenance and fragmentation
- Advanced index types (filtered, columnstore, full-text, spatial)
- Constraint management
- Performance considerations

INSTRUCTIONS:
-------------
1. Complete all exercises without looking at solutions first
2. Each exercise has a point value (Total: 400 points)
3. Solutions are provided at the end
4. Grade yourself honestly
5. Review topics where you struggled

GRADING SCALE:
--------------
360-400 points (90-100%): Excellent! Ready for Chapter 14
320-359 points (80-89%):  Good! Review weak areas
280-319 points (70-79%):  Fair - Re-study some topics
Below 280 (< 70%):        Review the entire chapter

Time Limit: 90 minutes (recommended)
Database: RetailStore

Good luck!
================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
SECTION 1: INDEX FUNDAMENTALS (50 points)
================================================================================
*/

/*
EXERCISE 1.1 (10 points)
------------------------
Explain the difference between clustered and nonclustered indexes.
Create a table with both types and describe their characteristics.

Write your answer as comments, then create example table.
*/

-- Your answer here:






/*
EXERCISE 1.2 (15 points)
------------------------
Create a table 'Book' with the following requirements:
- ISBN (Primary Key, clustered index)
- Title (Required)
- Author (Required)
- PublicationYear (Required)
- Price (Required, must be > 0)
- QuantityInStock (Required, default 0)
- Create appropriate indexes for common queries on Author and PublicationYear
*/

-- Your solution here:






/*
EXERCISE 1.3 (15 points)
------------------------
Demonstrate the difference between Index Seek and Index Scan.
Create a table, add data, and show queries that result in each operation.
Include execution plan analysis in comments.
*/

-- Your solution here:






/*
EXERCISE 1.4 (10 points)
------------------------
Explain when you would use a composite index versus multiple single-column indexes.
Provide a practical example.
*/

-- Your answer and example here:






/*
================================================================================
SECTION 2: CREATING AND DESIGNING INDEXES (60 points)
================================================================================
*/

/*
EXERCISE 2.1 (20 points)
------------------------
Create a CustomerPurchase table with optimal indexes for these queries:
1. Find all purchases by CustomerID
2. Find purchases in a date range
3. Find purchases by CustomerID AND date range
4. Get total purchase amount by customer

Consider covering indexes where appropriate.
*/

-- Your solution here:






/*
EXERCISE 2.2 (20 points)
------------------------
Create a filtered index on an Orders table that indexes only:
- Orders from the last 30 days
- Orders with status 'Pending' or 'Processing'

Demonstrate the index is used by a query.
*/

-- Your solution here:






/*
EXERCISE 2.3 (20 points)
------------------------
Design indexes for this scenario:

You have a Products table with 1,000,000 rows:
- 80% of products are Active (IsActive = 1)
- 15% are Discontinued (IsActive = 0, IsDiscontinued = 1)
- 5% are Pending (IsActive = 0, IsDiscontinued = 0)

Queries:
- 90% of queries search Active products
- 8% search Discontinued products
- 2% search Pending products

Design optimal indexes considering storage, performance, and maintenance.
*/

-- Your solution here:






/*
================================================================================
SECTION 3: CONSTRAINTS (80 points)
================================================================================
*/

/*
EXERCISE 3.1 (25 points)
------------------------
Create a schema for an Employee/Department system with:

Tables:
- Department (DepartmentID, DepartmentName, ManagerID)
- Employee (EmployeeID, FirstName, LastName, Email, DepartmentID, Salary, HireDate)

Constraints:
- Primary keys for both tables
- Foreign key: Employee.DepartmentID → Department.DepartmentID (CASCADE on update, RESTRICT on delete)
- Unique: Employee.Email
- Check: Employee.Salary > 0 and < 1000000
- Check: Employee.HireDate <= today
- Default: HireDate = today
- Self-referencing FK: Department.ManagerID → Employee.EmployeeID (manager is an employee)

Test all constraints with valid and invalid data.
*/

-- Your solution here:






/*
EXERCISE 3.2 (20 points)
------------------------
Modify an existing table to add constraints:

1. Create a Product table WITHOUT constraints
2. Insert sample data (some violating future constraints)
3. Add constraints (handling existing violations)
4. Document your approach to dealing with violations
*/

-- Your solution here:






/*
EXERCISE 3.3 (20 points)
------------------------
Demonstrate constraint management:

1. Create a table with multiple constraints
2. Disable all constraints
3. Insert violating data
4. Identify violations with SQL queries
5. Fix violations
6. Re-enable constraints with validation
7. Show all constraints and their status
*/

-- Your solution here:






/*
EXERCISE 3.4 (15 points)
------------------------
Create check constraints that validate:

1. Email format (contains @ and .)
2. Phone number format (XXX-XXX-XXXX)
3. Date range (EndDate > StartDate)
4. Price within range based on category

Test each constraint with valid and invalid data.
*/

-- Your solution here:






/*
================================================================================
SECTION 4: INDEX MAINTENANCE (60 points)
================================================================================
*/

/*
EXERCISE 4.1 (25 points)
------------------------
Create a comprehensive index maintenance script that:

1. Identifies fragmented indexes (>30%)
2. Rebuilds heavily fragmented indexes
3. Reorganizes moderately fragmented indexes (10-30%)
4. Updates statistics
5. Logs maintenance actions to a table
6. Reports summary of actions taken

Test with a table that has fragmented indexes.
*/

-- Your solution here:






/*
EXERCISE 4.2 (20 points)
------------------------
Analyze index usage and create a report showing:

1. Unused indexes (candidates for removal)
2. Write-heavy indexes (high updates, low reads)
3. Missing indexes (from DMVs)
4. Recommendations for each

Generate DROP and CREATE statements (don't execute).
*/

-- Your solution here:






/*
EXERCISE 4.3 (15 points)
------------------------
Demonstrate the impact of fragmentation:

1. Create a table with random GUIDs (causes fragmentation)
2. Insert 50,000 rows
3. Check fragmentation level
4. Measure query performance
5. Rebuild index
6. Measure query performance again
7. Compare results
*/

-- Your solution here:






/*
================================================================================
SECTION 5: ADVANCED INDEX TYPES (60 points)
================================================================================
*/

/*
EXERCISE 5.1 (20 points)
------------------------
Create a product catalog with full-text search:

1. Create ProductCatalog table (Name, Description, Specifications)
2. Create full-text catalog and index
3. Write queries using:
   - CONTAINS for exact match
   - FREETEXT for natural language
   - Proximity search (NEAR)
   - Ranked results (CONTAINSTABLE)

Test with sample product data.
*/

-- Your solution here:






/*
EXERCISE 5.2 (20 points)
------------------------
Create a columnstore index for analytics:

1. Create a SalesFact table (Date, Product, Customer, Amount, Quantity)
2. Insert 100,000 rows
3. Create nonclustered columnstore index
4. Write analytical queries (aggregations, GROUP BY)
5. Compare performance with and without columnstore
*/

-- Your solution here:






/*
EXERCISE 5.3 (20 points)
------------------------
Create covering indexes to eliminate key lookups:

1. Create a table with 10 columns
2. Write a query that causes key lookups
3. Analyze execution plan
4. Create covering index with INCLUDE
5. Verify key lookups eliminated
6. Compare logical reads before/after
*/

-- Your solution here:






/*
================================================================================
SECTION 6: PERFORMANCE OPTIMIZATION (90 points)
================================================================================
*/

/*
EXERCISE 6.1 (30 points)
------------------------
Performance comparison:

1. Create an Orders table (50,000 rows)
2. Measure INSERT performance with 0 indexes
3. Add 5 nonclustered indexes
4. Measure INSERT performance again
5. Calculate overhead percentage
6. Measure SELECT performance for both scenarios
7. Determine optimal index strategy

Document all findings with statistics.
*/

-- Your solution here:






/*
EXERCISE 6.2 (30 points)
------------------------
Query optimization challenge:

Given this slow query:
"Find all customers who made purchases > $1000 in 2023, 
 group by month, show customer name, month, and total amount"

1. Create necessary tables
2. Insert sample data (10,000+ rows)
3. Run query WITHOUT optimal indexes (measure performance)
4. Analyze execution plan
5. Design and create optimal indexes
6. Re-run query (measure performance)
7. Document improvement percentage

Show all work and measurements.
*/

-- Your solution here:






/*
EXERCISE 6.3 (30 points)
------------------------
Real-world scenario:

You inherit a database with these issues:
- 20 tables, each with 8-12 indexes
- Many unused indexes
- High fragmentation (>50% on several indexes)
- Missing indexes suggested by DMVs
- Poor query performance

Create a complete optimization plan:
1. Identify all issues with queries
2. Generate DROP statements for unused indexes
3. Generate REBUILD statements for fragmented indexes
4. Generate CREATE statements for missing indexes
5. Estimate impact of changes
6. Create execution plan

Document methodology and expected improvements.
*/

-- Your solution here:






/*
================================================================================
SECTION 7: REAL-WORLD APPLICATION (Bonus: 50 points)
================================================================================
*/

/*
BONUS EXERCISE 7.1 (50 points)
------------------------------
Design a complete database for an e-commerce system:

Tables needed:
- Customer
- Product
- Category
- Order
- OrderDetail
- Supplier
- Inventory
- Review

Requirements:
1. All appropriate primary keys
2. All foreign keys with appropriate CASCADE options
3. Unique constraints where needed
4. Check constraints for data validation
5. Default constraints for common values
6. Indexes optimized for these queries:
   - Customer order history
   - Product search by category
   - Inventory levels by product
   - Revenue reports by date range
   - Top-rated products
7. Consider read vs write ratios
8. Document all design decisions

Create complete schema with sample data and test queries.
*/

-- Your solution here:






/*
================================================================================
SOLUTIONS
================================================================================
Do not look at solutions until you've attempted all exercises!

Scroll down for solutions...
*/





























/*
================================================================================
SECTION 1 SOLUTIONS: INDEX FUNDAMENTALS (50 points)
================================================================================
*/

-- SOLUTION 1.1 (10 points)
/*
CLUSTERED INDEX:
- Physical order of data
- One per table
- Leaf level = data pages
- Faster range queries
- Slower inserts (may require page splits)

NONCLUSTERED INDEX:
- Logical order separate from physical
- Multiple per table
- Leaf level = pointers to data
- Faster specific lookups
- Includes key lookup overhead
*/

DROP TABLE IF EXISTS BookExample;
GO

CREATE TABLE BookExample (
    BookID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,  -- Clustered index
    ISBN VARCHAR(20) NOT NULL UNIQUE NONCLUSTERED,   -- Nonclustered index
    Title NVARCHAR(200) NOT NULL,
    PublicationYear INT
);
GO

-- SOLUTION 1.2 (15 points)
DROP TABLE IF EXISTS Book;
GO

CREATE TABLE Book (
    ISBN VARCHAR(20) PRIMARY KEY CLUSTERED,  -- Clustered on ISBN
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100) NOT NULL,
    PublicationYear INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    QuantityInStock INT NOT NULL DEFAULT 0,
    CONSTRAINT CK_Book_Price CHECK (Price > 0),
    CONSTRAINT CK_Book_PublicationYear CHECK (PublicationYear > 1450 AND PublicationYear <= YEAR(GETDATE()))
);
GO

-- Indexes for common queries
CREATE INDEX IX_Book_Author ON Book(Author);
CREATE INDEX IX_Book_PublicationYear ON Book(PublicationYear);
CREATE INDEX IX_Book_Author_Year ON Book(Author, PublicationYear);  -- Composite for combined search
GO

-- SOLUTION 1.3 (15 points)
DROP TABLE IF EXISTS SeekScanDemo;
GO

CREATE TABLE SeekScanDemo (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SearchValue INT NOT NULL,
    Data NVARCHAR(100)
);
GO

-- Insert data
INSERT INTO SeekScanDemo (SearchValue, Data)
SELECT number, 'Data ' + CAST(number AS VARCHAR(10))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;
GO

CREATE INDEX IX_SeekScanDemo_SearchValue ON SeekScanDemo(SearchValue);
GO

-- Index SEEK (efficient - uses index to find specific rows)
SELECT ID, SearchValue, Data
FROM SeekScanDemo
WHERE SearchValue = 5000;  -- Equality search = Seek
GO

-- Index SCAN (less efficient - reads entire index)
SELECT ID, SearchValue, Data
FROM SeekScanDemo
WHERE SearchValue < 100 OR SearchValue > 9900;  -- Wide range or complex predicate = Scan
GO

/*
EXECUTION PLAN ANALYSIS:
- Seek: Directly navigates to specific rows (fast)
- Scan: Reads all/most rows (slower for large tables)
*/

-- SOLUTION 1.4 (10 points)
/*
COMPOSITE INDEX vs MULTIPLE SINGLE-COLUMN INDEXES:

Use COMPOSITE INDEX when:
- Queries filter on multiple columns together
- Column order matters (most selective first)
- Reduces index count

Use MULTIPLE SINGLE-COLUMN INDEXES when:
- Queries filter on different individual columns
- Index intersection possible
- More flexibility

EXAMPLE: Product search
*/

DROP TABLE IF EXISTS ProductSearch;
GO

CREATE TABLE ProductSearch (
    ProductID INT PRIMARY KEY,
    Category VARCHAR(50),
    Brand VARCHAR(50),
    Price DECIMAL(10,2)
);
GO

-- Composite index for common query: WHERE Category = ? AND Brand = ?
CREATE INDEX IX_ProductSearch_Category_Brand ON ProductSearch(Category, Brand);

-- Single column indexes for queries using only one column
CREATE INDEX IX_ProductSearch_Price ON ProductSearch(Price);
GO

/*
Query: WHERE Category = 'Electronics' AND Brand = 'Sony'
Uses: IX_ProductSearch_Category_Brand (composite)

Query: WHERE Price < 100
Uses: IX_ProductSearch_Price (single column)
*/

/*
================================================================================
SECTION 2 SOLUTIONS: CREATING AND DESIGNING INDEXES (60 points)
================================================================================
*/

-- SOLUTION 2.1 (20 points)
DROP TABLE IF EXISTS CustomerPurchase;
GO

CREATE TABLE CustomerPurchase (
    PurchaseID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    PurchaseDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    ProductID INT NOT NULL
);
GO

-- Index for Query 1: Find all purchases by CustomerID
CREATE INDEX IX_CustomerPurchase_CustomerID 
ON CustomerPurchase(CustomerID)
INCLUDE (PurchaseDate, Amount);  -- Covering
GO

-- Index for Query 2: Find purchases in date range
CREATE INDEX IX_CustomerPurchase_PurchaseDate 
ON CustomerPurchase(PurchaseDate)
INCLUDE (CustomerID, Amount);  -- Covering
GO

-- Index for Query 3 & 4: Find by CustomerID AND date range, totals by customer
CREATE INDEX IX_CustomerPurchase_CustomerID_Date 
ON CustomerPurchase(CustomerID, PurchaseDate)
INCLUDE (Amount);  -- Covering for both queries
GO

-- SOLUTION 2.2 (20 points)
DROP TABLE IF EXISTS Orders_Filtered;
GO

CREATE TABLE Orders_Filtered (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status VARCHAR(20) NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2)
);
GO

-- Insert sample data
INSERT INTO Orders_Filtered (OrderDate, Status, CustomerID, Amount)
SELECT 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 90, CAST(GETDATE() AS DATE)),
    CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Processing'
        WHEN 2 THEN 'Shipped'
        WHEN 3 THEN 'Delivered'
        ELSE 'Cancelled'
    END,
    ABS(CHECKSUM(NEWID())) % 1000 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 1000 + 10 AS DECIMAL(10,2))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 5000;
GO

-- Filtered index (only recent pending/processing orders)
CREATE INDEX IX_Orders_Filtered_Recent 
ON Orders_Filtered(OrderDate, CustomerID)
WHERE Status IN ('Pending', 'Processing')
    AND OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
GO

-- Query using filtered index
SELECT OrderID, OrderDate, CustomerID, Amount
FROM Orders_Filtered
WHERE Status IN ('Pending', 'Processing')
    AND OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
ORDER BY OrderDate DESC;
GO

-- SOLUTION 2.3 (20 points)
DROP TABLE IF EXISTS Products_Optimized;
GO

CREATE TABLE Products_Optimized (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(200),
    IsActive BIT NOT NULL,
    IsDiscontinued BIT NOT NULL,
    Price DECIMAL(10,2)
);
GO

/*
OPTIMAL INDEX STRATEGY:

1. Filtered index for Active products (80% of queries, 80% of data)
   - Smaller than full index
   - Faster for most queries
*/

CREATE INDEX IX_Products_Active 
ON Products_Optimized(ProductName)
WHERE IsActive = 1;
GO

/*
2. Filtered index for Discontinued products (8% of queries, 15% of data)
   - Still beneficial
*/

CREATE INDEX IX_Products_Discontinued 
ON Products_Optimized(ProductName)
WHERE IsDiscontinued = 1 AND IsActive = 0;
GO

/*
3. No index for Pending products (2% of queries, 5% of data)
   - Not worth overhead
   - Queries can use clustered index scan

RATIONALE:
- Two filtered indexes cover 88% of queries
- Much smaller than single full index
- Less maintenance overhead
- Better performance for common cases
*/

/*
================================================================================
SECTION 3 SOLUTIONS: CONSTRAINTS (80 points)
================================================================================
*/

-- SOLUTION 3.1 (25 points)
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Department;
GO

CREATE TABLE Department (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    ManagerID INT NULL  -- NULL allowed initially (circular reference)
);
GO

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    DepartmentID INT NOT NULL,
    Salary DECIMAL(10,2) NOT NULL,
    HireDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Employee_Department 
        FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,  -- Cannot delete department with employees
    CONSTRAINT CK_Employee_Salary CHECK (Salary > 0 AND Salary < 1000000),
    CONSTRAINT CK_Employee_HireDate CHECK (HireDate <= CAST(GETDATE() AS DATE))
);
GO

-- Add self-referencing FK to Department
ALTER TABLE Department
ADD CONSTRAINT FK_Department_Manager 
    FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeID);
GO

-- Test valid data
INSERT INTO Department (DepartmentID, DepartmentName, ManagerID)
VALUES (1, 'Engineering', NULL);

INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID, Salary, HireDate)
VALUES (1, 'John', 'Doe', 'john@company.com', 1, 75000, '2024-01-15');

UPDATE Department SET ManagerID = 1 WHERE DepartmentID = 1;
GO

-- Test invalid data
BEGIN TRY
    INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID, Salary)
    VALUES (2, 'Jane', 'Smith', 'john@company.com', 1, 50000);  -- Duplicate email
END TRY
BEGIN CATCH
    PRINT 'UNIQUE constraint violation: ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID, Salary)
    VALUES (3, 'Bob', 'Johnson', 'bob@company.com', 1, -1000);  -- Invalid salary
END TRY
BEGIN CATCH
    PRINT 'CHECK constraint violation: ' + ERROR_MESSAGE();
END CATCH;
GO

-- SOLUTION 3.2 (20 points)
DROP TABLE IF EXISTS Product_Constraints;
GO

-- Step 1: Create without constraints
CREATE TABLE Product_Constraints (
    ProductID INT IDENTITY(1,1),
    SKU VARCHAR(50),
    ProductName NVARCHAR(200),
    Price DECIMAL(10,2),
    Quantity INT
);
GO

-- Step 2: Insert data (some violating)
INSERT INTO Product_Constraints (SKU, ProductName, Price, Quantity)
VALUES 
    ('SKU-001', 'Laptop', 999.99, 50),      -- Valid
    ('SKU-002', 'Mouse', -10.00, 100),      -- Invalid price
    ('SKU-001', 'Keyboard', 79.99, -5),     -- Duplicate SKU, invalid quantity
    (NULL, 'Monitor', 299.99, 75),          -- NULL SKU
    ('SKU-003', NULL, 149.99, 100);         -- NULL name
GO

-- Step 3: Fix violations before adding constraints

-- Fix negative prices
UPDATE Product_Constraints SET Price = ABS(Price) WHERE Price < 0;

-- Fix negative quantities
UPDATE Product_Constraints SET Quantity = 0 WHERE Quantity < 0;

-- Fix NULL SKUs
UPDATE Product_Constraints SET SKU = 'UNK-' + CAST(ProductID AS VARCHAR(10)) WHERE SKU IS NULL;

-- Fix duplicate SKUs
UPDATE Product_Constraints 
SET SKU = SKU + '-' + CAST(ProductID AS VARCHAR(10))
WHERE ProductID IN (
    SELECT ProductID 
    FROM Product_Constraints p1
    WHERE EXISTS (
        SELECT 1 FROM Product_Constraints p2 
        WHERE p1.SKU = p2.SKU AND p1.ProductID > p2.ProductID
    )
);

-- Fix NULL names
UPDATE Product_Constraints SET ProductName = 'Unknown Product' WHERE ProductName IS NULL;
GO

-- Step 4: Add constraints
ALTER TABLE Product_Constraints
ADD CONSTRAINT PK_Product_Constraints PRIMARY KEY (ProductID);

ALTER TABLE Product_Constraints
ADD CONSTRAINT UQ_Product_Constraints_SKU UNIQUE (SKU);

ALTER TABLE Product_Constraints
ALTER COLUMN ProductName NVARCHAR(200) NOT NULL;

ALTER TABLE Product_Constraints
ALTER COLUMN SKU VARCHAR(50) NOT NULL;

ALTER TABLE Product_Constraints
ADD CONSTRAINT CK_Product_Constraints_Price CHECK (Price >= 0);

ALTER TABLE Product_Constraints
ADD CONSTRAINT CK_Product_Constraints_Quantity CHECK (Quantity >= 0);
GO

-- SOLUTION 3.3 (20 points)
DROP TABLE IF EXISTS TestConstraints;
GO

-- Step 1: Create with constraints
CREATE TABLE TestConstraints (
    ID INT PRIMARY KEY,
    Value INT NOT NULL,
    Status VARCHAR(20),
    Amount DECIMAL(10,2),
    CONSTRAINT CK_TestConstraints_Value CHECK (Value > 0),
    CONSTRAINT CK_TestConstraints_Amount CHECK (Amount >= 0)
);
GO

-- Step 2: Disable constraints
ALTER TABLE TestConstraints NOCHECK CONSTRAINT ALL;
GO

-- Step 3: Insert violating data
INSERT INTO TestConstraints (ID, Value, Status, Amount)
VALUES 
    (1, 100, 'Valid', 50.00),
    (2, -50, 'Invalid', 100.00),
    (3, 75, 'Invalid', -25.00),
    (4, -10, 'Invalid', -15.00);
GO

-- Step 4: Identify violations
SELECT 
    ID, 
    Value, 
    Amount,
    CASE 
        WHEN Value <= 0 AND Amount < 0 THEN 'Both invalid'
        WHEN Value <= 0 THEN 'Invalid Value'
        WHEN Amount < 0 THEN 'Invalid Amount'
        ELSE 'Valid'
    END AS ViolationType
FROM TestConstraints
WHERE Value <= 0 OR Amount < 0;
GO

-- Step 5: Fix violations
UPDATE TestConstraints SET Value = ABS(Value) WHERE Value <= 0;
UPDATE TestConstraints SET Amount = ABS(Amount) WHERE Amount < 0;
GO

-- Step 6: Re-enable with validation
ALTER TABLE TestConstraints WITH CHECK CHECK CONSTRAINT ALL;
GO

-- Step 7: Show all constraints
SELECT 
    name AS ConstraintName,
    type_desc AS ConstraintType,
    is_disabled AS IsDisabled,
    is_not_trusted AS IsNotTrusted
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('TestConstraints')
    AND type IN ('PK', 'C')
ORDER BY type_desc;
GO

-- SOLUTION 3.4 (15 points)
DROP TABLE IF EXISTS ValidationDemo;
GO

CREATE TABLE ValidationDemo (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100),
    Phone VARCHAR(20),
    StartDate DATE,
    EndDate DATE,
    ProductCategory VARCHAR(20),
    Price DECIMAL(10,2)
);
GO

-- Email format validation
ALTER TABLE ValidationDemo
ADD CONSTRAINT CK_ValidationDemo_Email 
CHECK (Email LIKE '%_@__%.__%');
GO

-- Phone format validation
ALTER TABLE ValidationDemo
ADD CONSTRAINT CK_ValidationDemo_Phone 
CHECK (Phone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]');
GO

-- Date range validation
ALTER TABLE ValidationDemo
ADD CONSTRAINT CK_ValidationDemo_DateRange 
CHECK (EndDate > StartDate);
GO

-- Price range by category
ALTER TABLE ValidationDemo
ADD CONSTRAINT CK_ValidationDemo_PriceRange 
CHECK (
    (ProductCategory = 'Electronics' AND Price BETWEEN 10 AND 10000) OR
    (ProductCategory = 'Clothing' AND Price BETWEEN 5 AND 500) OR
    (ProductCategory = 'Food' AND Price BETWEEN 1 AND 100) OR
    (ProductCategory NOT IN ('Electronics', 'Clothing', 'Food'))
);
GO

-- Test valid data
INSERT INTO ValidationDemo (ID, Email, Phone, StartDate, EndDate, ProductCategory, Price)
VALUES (1, 'test@example.com', '555-123-4567', '2024-01-01', '2024-01-31', 'Electronics', 999.99);
GO

-- Test invalid email
BEGIN TRY
    INSERT INTO ValidationDemo (ID, Email) VALUES (2, 'invalid-email');
END TRY
BEGIN CATCH
    PRINT 'Email validation failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test invalid phone
BEGIN TRY
    INSERT INTO ValidationDemo (ID, Phone) VALUES (3, '1234567890');
END TRY
BEGIN CATCH
    PRINT 'Phone validation failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test invalid date range
BEGIN TRY
    INSERT INTO ValidationDemo (ID, StartDate, EndDate) 
    VALUES (4, '2024-01-31', '2024-01-01');
END TRY
BEGIN CATCH
    PRINT 'Date range validation failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test invalid price for category
BEGIN TRY
    INSERT INTO ValidationDemo (ID, ProductCategory, Price) 
    VALUES (5, 'Electronics', 5.00);  -- Too cheap for electronics
END TRY
BEGIN CATCH
    PRINT 'Price range validation failed: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
================================================================================
NOTE: Solutions for Sections 4-7 are conceptually similar to previous solutions.
      The key is demonstrating understanding of:
      - Index maintenance procedures
      - DMV queries
      - Performance measurement
      - Real-world application

For a complete solution guide, refer to the individual lesson files.

GRADING YOUR TEST:
------------------
Award yourself points based on:
- Correctness of SQL syntax (40%)
- Completeness of solution (30%)
- Understanding of concepts (20%)
- Best practices applied (10%)

Total your score and review areas where you scored < 70%.
================================================================================
*/

PRINT 'Test completed! Grade yourself honestly and review weak areas.';
PRINT 'Chapter 13 complete - ready for Chapter 14: Views!';
GO

/*
================================================================================
CONGRATULATIONS!
================================================================================

You've completed Chapter 13: Indexes and Constraints!

KEY SKILLS MASTERED:
--------------------
✓ Index fundamentals (clustered vs nonclustered)
✓ Creating effective indexes
✓ Designing index strategies
✓ Implementing all constraint types
✓ Managing and maintaining indexes
✓ Advanced index types
✓ Performance optimization
✓ Real-world application

NEXT CHAPTER:
-------------
Chapter 14: Views
- Creating and using views
- Updatable views
- Indexed views
- Partitioned views
- Security with views

Continue your SQL mastery!
================================================================================
*/
