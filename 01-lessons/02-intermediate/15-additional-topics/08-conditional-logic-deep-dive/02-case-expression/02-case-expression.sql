/*
============================================================================
Lesson 11.02 - CASE Expression
============================================================================

Description:
Deep dive into CASE expression fundamentals. Master the syntax, understand
evaluation order, learn about data types, and explore CASE in different
SQL clauses. Essential foundation for all conditional logic in SQL.

Topics Covered:
• CASE expression syntax (searched and simple)
• Evaluation order and short-circuiting
• Data type consistency
• CASE in SELECT, WHERE, ORDER BY, GROUP BY
• Nesting CASE expressions
• Common patterns and best practices

Prerequisites:
• Lesson 11.01

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: CASE Expression Syntax
============================================================================
*/

/*
TWO FORMATS OF CASE:

1. SEARCHED CASE (Most Common):
   CASE
       WHEN boolean_condition1 THEN result1
       WHEN boolean_condition2 THEN result2
       [WHEN boolean_conditionN THEN resultN]
       [ELSE else_result]
   END

2. SIMPLE CASE (Equality Only):
   CASE test_expression
       WHEN value1 THEN result1
       WHEN value2 THEN result2
       [WHEN valueN THEN resultN]
       [ELSE else_result]
   END
*/

-- Example 1.1: Searched CASE
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'No Price'
        WHEN Price < 50 THEN 'Under $50'
        WHEN Price < 100 THEN '$50-$100'
        WHEN Price < 200 THEN '$100-$200'
        ELSE 'Over $200'
    END AS PriceRange
FROM Products
WHERE ProductID <= 10;

-- Example 1.2: Simple CASE
SELECT 
    CustomerName,
    Country,
    CASE Country
        WHEN 'USA' THEN 'United States'
        WHEN 'UK' THEN 'United Kingdom'
        WHEN 'UAE' THEN 'United Arab Emirates'
        ELSE Country  -- Keep original if not in list
    END AS CountryFull
FROM Customers
WHERE CustomerID <= 10;

-- Example 1.3: CASE is an Expression (not a statement)
-- Returns a VALUE, can be used anywhere a value is expected
SELECT 
    OrderID,
    TotalAmount,
    -- CASE as a column value:
    CASE 
        WHEN TotalAmount > 1000 THEN 'Large'
        ELSE 'Standard'
    END AS OrderSize,
    -- CASE in calculation:
    TotalAmount * CASE 
        WHEN TotalAmount > 1000 THEN 0.9  -- 10% discount
        WHEN TotalAmount > 500 THEN 0.95  -- 5% discount
        ELSE 1.0                           -- No discount
    END AS DiscountedAmount
FROM Orders
WHERE OrderID <= 10;


/*
============================================================================
PART 2: Evaluation Order and Short-Circuiting
============================================================================
*/

/*
EVALUATION RULES:
1. WHEN clauses evaluated TOP to BOTTOM
2. STOPS at FIRST true condition (short-circuit)
3. ELSE executes if NO WHEN is true
4. Returns NULL if no ELSE and no WHEN matches
*/

-- Example 2.1: Order Matters!
SELECT 
    ProductName,
    Price,
    -- ✅ Correct order (specific to general):
    CASE 
        WHEN Price > 200 THEN 'Premium'
        WHEN Price > 100 THEN 'Standard'
        WHEN Price > 50 THEN 'Economy'
        ELSE 'Budget'
    END AS CorrectCategory,
    -- ❌ Wrong order (first condition catches everything):
    CASE 
        WHEN Price > 50 THEN 'Over 50'     -- Catches 51-999!
        WHEN Price > 100 THEN 'Over 100'   -- Never reached
        WHEN Price > 200 THEN 'Over 200'   -- Never reached
        ELSE 'Budget'
    END AS WrongCategory
FROM Products
WHERE ProductID <= 5;

-- Example 2.2: Short-Circuit Evaluation
-- Stops evaluating after first match
SELECT 
    OrderID,
    OrderDate,
    CASE 
        WHEN OrderDate >= DATEADD(DAY, -7, GETDATE()) THEN 'This Week'
        WHEN OrderDate >= DATEADD(DAY, -30, GETDATE()) THEN 'This Month'  -- Only checked if not "This Week"
        WHEN OrderDate >= DATEADD(DAY, -90, GETDATE()) THEN 'This Quarter' -- Only if not month
        ELSE 'Older'
    END AS Recency
FROM Orders
WHERE OrderID <= 10
ORDER BY OrderDate DESC;

