/*
============================================================================
Lesson 11.04 - Simple CASE Expressions
============================================================================

Description:
Learn the concise equality-based CASE format. Master when to use simple
CASE vs searched CASE, understand limitations, and learn conversion
techniques between the two formats.

Topics Covered:
• Simple CASE syntax
• Equality matching only
• When to use simple vs searched
• Converting between formats
• Limitations and workarounds
• Performance considerations

Prerequisites:
• Lessons 11.01-11.03

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Simple CASE Syntax
============================================================================
*/

/*
SIMPLE CASE Format:

CASE test_expression
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    [WHEN valueN THEN resultN]
    [ELSE else_result]
END

Key Features:
• Tests ONE expression for equality
• Each WHEN compares to a specific value
• More concise than searched CASE
• Limited to equality (=) comparisons only
*/

-- Example 1.1: Basic Simple CASE
SELECT 
    ProductName,
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        WHEN 3 THEN 'Food'
        WHEN 4 THEN 'Books'
        ELSE 'Other'
    END AS CategoryName
FROM Products
WHERE ProductID <= 10;

-- Example 1.2: Status Code Translation
SELECT 
    OrderID,
    Status,
    CASE Status
        WHEN 'P' THEN 'Pending'
        WHEN 'S' THEN 'Shipped'
        WHEN 'D' THEN 'Delivered'
        WHEN 'C' THEN 'Cancelled'
        ELSE 'Unknown'
    END AS StatusDescription
FROM Orders
WHERE OrderID <= 10;

-- Example 1.3: Numeric Value Mapping
SELECT 
    CustomerID,
    CustomerName,
    CustomerType,
    CASE CustomerType
        WHEN 1 THEN 'Retail'
        WHEN 2 THEN 'Wholesale'
        WHEN 3 THEN 'Corporate'
        ELSE 'Unknown Type'
    END AS TypeDescription
FROM Customers
WHERE CustomerID <= 10;


/*
============================================================================
PART 2: Simple vs Searched CASE
============================================================================
*/

-- Comparison 2.1: Same Result, Different Syntax
-- Simple CASE:
SELECT 
    ProductName,
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        WHEN 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Equivalent Searched CASE:
SELECT 
    ProductName,
    CategoryID,
    CASE 
        WHEN CategoryID = 1 THEN 'Electronics'
        WHEN CategoryID = 2 THEN 'Clothing'
        WHEN CategoryID = 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Comparison 2.2: When Simple CASE Works
-- ✅ Perfect for simple CASE (one column, equality):
SELECT 
    CustomerName,
    Country,
    CASE Country
        WHEN 'USA' THEN 'United States'
        WHEN 'UK' THEN 'United Kingdom'
        WHEN 'UAE' THEN 'United Arab Emirates'
        ELSE Country
    END AS CountryFullName
FROM Customers
WHERE CustomerID <= 10;

-- Comparison 2.3: When Searched CASE is Required
-- ❌ Cannot use simple CASE (ranges, not equality):
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        WHEN Price < 200 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 10;

-- ❌ Cannot use simple CASE (different columns):
SELECT 
    OrderID,
    CASE 
        WHEN TotalAmount > 1000 THEN 'Large Order'
        WHEN CustomerID IN (1, 2, 3) THEN 'VIP Customer'
        ELSE 'Standard'
    END AS OrderType
FROM Orders
WHERE OrderID <= 10;


/*
============================================================================
PART 3: When to Use Simple CASE
============================================================================
*/

-- Use Case 3.1: ✅ Status Code Mapping
CREATE TABLE #OrderStatus (
    OrderID INT,
    StatusCode CHAR(1)
);

INSERT INTO #OrderStatus VALUES
(1, 'N'), (2, 'P'), (3, 'S'), (4, 'D'), (5, 'C');

SELECT 
    OrderID,
    StatusCode,
    CASE StatusCode
        WHEN 'N' THEN 'New'
        WHEN 'P' THEN 'Processing'
        WHEN 'S' THEN 'Shipped'
        WHEN 'D' THEN 'Delivered'
        WHEN 'C' THEN 'Cancelled'
        ELSE 'Unknown'
    END AS Status
FROM #OrderStatus;

DROP TABLE #OrderStatus;

-- Use Case 3.2: ✅ Category Translation
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'CAT-ELEC'
        WHEN 2 THEN 'CAT-CLOTH'
        WHEN 3 THEN 'CAT-FOOD'
        WHEN 4 THEN 'CAT-BOOKS'
        ELSE 'CAT-OTHER'
    END AS CategoryCode
