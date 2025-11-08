/*============================================
   LESSON 09: NULL HANDLING
   Working with missing/unknown values
   
   Estimated Time: 20 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS NULL?
   Understanding NULL
--------------------------------------------*/

/*
   NULL = Unknown, Missing, or Not Applicable
   - NOT the same as 0
   - NOT the same as empty string ''
   - NOT the same as space ' '
   
   NULL has special behavior:
   - NULL = NULL returns NULL (not TRUE!)
   - NULL <> NULL returns NULL (not TRUE!)
   - NULL in ANY comparison returns NULL
*/

-- Show NULL behavior
SELECT 
    NULL AS NullValue,
    NULL = NULL AS NullEqualsNull,           -- NULL (not TRUE!)
    NULL <> NULL AS NullNotEqualsNull,       -- NULL (not TRUE!)
    NULL > 5 AS NullGreaterThan5,            -- NULL
    5 + NULL AS FivePlusNull,                -- NULL
    'Hello' + NULL AS StringPlusNull;        -- NULL

/*--------------------------------------------
   PART 2: CHECKING FOR NULL
   IS NULL and IS NOT NULL
--------------------------------------------*/

-- ❌ WRONG: This returns ZERO rows (NULL = NULL is NULL, not TRUE)
SELECT ProductName FROM Inventory.Products WHERE SupplierID = NULL;

-- ✅ CORRECT: Use IS NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NULL;

-- ✅ CORRECT: Use IS NOT NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NOT NULL;

/*--------------------------------------------
   PART 3: NULL IN CALCULATIONS
   NULL propagation
--------------------------------------------*/

-- Any arithmetic with NULL = NULL
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax,
    NULL * 1.15 AS NullCalculation  -- NULL
FROM Inventory.Products;

-- NULL in string concatenation
SELECT 
    FirstName,
    LastName,
    FirstName + ' ' + LastName AS FullName  -- NULL if either is NULL
FROM Sales.Customers;

/*--------------------------------------------
   PART 4: ISNULL FUNCTION
   Replace NULL with default value
--------------------------------------------*/

-- ISNULL(column, replacement_value)
SELECT 
    ProductName,
    SupplierID,
    ISNULL(SupplierID, 0) AS SupplierIDOrZero
FROM Inventory.Products;

-- Use in calculations
SELECT 
    ProductName,
    Price,
    ISNULL(Price, 0) * 1.15 AS PriceWithTax
FROM Inventory.Products;

-- Use in strings
SELECT 
    FirstName,
    LastName,
    ISNULL(FirstName, 'Unknown') + ' ' + ISNULL(LastName, 'Unknown') AS FullName
FROM Sales.Customers;

/*--------------------------------------------
   PART 5: COALESCE FUNCTION
   Return first non-NULL value
--------------------------------------------*/

-- COALESCE(value1, value2, value3, ..., default)
SELECT 
    ProductName,
    SupplierID,
    COALESCE(SupplierID, -1) AS SupplierIDOrNegativeOne
FROM Inventory.Products;

-- Multiple fallbacks
SELECT 
    ProductName,
    COALESCE(SupplierID, CategoryID, ProductID, 0) AS FirstNonNull
FROM Inventory.Products;