-- Example 2.3: Missing ELSE Returns NULL
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        -- No ELSE clause
    END AS Category
FROM Products
WHERE ProductID <= 10;
-- Products under $100 get NULL for Category

-- Example 2.4: Explicit vs Implicit NULL
-- Explicit ELSE:
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE 'Not Expensive'
    END AS Category1
FROM Products
WHERE ProductID <= 3;

-- Implicit NULL (no ELSE):
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
    END AS Category2
FROM Products
WHERE ProductID <= 3;


/*
============================================================================
PART 3: Data Type Consistency
============================================================================
*/

/*
CRITICAL RULE:
All THEN results AND ELSE result must be COMPATIBLE data types.
SQL Server will implicitly convert if possible, but be explicit!
*/

-- Example 3.1: Compatible Types (Works)
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        WHEN Price > 50 THEN 'Moderate'
        ELSE 'Affordable'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 5;
-- All VARCHAR - Compatible

-- Example 3.2: Incompatible Types (Error or Implicit Conversion)
-- ❌ This may error or have unexpected results:
/*
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE Price  -- VARCHAR vs DECIMAL
    END AS Result
FROM Products;
*/

-- ✅ Fix with explicit conversion:
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price > 100 THEN 'Expensive'
        ELSE CAST(Price AS VARCHAR(20))
    END AS PriceInfo
FROM Products
WHERE ProductID <= 5;

-- Example 3.3: Numeric Result Types
SELECT 
    OrderID,
    TotalAmount,
    CASE 
        WHEN TotalAmount > 1000 THEN 1
        WHEN TotalAmount > 500 THEN 0.5
        ELSE 0
    END AS Priority
FROM Orders
WHERE OrderID <= 5;
-- SQL converts all to DECIMAL(3,1)

-- Example 3.4: Date Consistency
SELECT 
    OrderID,
    OrderDate,
    CASE 
        WHEN OrderDate >= '2024-01-01' THEN OrderDate
        ELSE NULL  -- NULL is compatible with any type
    END AS RecentOrderDate
FROM Orders
WHERE OrderID <= 5;


/*
============================================================================
PART 4: CASE in SELECT Clause
============================================================================
*/

-- Usage 4.1: Creating Derived Columns
SELECT 
    ProductID,
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceTier,
    CASE 
        WHEN InStock = 1 THEN 'Available'
        WHEN InStock = 0 THEN 'Out of Stock'
        ELSE 'Unknown'
    END AS Availability
FROM Products
WHERE ProductID <= 10;

-- Usage 4.2: Conditional Aggregation
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN TotalAmount > 500 THEN 1 ELSE 0 END) AS LargeOrders,
    SUM(CASE WHEN TotalAmount <= 500 THEN 1 ELSE 0 END) AS SmallOrders,
    AVG(CASE WHEN TotalAmount > 500 THEN TotalAmount END) AS AvgLargeOrder
FROM Orders;

-- Usage 4.3: Pivoting Data
SELECT 
    CustomerID,
    SUM(CASE WHEN YEAR(OrderDate) = 2023 THEN TotalAmount ELSE 0 END) AS Sales2023,
    SUM(CASE WHEN YEAR(OrderDate) = 2024 THEN TotalAmount ELSE 0 END) AS Sales2024,
    SUM(TotalAmount) AS TotalSales
FROM Orders
GROUP BY CustomerID;


/*
============================================================================
PART 5: CASE in WHERE Clause
============================================================================
*/

-- Usage 5.1: Conditional Filtering
-- Different filter based on condition
SELECT 
    ProductName,
    Price,
    CategoryID
FROM Products
WHERE CASE 
        WHEN CategoryID = 1 THEN Price > 100  -- Electronics: expensive only
        WHEN CategoryID = 2 THEN Price > 50   -- Clothing: moderate+
        ELSE Price > 0                         -- Others: all prices
      END = 1;  -- TRUE

-- Usage 5.2: Dynamic Range Filtering
DECLARE @PriceFilter VARCHAR(10) = 'High';

SELECT 
    ProductName,
    Price
FROM Products
WHERE CASE @PriceFilter
        WHEN 'High' THEN CASE WHEN Price > 100 THEN 1 ELSE 0 END
        WHEN 'Medium' THEN CASE WHEN Price BETWEEN 50 AND 100 THEN 1 ELSE 0 END
        WHEN 'Low' THEN CASE WHEN Price < 50 THEN 1 ELSE 0 END
        ELSE 1
      END = 1;