FROM Products
WHERE ProductID <= 10;

-- Use Case 3.3: ✅ Fixed Value Lists
SELECT 
    CustomerName,
    CASE Country
        WHEN 'USA' THEN 'North America'
        WHEN 'Canada' THEN 'North America'
        WHEN 'Mexico' THEN 'North America'
        WHEN 'UK' THEN 'Europe'
        WHEN 'France' THEN 'Europe'
        WHEN 'Germany' THEN 'Europe'
        ELSE 'Other Region'
    END AS Region
FROM Customers
WHERE CustomerID <= 15;

-- Use Case 3.4: ✅ Day of Week Names
SELECT 
    OrderID,
    OrderDate,
    DATEPART(WEEKDAY, OrderDate) AS DayNumber,
    CASE DATEPART(WEEKDAY, OrderDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS DayName
FROM Orders
WHERE OrderID <= 10;


/*
============================================================================
PART 4: Limitations of Simple CASE
============================================================================
*/

-- Limitation 4.1: ❌ Cannot Use Ranges
-- This doesn't work with simple CASE:
/*
CASE Price
    WHEN < 50 THEN 'Budget'  -- Syntax error!
    WHEN < 100 THEN 'Standard'
    ...
*/

-- Must use searched CASE:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 5;

-- Limitation 4.2: ❌ Cannot Use Comparison Operators
-- Simple CASE only supports equality (=)
-- Cannot use: <, >, <=, >=, <>, BETWEEN, LIKE, IN, etc.

-- ❌ Won't work:
/*
CASE ProductName
    WHEN LIKE 'Pro%' THEN 'Professional'  -- Syntax error!
    ...
*/

-- ✅ Must use searched CASE:
SELECT 
    ProductName,
    CASE 
        WHEN ProductName LIKE 'Pro%' THEN 'Professional'
        WHEN ProductName LIKE '%Plus%' THEN 'Plus Edition'
        ELSE 'Standard'
    END AS ProductLine
FROM Products
WHERE ProductID <= 10;

-- Limitation 4.3: ❌ Cannot Check Multiple Columns
-- Simple CASE tests ONE expression only

-- ❌ Can't do this:
/*
CASE
    WHEN CategoryID = 1 AND Price > 100 THEN ...  -- Need searched CASE
*/

-- ✅ Must use searched CASE:
SELECT 
    ProductName,
    CASE 
        WHEN CategoryID = 1 AND Price > 100 THEN 'Premium Electronics'
        WHEN CategoryID = 2 AND Price > 50 THEN 'Designer Clothing'
        ELSE 'Standard Product'
    END AS ProductType
FROM Products
WHERE ProductID <= 10;

-- Limitation 4.4: ❌ Cannot Use NULL Directly
-- Simple CASE uses = operator, which doesn't work with NULL

-- ❌ This won't catch NULL:
SELECT 
    ProductName,
    Price,
    CASE Price
        WHEN NULL THEN 'No Price'  -- This never matches!
        WHEN 0 THEN 'Free'
        ELSE 'Has Price'
    END AS PriceStatus
FROM Products
WHERE ProductID <= 5;

-- ✅ Use searched CASE for NULL:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'No Price'
        WHEN Price = 0 THEN 'Free'
        ELSE 'Has Price'
    END AS PriceStatus
FROM Products
WHERE ProductID <= 5;


/*
============================================================================
PART 5: Converting Between Formats
============================================================================
*/

-- Conversion 5.1: Simple → Searched (Always Possible)
-- Simple CASE:
SELECT 
    Country,
    CASE Country
        WHEN 'USA' THEN 'United States'
        WHEN 'UK' THEN 'United Kingdom'
        ELSE Country
    END AS CountryName
FROM Customers
WHERE CustomerID <= 5;

-- Converted to Searched CASE:
SELECT 
    Country,
    CASE 
        WHEN Country = 'USA' THEN 'United States'
        WHEN Country = 'UK' THEN 'United Kingdom'
        ELSE Country
    END AS CountryName
FROM Customers
WHERE CustomerID <= 5;

-- Conversion 5.2: Searched → Simple (Only If Equality)
-- Searched CASE (can convert):
SELECT 
    CategoryID,
    CASE 
        WHEN CategoryID = 1 THEN 'Electronics'
        WHEN CategoryID = 2 THEN 'Clothing'
        WHEN CategoryID = 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Converted to Simple CASE:
SELECT 
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        WHEN 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Conversion 5.3: Searched → Simple (Cannot Convert)
-- Searched CASE with ranges (can't convert):
SELECT 
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 5;
-- No simple CASE equivalent


/*
============================================================================
PART 6: Performance Considerations
============================================================================
*/

-- Performance 6.1: Simple CASE is Slightly Faster
-- For equality checks, simple CASE can be marginally faster
SET STATISTICS TIME ON;

-- Simple CASE:
SELECT 
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        WHEN 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products;

-- Searched CASE (same result):
SELECT 
    CategoryID,
    CASE 
        WHEN CategoryID = 1 THEN 'Electronics'
        WHEN CategoryID = 2 THEN 'Clothing'
        WHEN CategoryID = 3 THEN 'Food'
        ELSE 'Other'
    END AS Category
FROM Products;

SET STATISTICS TIME OFF;
-- Difference is negligible in most cases

-- Performance 6.2: ✅ Readability Often More Important
-- Simple CASE is more concise and readable for equality checks
-- Choose based on readability, not micro-optimization


/*
============================================================================
PART 7: Real-World Examples
============================================================================
*/

-- Example 7.1: Month Number to Name
SELECT 
    OrderID,
    OrderDate,
    MONTH(OrderDate) AS MonthNumber,
    CASE MONTH(OrderDate)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS MonthName
FROM Orders
WHERE OrderID <= 20;

-- Example 7.2: Priority Mapping
CREATE TABLE #TaskPriority (
    TaskID INT,
    PriorityCode INT
);

INSERT INTO #TaskPriority VALUES
(1, 1), (2, 2), (3, 3), (4, 1), (5, 4);

SELECT 
    TaskID,
    PriorityCode,
    CASE PriorityCode
        WHEN 1 THEN 'Critical'
        WHEN 2 THEN 'High'
        WHEN 3 THEN 'Medium'
        WHEN 4 THEN 'Low'
        ELSE 'Undefined'
    END AS Priority,
    CASE PriorityCode
        WHEN 1 THEN 'Within 24 hours'
        WHEN 2 THEN 'Within 3 days'
        WHEN 3 THEN 'Within 1 week'
        WHEN 4 THEN 'When possible'
        ELSE 'No timeline'
    END AS Timeline
FROM #TaskPriority;

DROP TABLE #TaskPriority;

-- Example 7.3: Size Code Translation
CREATE TABLE #ProductSizes (
    ProductID INT,
    SizeCode VARCHAR(5)
);

