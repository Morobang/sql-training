/*
============================================================================
Lesson 11.01 - What is Conditional Logic
============================================================================

Description:
Introduction to conditional logic in SQL. Understand why conditional logic
is essential, explore different approaches, and learn when to apply CASE
expressions, COALESCE, NULLIF, and other conditional techniques.

Topics Covered:
• What is conditional logic
• Why use conditional logic in SQL
• CASE expression overview
• Alternative functions (COALESCE, NULLIF, IIF)
• Real-world applications
• When to use conditional logic

Prerequisites:
• Chapters 1-10
• Basic SELECT queries

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Conditional Logic
============================================================================
*/

/*
CONDITIONAL LOGIC Definition:
The ability to return different values or execute different logic based on
conditions being true or false.

In SQL:
• IF-THEN-ELSE logic within queries
• Different results based on data values
• Dynamic behavior based on conditions
• Business rule implementation
*/

-- Example 1.1: Without conditional logic (limited)
SELECT 
    ProductName,
    Price
FROM Products
WHERE ProductID <= 5;
-- Returns raw data, no interpretation

-- Example 1.2: With conditional logic (meaningful)
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
WHERE ProductID <= 5;
-- Adds business context to raw numbers

-- Example 1.3: Real-world interpretation
SELECT 
    CustomerName,
    Country,
    CASE Country
        WHEN 'USA' THEN 'Domestic'
        WHEN 'Canada' THEN 'North America'
        WHEN 'Mexico' THEN 'North America'
        ELSE 'International'
    END AS CustomerRegion
FROM Customers
WHERE CustomerID <= 10;


/*
============================================================================
PART 2: Why Use Conditional Logic
============================================================================
*/

-- Reason 2.1: Data Categorization
-- Transform continuous data into categories
SELECT 
    OrderID,
    TotalAmount,
    CASE 
        WHEN TotalAmount < 100 THEN 'Small'
        WHEN TotalAmount < 500 THEN 'Medium'
        WHEN TotalAmount < 1000 THEN 'Large'
        ELSE 'Extra Large'
    END AS OrderSize
FROM Orders
WHERE OrderID <= 10;

-- Reason 2.2: Status Determination
-- Calculate status based on multiple fields
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    CASE 
        WHEN ShipDate IS NULL THEN 'Pending'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) <= 1 THEN 'Fast'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) <= 3 THEN 'Normal'
        ELSE 'Slow'
    END AS ShippingSpeed
FROM Orders
WHERE OrderID <= 10;

-- Reason 2.3: Data Transformation
-- Convert codes to meaningful descriptions
SELECT 
    ProductID,
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

-- Reason 2.4: Business Rule Implementation
-- Apply complex business logic
SELECT 
    CustomerID,
    Country,
    TotalAmount,
    CASE 
        WHEN Country = 'USA' AND TotalAmount > 1000 THEN TotalAmount * 0.95  -- 5% discount
        WHEN Country = 'USA' AND TotalAmount > 500 THEN TotalAmount * 0.97   -- 3% discount
        WHEN Country IN ('Canada', 'Mexico') THEN TotalAmount * 0.98         -- 2% discount
        ELSE TotalAmount                                                      -- No discount
    END AS FinalAmount
FROM Orders
WHERE OrderID <= 10;

-- Reason 2.5: Safe Calculations
-- Prevent errors (division by zero, NULL handling)
SELECT 
    ProductID,
    ProductName,
    CASE 
        WHEN UnitsInStock = 0 THEN 'Out of Stock'
        WHEN UnitsInStock < 10 THEN 'Low Stock'
        WHEN UnitsInStock < 50 THEN 'Available'
        ELSE 'In Stock'
    END AS StockStatus
FROM Products
WHERE ProductID <= 10;


/*
============================================================================
PART 3: CASE Expression Overview
============================================================================
*/