-- Usage 5.3: Complex Conditional Logic
SELECT 
    OrderID,
    OrderDate,
    TotalAmount
FROM Orders
WHERE CASE 
        WHEN YEAR(OrderDate) = 2024 THEN TotalAmount > 500
        WHEN YEAR(OrderDate) = 2023 THEN TotalAmount > 300
        ELSE TotalAmount > 100
      END = 1;


/*
============================================================================
PART 6: CASE in ORDER BY Clause
============================================================================
*/

-- Usage 6.1: Custom Sort Order
SELECT 
    CustomerName,
    Country
FROM Customers
ORDER BY 
    CASE Country
        WHEN 'USA' THEN 1
        WHEN 'Canada' THEN 2
        WHEN 'Mexico' THEN 3
        ELSE 4
    END,
    CustomerName;
-- USA customers first, then Canada, Mexico, then others

-- Usage 6.2: NULL Handling in Sorting
SELECT 
    ProductName,
    Price
FROM Products
ORDER BY 
    CASE 
        WHEN Price IS NULL THEN 1  -- NULLs last
        ELSE 0
    END,
    Price;

-- Usage 6.3: Conditional Sort Direction
DECLARE @SortOrder VARCHAR(10) = 'HighToLow';

SELECT 
    ProductName,
    Price
FROM Products
ORDER BY 
    CASE @SortOrder
        WHEN 'HighToLow' THEN Price
    END DESC,
    CASE @SortOrder
        WHEN 'LowToHigh' THEN Price
    END ASC;


/*
============================================================================
PART 7: Nesting CASE Expressions
============================================================================
*/

-- Example 7.1: Nested CASE (Use Sparingly)
SELECT 
    ProductName,
    Price,
    CategoryID,
    CASE CategoryID
        WHEN 1 THEN 
            CASE 
                WHEN Price > 200 THEN 'Premium Electronics'
                WHEN Price > 100 THEN 'Standard Electronics'
                ELSE 'Budget Electronics'
            END
        WHEN 2 THEN
            CASE 
                WHEN Price > 100 THEN 'Designer Clothing'
                ELSE 'Regular Clothing'
            END
        ELSE 'Other Product'
    END AS DetailedCategory
FROM Products
WHERE ProductID <= 10;

-- Example 7.2: Better Alternative - Flat Structure
SELECT 
    ProductName,
    Price,
    CategoryID,
    CASE 
        WHEN CategoryID = 1 AND Price > 200 THEN 'Premium Electronics'
        WHEN CategoryID = 1 AND Price > 100 THEN 'Standard Electronics'
        WHEN CategoryID = 1 THEN 'Budget Electronics'
        WHEN CategoryID = 2 AND Price > 100 THEN 'Designer Clothing'
        WHEN CategoryID = 2 THEN 'Regular Clothing'
        ELSE 'Other Product'
    END AS DetailedCategory
FROM Products
WHERE ProductID <= 10;

-- Example 7.3: When Nesting Makes Sense
-- Outer CASE determines category, inner determines specific value
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    CASE 
        WHEN OrderDate >= DATEADD(DAY, -30, GETDATE()) THEN
            'Recent: ' + CASE 
                WHEN TotalAmount > 500 THEN 'Large'
                ELSE 'Small'
            END
        ELSE
            'Old: ' + CASE 
                WHEN TotalAmount > 500 THEN 'Large'
                ELSE 'Small'
            END
    END AS OrderDescription
FROM Orders
WHERE OrderID <= 10;


/*
============================================================================
PART 8: Common Patterns and Best Practices
============================================================================
*/

-- Pattern 8.1: ✅ Range Categorization
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'No Price'
        WHEN Price < 50 THEN 'Tier 1'
        WHEN Price < 100 THEN 'Tier 2'
        WHEN Price < 200 THEN 'Tier 3'
        ELSE 'Tier 4'
    END AS PriceTier
FROM Products
WHERE ProductID <= 10;

-- Pattern 8.2: ✅ Status Mapping
SELECT 
    OrderID,
    CASE 
        WHEN ShipDate IS NULL THEN 'Pending'
        WHEN DeliveryDate IS NULL THEN 'Shipped'
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered'
    END AS Status
FROM Orders
WHERE OrderID <= 10;

-- Pattern 8.3: ✅ Value Translation
SELECT 
    CustomerName,
    CASE Country
        WHEN 'USA' THEN 'United States'
        WHEN 'UK' THEN 'United Kingdom'
        WHEN 'UAE' THEN 'United Arab Emirates'
        ELSE Country
    END AS CountryName