INSERT INTO #ProductSizes VALUES
(1, 'XS'), (2, 'S'), (3, 'M'), (4, 'L'), (5, 'XL'), (6, 'XXL');

SELECT 
    ProductID,
    SizeCode,
    CASE SizeCode
        WHEN 'XS' THEN 'Extra Small'
        WHEN 'S' THEN 'Small'
        WHEN 'M' THEN 'Medium'
        WHEN 'L' THEN 'Large'
        WHEN 'XL' THEN 'Extra Large'
        WHEN 'XXL' THEN 'Double Extra Large'
        ELSE SizeCode
    END AS SizeName,
    CASE SizeCode
        WHEN 'XS' THEN 1
        WHEN 'S' THEN 2
        WHEN 'M' THEN 3
        WHEN 'L' THEN 4
        WHEN 'XL' THEN 5
        WHEN 'XXL' THEN 6
        ELSE 0
    END AS SizeOrder
FROM #ProductSizes
ORDER BY SizeOrder;

DROP TABLE #ProductSizes;

-- Example 7.4: Grade to GPA Conversion
CREATE TABLE #StudentGrades (
    StudentID INT,
    Grade CHAR(2)
);

INSERT INTO #StudentGrades VALUES
(1, 'A'), (2, 'A-'), (3, 'B+'), (4, 'B'), (5, 'C'), (6, 'D'), (7, 'F');

SELECT 
    StudentID,
    Grade,
    CASE Grade
        WHEN 'A' THEN 4.0
        WHEN 'A-' THEN 3.7
        WHEN 'B+' THEN 3.3
        WHEN 'B' THEN 3.0
        WHEN 'B-' THEN 2.7
        WHEN 'C+' THEN 2.3
        WHEN 'C' THEN 2.0
        WHEN 'C-' THEN 1.7
        WHEN 'D+' THEN 1.3
        WHEN 'D' THEN 1.0
        WHEN 'F' THEN 0.0
        ELSE NULL
    END AS GPA
FROM #StudentGrades;

DROP TABLE #StudentGrades;


/*
============================================================================
PART 8: Decision Guide
============================================================================
*/