/*
CASE Expression - Two Formats:

1. SEARCHED CASE (Most Flexible):
   CASE
       WHEN condition1 THEN result1
       WHEN condition2 THEN result2
       ELSE default_result
   END

2. SIMPLE CASE (Equality Only):
   CASE expression
       WHEN value1 THEN result1
       WHEN value2 THEN result2
       ELSE default_result
   END
*/

-- Example 3.1: Searched CASE (Complex Conditions)
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 200 THEN 'Expensive'
        WHEN Price > 100 THEN 'Moderate'
        WHEN Price > 50 THEN 'Affordable'
        ELSE 'Budget'
    END AS PriceRange
FROM Products
WHERE ProductID <= 5;

-- Example 3.2: Simple CASE (Equality Checks)
SELECT 
    ProductName,
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 'Category One'
        WHEN 2 THEN 'Category Two'
        WHEN 3 THEN 'Category Three'
        ELSE 'Other Category'
    END AS CategoryDescription
FROM Products
WHERE ProductID <= 5;

-- Example 3.3: CASE in Different Clauses
-- In SELECT:
SELECT 
    OrderID,
    CASE 
        WHEN TotalAmount > 500 THEN 'Large Order'
        ELSE 'Regular Order'
    END AS OrderType
FROM Orders
WHERE OrderID <= 5;

-- In WHERE:
SELECT 
    OrderID,
    TotalAmount
FROM Orders
WHERE CASE 
        WHEN YEAR(OrderDate) = 2024 THEN TotalAmount
        ELSE 0
      END > 100;

-- In ORDER BY:
SELECT 
    ProductName,
    Price
FROM Products
ORDER BY 
    CASE 
        WHEN Price IS NULL THEN 1
        ELSE 0
    END,
    Price;


/*
============================================================================
PART 4: Alternative Conditional Functions
============================================================================
*/

-- Function 4.1: COALESCE (Return First Non-NULL)
SELECT 
    ProductName,
    Price,
    COALESCE(Price, 0) AS PriceOrZero,
    COALESCE(Price, 100) AS PriceOr100
FROM Products
WHERE ProductID <= 5;

-- Equivalent with CASE:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NOT NULL THEN Price
        ELSE 0
    END AS PriceOrZero
FROM Products
WHERE ProductID <= 5;

-- Function 4.2: NULLIF (Return NULL if Equal)
SELECT 
    ProductID,
    UnitsInStock,
    NULLIF(UnitsInStock, 0) AS StockOrNull
FROM Products
WHERE ProductID <= 5;
-- Use case: Prevent division by zero

-- Equivalent with CASE:
SELECT 
    ProductID,
    UnitsInStock,
    CASE 
        WHEN UnitsInStock = 0 THEN NULL
        ELSE UnitsInStock
    END AS StockOrNull
FROM Products
WHERE ProductID <= 5;

-- Function 4.3: IIF (SQL Server - Simple IF-THEN-ELSE)
SELECT 
    ProductName,
    Price,
    IIF(Price > 100, 'Expensive', 'Affordable') AS PriceCategory
FROM Products
WHERE ProductID <= 5;

-- Equivalent with CASE:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 5;

-- Function 4.4: ISNULL (SQL Server - Replace NULL)
SELECT 
    ProductName,
    Price,
    ISNULL(Price, 0) AS PriceOrZero
FROM Products
WHERE ProductID <= 5;

-- Note: COALESCE is ANSI standard, ISNULL is SQL Server-specific


/*
============================================================================
PART 5: When to Use Each Approach
============================================================================
*/

/*
DECISION TREE:

Need to check multiple conditions?
├─ YES → Use CASE
└─ NO → Continue...

Just replacing NULL?
├─ YES → Use COALESCE or ISNULL
└─ NO → Continue...

Preventing division by zero?
├─ YES → Use NULLIF or CASE
└─ NO → Continue...

Simple true/false condition?
├─ YES → Use IIF (SQL Server) or CASE
└─ NO → Use CASE
*/