FROM Customers
WHERE CustomerID <= 10;

-- Pattern 8.4: ⚠️ Avoid Over-Nesting
-- ❌ Hard to read:
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 THEN
            CASE 
                WHEN InStock = 1 THEN
                    CASE 
                        WHEN Featured = 1 THEN 'Premium Featured'
                        ELSE 'Premium Regular'
                    END
                ELSE 'Premium Out of Stock'
            END
        ELSE 'Standard'
    END AS Category
FROM Products
WHERE ProductID <= 5;

-- ✅ Better - Flat conditions:
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 AND InStock = 1 AND Featured = 1 THEN 'Premium Featured'
        WHEN Price > 100 AND InStock = 1 THEN 'Premium Regular'
        WHEN Price > 100 THEN 'Premium Out of Stock'
        ELSE 'Standard'
    END AS Category
FROM Products
WHERE ProductID <= 5;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a query categorizing orders by size: Tiny (<100), Small (100-500), Medium (500-1000), Large (>1000)
2. Use CASE in ORDER BY to sort products: In Stock first, then by price ascending
3. Write nested CASE showing customer tier and activity level
4. Create conditional aggregation counting orders by size category
5. Use CASE in WHERE to filter products: Electronics >$100 OR Clothing >$50

Solutions below ↓
*/

-- Solution 1:
SELECT 
    OrderID,
    TotalAmount,
    CASE 
        WHEN TotalAmount < 100 THEN 'Tiny'
        WHEN TotalAmount < 500 THEN 'Small'
        WHEN TotalAmount < 1000 THEN 'Medium'
        ELSE 'Large'
    END AS OrderSize
FROM Orders
WHERE OrderID <= 20;

-- Solution 2:
SELECT 
    ProductName,
    Price,
    InStock
FROM Products
ORDER BY 
    CASE 
        WHEN InStock = 1 THEN 0
        ELSE 1
    END,
    Price ASC;

-- Solution 3:
WITH CustomerStats AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    OrderCount,
    CASE 
        WHEN OrderCount >= 10 THEN
            CASE 
                WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 'VIP - Active'
                ELSE 'VIP - Inactive'
            END
        WHEN OrderCount >= 5 THEN
            CASE 
                WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 60 THEN 'Regular - Active'
                ELSE 'Regular - Inactive'
            END
        ELSE 'New Customer'
    END AS CustomerStatus
FROM CustomerStats;

-- Solution 4:
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN TotalAmount < 100 THEN 1 ELSE 0 END) AS TinyOrders,
    SUM(CASE WHEN TotalAmount >= 100 AND TotalAmount < 500 THEN 1 ELSE 0 END) AS SmallOrders,
    SUM(CASE WHEN TotalAmount >= 500 AND TotalAmount < 1000 THEN 1 ELSE 0 END) AS MediumOrders,
    SUM(CASE WHEN TotalAmount >= 1000 THEN 1 ELSE 0 END) AS LargeOrders
FROM Orders;

-- Solution 5:
SELECT 
    ProductName,
    Price,
    CategoryID
FROM Products
WHERE CASE 
        WHEN CategoryID = 1 THEN Price > 100  -- Electronics
        WHEN CategoryID = 2 THEN Price > 50   -- Clothing
        ELSE 0  -- Exclude others
      END = 1;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CASE FORMATS:
  • Searched CASE: Any boolean condition
  • Simple CASE: Equality checks only
  • Both are expressions (return values)

✓ EVALUATION:
  • Top to bottom
  • Stops at first TRUE condition
  • ELSE if no match (or NULL)
  • Order of WHEN matters!

✓ DATA TYPES:
  • All results must be compatible
  • Use CAST/CONVERT if needed
  • NULL is compatible with any type

✓ USAGE LOCATIONS:
  • SELECT: Derive columns
  • WHERE: Conditional filtering
  • ORDER BY: Custom sorting
  • GROUP BY: Conditional grouping
  • Any expression context

✓ NESTING:
  • Keep to 2-3 levels max
  • Flat structure often better
  • Use AND/OR when possible

✓ BEST PRACTICES:
  • Always include ELSE
  • Order WHEN specific → general
  • Keep expressions simple
  • Use meaningful names
  • Comment complex logic
  • Test all branches

✓ COMMON PATTERNS:
  • Range categorization
  • Status mapping
  • Value translation
  • Conditional aggregation
  • Pivoting data

============================================================================
NEXT: Lesson 11.03 - Searched CASE Expressions
Master the most flexible CASE format with complex conditions.
============================================================================
*/