/*
USE SIMPLE CASE WHEN:
✓ Checking ONE column/expression
✓ All conditions are equality (=)
✓ Comparing to specific values
✓ Code mapping (status codes, categories)
✓ Readability is priority

USE SEARCHED CASE WHEN:
✓ Need ranges (>, <, BETWEEN)
✓ Multiple columns involved
✓ Complex conditions (AND, OR)
✓ NULL checking required
✓ Pattern matching (LIKE)
✓ Using IN, EXISTS, etc.
✓ Need flexibility

GENERAL RULE:
If you CAN use simple CASE, consider it for conciseness.
If you NEED complexity, use searched CASE.
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Write simple CASE converting numeric quarter (1-4) to Q1, Q2, Q3, Q4
2. Create simple CASE mapping department codes (HR, IT, FIN, OPS) to names
3. Convert a simple CASE to searched CASE format
4. Try to write a range check with simple CASE (it won't work), then use searched
5. Map day of week numbers to weekend/weekday status

Solutions below ↓
*/

-- Solution 1:
SELECT 
    OrderID,
    OrderDate,
    DATEPART(QUARTER, OrderDate) AS QuarterNum,
    CASE DATEPART(QUARTER, OrderDate)
        WHEN 1 THEN 'Q1'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4'
    END AS Quarter
FROM Orders
WHERE OrderID <= 20;

-- Solution 2:
CREATE TABLE #Employees (
    EmployeeID INT,
    DeptCode VARCHAR(10)
);

INSERT INTO #Employees VALUES
(1, 'HR'), (2, 'IT'), (3, 'FIN'), (4, 'OPS'), (5, 'MKT');

SELECT 
    EmployeeID,
    DeptCode,
    CASE DeptCode
        WHEN 'HR' THEN 'Human Resources'
        WHEN 'IT' THEN 'Information Technology'
        WHEN 'FIN' THEN 'Finance'
        WHEN 'OPS' THEN 'Operations'
        WHEN 'MKT' THEN 'Marketing'
        ELSE 'Unknown Department'
    END AS DepartmentName
FROM #Employees;

DROP TABLE #Employees;

-- Solution 3:
-- Simple CASE:
SELECT 
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Converted to Searched CASE:
SELECT 
    CategoryID,
    CASE 
        WHEN CategoryID = 1 THEN 'Electronics'
        WHEN CategoryID = 2 THEN 'Clothing'
        ELSE 'Other'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- Solution 4:
-- ❌ Simple CASE doesn't work for ranges:
/*
SELECT 
    Price,
    CASE Price
        WHEN < 50 THEN 'Budget'  -- Syntax error!
    ...
*/

-- ✅ Must use Searched CASE:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        WHEN Price < 200 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceRange
FROM Products
WHERE ProductID <= 10;

-- Solution 5:
SELECT 
    OrderID,
    OrderDate,
    DATEPART(WEEKDAY, OrderDate) AS DayNum,
    CASE DATEPART(WEEKDAY, OrderDate)
        WHEN 1 THEN 'Weekend'     -- Sunday
        WHEN 7 THEN 'Weekend'     -- Saturday
        ELSE 'Weekday'
    END AS DayType
FROM Orders
WHERE OrderID <= 20;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SIMPLE CASE SYNTAX:
  • CASE expression WHEN value THEN result
  • Tests ONE expression
  • Equality (=) checks only
  • More concise than searched CASE

✓ WHEN TO USE:
  • Single column/expression
  • Equality comparisons
  • Fixed value lists
  • Code translation
  • Month/day mapping

✓ LIMITATIONS:
  • Equality only (no <, >, BETWEEN, etc.)
  • Cannot check multiple columns
  • Cannot use LIKE, IN with WHEN
  • NULL requires searched CASE
  • No complex conditions

✓ CONVERSION:
  • Simple → Searched: Always possible
  • Searched → Simple: Only if equality
  • Add "= value" for each WHEN

✓ PERFORMANCE:
  • Slightly faster than searched (negligible)
  • Readability more important
  • Choose based on clarity

✓ BEST PRACTICES:
  • Use for simple equality mapping
  • Switch to searched for complexity
  • Always include ELSE clause
  • Keep value list reasonable (<10-15)
  • Consider lookup table for many values

✓ COMMON USES:
  • Status code translation
  • Category mapping
  • Day/month names
  • Priority levels
  • Size codes
  • Grade conversion

============================================================================
NEXT: Lesson 11.05 - CASE Examples
Comprehensive real-world CASE expression examples.
============================================================================
*/