-- ISNULL vs COALESCE
SELECT 
    ISNULL(NULL, 100) AS UsingISNULL,        -- 100
    COALESCE(NULL, 100) AS UsingCOALESCE,    -- 100
    COALESCE(NULL, NULL, 200) AS MultipleValues;  -- 200 (ISNULL can't do this)

/*--------------------------------------------
   PART 6: NULLIF FUNCTION
   Convert specific value to NULL
--------------------------------------------*/

-- NULLIF(value, value_to_convert_to_null)
-- Returns NULL if values match, otherwise returns first value

SELECT 
    ProductName,
    Price,
    NULLIF(Price, 0) AS PriceOrNull  -- NULL if price is 0
FROM Inventory.Products;

-- Avoid division by zero
SELECT 
    ProductName,
    StockQuantity,
    Price / NULLIF(StockQuantity, 0) AS PricePerUnit  -- NULL instead of error
FROM Inventory.Products;

/*--------------------------------------------
   PART 7: NULL IN WHERE CLAUSE
   Filtering with NULL
--------------------------------------------*/

-- Find missing values
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NULL;

-- Find existing values
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NOT NULL;

-- Combine with other conditions
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100
  AND SupplierID IS NULL;

/*--------------------------------------------
   PART 8: NULL IN AND/OR LOGIC
   Three-valued logic
--------------------------------------------*/

/*
   AND Truth Table:
   TRUE  AND TRUE  = TRUE
   TRUE  AND FALSE = FALSE
   TRUE  AND NULL  = NULL
   FALSE AND NULL  = FALSE
   NULL  AND NULL  = NULL
   
   OR Truth Table:
   TRUE  OR TRUE  = TRUE
   TRUE  OR FALSE = TRUE
   TRUE  OR NULL  = TRUE
   FALSE OR NULL  = NULL
   NULL  OR NULL  = NULL
*/

-- NULL in AND
SELECT ProductName FROM Inventory.Products 
WHERE Price > 100 AND SupplierID IS NULL;  -- Both must be TRUE

-- NULL in OR
SELECT ProductName FROM Inventory.Products 
WHERE Price > 100 OR SupplierID IS NULL;  -- Either TRUE works

/*--------------------------------------------
   PART 9: NULL IN JOINS
   Handling NULL in join conditions
--------------------------------------------*/

-- LEFT JOIN with NULL check
SELECT p.ProductName, s.SupplierName
FROM Inventory.Products p
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE s.SupplierID IS NULL;  -- Products with no supplier

-- Find matches including NULL
SELECT p.ProductName, ISNULL(s.SupplierName, 'No Supplier') AS Supplier
FROM Inventory.Products p
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

/*--------------------------------------------
   PART 10: NULL IN AGGREGATES
   How functions handle NULL
--------------------------------------------*/

-- Most aggregates IGNORE NULL
SELECT 
    COUNT(*) AS TotalRows,                    -- Counts all rows
    COUNT(SupplierID) AS NonNullSuppliers,   -- Counts non-NULL only
    COUNT(DISTINCT SupplierID) AS UniqueSuppliers,
    AVG(Price) AS AvgPrice                    -- Ignores NULL prices
FROM Inventory.Products;

-- SUM ignores NULL
SELECT SUM(Price) AS TotalPrice FROM Inventory.Products;  -- NULL values ignored

-- MAX/MIN ignore NULL
SELECT MAX(Price) AS MaxPrice, MIN(Price) AS MinPrice FROM Inventory.Products;

/*--------------------------------------------
   PART 11: NULL IN ORDER BY
   Sorting NULL values
--------------------------------------------*/

-- NULL sorts first (ascending)
SELECT ProductName, SupplierID
FROM Inventory.Products
ORDER BY SupplierID ASC;  -- NULLs appear first

-- NULL sorts last (descending)
SELECT ProductName, SupplierID
FROM Inventory.Products
ORDER BY SupplierID DESC;  -- NULLs appear last

-- Force NULL to bottom
SELECT ProductName, SupplierID
FROM Inventory.Products
ORDER BY 
    CASE WHEN SupplierID IS NULL THEN 1 ELSE 0 END,
    SupplierID;

/*--------------------------------------------
   PART 12: NULL IN CASE EXPRESSIONS
   Conditional NULL handling
--------------------------------------------*/

SELECT 
    ProductName,
    SupplierID,
    CASE 
        WHEN SupplierID IS NULL THEN 'No Supplier'
        WHEN SupplierID = 1 THEN 'Primary Supplier'
        ELSE 'Other Supplier'
    END AS SupplierStatus
FROM Inventory.Products;

/*--------------------------------------------
   PART 13: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Customer contact info (handle missing)
SELECT 
    FirstName,
    LastName,
    ISNULL(Email, 'No Email') AS Email,
    ISNULL(Phone, 'No Phone') AS Phone
FROM Sales.Customers;

-- Example 2: Product pricing with discounts
SELECT 
    ProductName,
    Price AS OriginalPrice,
    ISNULL(Price * 0.90, Price) AS DiscountedPrice  -- 10% off if price exists
FROM Inventory.Products;

-- Example 3: Employee reporting structure
SELECT 
    e.FirstName,
    e.LastName,
    ISNULL(m.FirstName + ' ' + m.LastName, 'No Manager') AS Manager
FROM HR.Employees e
LEFT JOIN HR.Employees m ON e.ManagerID = m.EmployeeID;

/*--------------------------------------------
   PART 14: COMMON MISTAKES
--------------------------------------------*/

-- ❌ MISTAKE 1: Using = NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID = NULL;  -- Returns nothing!

-- ✅ FIX: Use IS NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NULL;

-- ❌ MISTAKE 2: Forgetting NULL in concatenation
SELECT FirstName + ' ' + LastName FROM Sales.Customers;  -- NULL if either is NULL

-- ✅ FIX: Use ISNULL or CONCAT
SELECT CONCAT(FirstName, ' ', LastName) FROM Sales.Customers;  -- CONCAT treats NULL as empty

-- ❌ MISTAKE 3: NOT IN with NULL subquery
SELECT * FROM Sales.Customers 
WHERE CustomerID NOT IN (SELECT CustomerID FROM Sales.Orders);  -- Fails if any NULL!

-- ✅ FIX: Filter NULLs or use NOT EXISTS
SELECT * FROM Sales.Customers c
WHERE NOT EXISTS (SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID);

/*--------------------------------------------
   PART 15: PRACTICE
--------------------------------------------*/

-- 1. Find products without suppliers
-- 2. Replace NULL supplier IDs with -1
-- 3. Calculate average price (how are NULLs handled?)
-- 4. Find customers with no email address
-- 5. Sort products putting NULLs at the bottom

/*============================================
   NEXT: Lesson 10 - Test Your Knowledge
============================================*/