-- Scenario 5.1: Multiple Conditions → CASE
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 200 THEN 'Premium'
        WHEN Price > 100 THEN 'Standard'
        WHEN Price > 50 THEN 'Economy'
        ELSE 'Budget'
    END AS Tier
FROM Products
WHERE ProductID <= 5;

-- Scenario 5.2: Simple NULL Replacement → COALESCE
SELECT 
    ProductName,
    COALESCE(DiscountPercent, 0) AS Discount
FROM Products
WHERE ProductID <= 5;

-- Scenario 5.3: Division by Zero → NULLIF
SELECT 
    OrderID,
    TotalAmount,
    ItemCount,
    TotalAmount / NULLIF(ItemCount, 0) AS AvgItemPrice
FROM Orders
WHERE OrderID <= 5;

-- Scenario 5.4: Simple Condition → IIF
SELECT 
    ProductName,
    IIF(InStock = 1, 'Available', 'Out of Stock') AS Availability
FROM Products
WHERE ProductID <= 5;


/*
============================================================================
PART 6: Real-World Applications
============================================================================
*/

-- Application 6.1: Customer Segmentation
SELECT 
    CustomerID,
    CustomerName,
    CASE 
        WHEN TotalOrders >= 10 THEN 'VIP'
        WHEN TotalOrders >= 5 THEN 'Regular'
        WHEN TotalOrders >= 1 THEN 'New'
        ELSE 'Inactive'
    END AS CustomerSegment
FROM (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS TotalOrders
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
) AS CustomerStats;

-- Application 6.2: Dynamic Pricing
SELECT 
    ProductName,
    Price AS OriginalPrice,
    CASE 
        WHEN CategoryID = 1 THEN Price * 0.90  -- 10% off electronics
        WHEN CategoryID = 2 THEN Price * 0.85  -- 15% off clothing
        WHEN Price > 200 THEN Price * 0.95     -- 5% off expensive items
        ELSE Price
    END AS SalePrice
FROM Products
WHERE ProductID <= 10;

-- Application 6.3: Order Status
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered'
        WHEN ShipDate IS NOT NULL THEN 'Shipped'
        WHEN OrderDate IS NOT NULL THEN 'Processing'
        ELSE 'Unknown'
    END AS OrderStatus
FROM Orders
WHERE OrderID <= 10;

-- Application 6.4: Grade Calculation
CREATE TABLE #StudentScores (
    StudentID INT,
    StudentName VARCHAR(50),
    Score INT
);

INSERT INTO #StudentScores VALUES
(1, 'Alice', 95),
(2, 'Bob', 87),
(3, 'Charlie', 76),
(4, 'David', 68),
(5, 'Eve', 54);

SELECT 
    StudentName,
    Score,
    CASE 
        WHEN Score >= 90 THEN 'A'
        WHEN Score >= 80 THEN 'B'
        WHEN Score >= 70 THEN 'C'
        WHEN Score >= 60 THEN 'D'
        ELSE 'F'
    END AS Grade
FROM #StudentScores;

DROP TABLE #StudentScores;


/*
============================================================================
PART 7: Benefits and Limitations
============================================================================
*/

/*
BENEFITS:
✓ Cleaner queries (avoid multiple UNION queries)
✓ Single pass through data
✓ Flexible business logic
✓ Readable and maintainable
✓ Can be used in any clause
✓ Type-safe results

LIMITATIONS:
✗ Can become complex with deep nesting
✗ Not a substitute for proper data modeling
✗ May impact performance with complex conditions
✗ All results must be compatible data types
✗ NULL is default ELSE if not specified
*/

-- Benefit Example: Single Query vs Multiple Queries
-- Without CASE (Multiple queries + UNION):
/*
SELECT ProductName, 'Budget' AS Category
FROM Products WHERE Price < 50
UNION ALL
SELECT ProductName, 'Standard'
FROM Products WHERE Price >= 50 AND Price < 100
UNION ALL
SELECT ProductName, 'Premium'
FROM Products WHERE Price >= 100;
*/

-- With CASE (Single query, cleaner):
SELECT 
    ProductName,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS Category
FROM Products;

-- Limitation Example: Data Type Compatibility
-- ❌ This will error (mixed types):
/*
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE Price  -- Error: VARCHAR vs DECIMAL
    END
FROM Products;
*/

-- ✅ This works (consistent types):
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE CAST(Price AS VARCHAR(20))
    END AS PriceInfo
FROM Products
WHERE ProductID <= 5;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a query that categorizes orders as 'Q1', 'Q2', 'Q3', or 'Q4' based on order month
2. Write a query showing customer risk level based on order count
3. Use COALESCE to handle NULL prices with a default of 99.99
4. Create a status field: 'New' if order < 30 days old, 'Old' otherwise
5. Use NULLIF to prevent division by zero when calculating average order value

Solutions below ↓
*/

-- Solution 1:
SELECT 
    OrderID,
    OrderDate,
    CASE 
        WHEN MONTH(OrderDate) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(OrderDate) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(OrderDate) BETWEEN 7 AND 9 THEN 'Q3'
        WHEN MONTH(OrderDate) BETWEEN 10 AND 12 THEN 'Q4'
    END AS Quarter
FROM Orders
WHERE OrderID <= 20;

-- Solution 2:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    CASE 
        WHEN COUNT(o.OrderID) = 0 THEN 'High Risk - No Orders'
        WHEN COUNT(o.OrderID) < 3 THEN 'Medium Risk - Few Orders'
        WHEN COUNT(o.OrderID) < 10 THEN 'Low Risk - Regular Customer'
        ELSE 'No Risk - Loyal Customer'
    END AS RiskLevel
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Solution 3:
SELECT 
    ProductName,
    Price AS OriginalPrice,
    COALESCE(Price, 99.99) AS PriceWithDefault
FROM Products
WHERE ProductID <= 10;

-- Solution 4:
SELECT 
    OrderID,
    OrderDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysOld,
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) < 30 THEN 'New'
        ELSE 'Old'
    END AS OrderAge
FROM Orders
WHERE OrderID <= 20;

-- Solution 5:
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSpent,
    COUNT(OrderID) AS OrderCount,
    SUM(TotalAmount) / NULLIF(COUNT(OrderID), 0) AS AvgOrderValue
FROM Orders
GROUP BY CustomerID;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CONDITIONAL LOGIC:
  • IF-THEN-ELSE logic in SQL queries
  • Makes data meaningful
  • Implements business rules
  • Transforms raw data

✓ CASE EXPRESSION:
  • Primary tool for conditional logic
  • Two formats: Searched and Simple
  • Can be used in any clause
  • Returns consistent data types

✓ ALTERNATIVE FUNCTIONS:
  • COALESCE: First non-NULL value
  • NULLIF: Return NULL if equal
  • IIF: Simple IF-THEN-ELSE (SQL Server)
  • ISNULL: Replace NULL (SQL Server)

✓ WHEN TO USE:
  • Multiple conditions → CASE
  • NULL replacement → COALESCE
  • Division by zero → NULLIF
  • Simple condition → IIF or CASE

✓ BENEFITS:
  • Cleaner queries
  • Single data pass
  • Flexible logic
  • Maintainable code

✓ BEST PRACTICES:
  • Use appropriate function for task
  • Keep CASE expressions simple
  • Always include ELSE clause
  • Ensure data type consistency
  • Comment complex logic

✓ REAL-WORLD USES:
  • Customer segmentation
  • Status determination
  • Data categorization
  • Dynamic pricing
  • Error prevention

============================================================================
NEXT: Lesson 11.02 - CASE Expression
Deep dive into CASE expression syntax and usage.
============================================================================
*/
