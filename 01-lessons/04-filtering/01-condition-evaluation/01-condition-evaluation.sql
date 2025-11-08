/*============================================
   LESSON 01: CONDITION EVALUATION
   How SQL evaluates WHERE clause conditions
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS CONDITION EVALUATION?
   Understanding TRUE, FALSE, and NULL
--------------------------------------------*/

-- Every condition returns TRUE, FALSE, or NULL
-- Only TRUE rows are included in results

-- Simple TRUE condition
SELECT ProductName, Price
FROM Inventory.Products
WHERE 1 = 1;  -- Always TRUE, returns all rows

-- Simple FALSE condition
SELECT ProductName, Price
FROM Inventory.Products
WHERE 1 = 0;  -- Always FALSE, returns no rows


/*--------------------------------------------
   PART 2: TRUTH VALUES
   How conditions evaluate
--------------------------------------------*/

-- TRUE: Condition is met
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;  -- Returns rows where Price > 100

-- FALSE: Condition not met (rows excluded)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 10000;  -- Probably no products this expensive (returns 0 rows)

-- NULL: Unknown result (treated as FALSE)
SELECT ProductName, Price
FROM Inventory.Products
WHERE NULL = NULL;  -- Returns 0 rows (NULL = NULL is NULL, not TRUE!)


/*--------------------------------------------
   PART 3: COMPARISON OPERATORS
   Basic condition building blocks
--------------------------------------------*/

-- Equal to (=)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price = 75.50;

-- Not equal to (<> or !=)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price <> 75.50;

-- Greater than (>)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;

-- Less than (<)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 50;

-- Greater than or equal (>=)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price >= 100;

-- Less than or equal (<=)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price <= 100;


/*--------------------------------------------
   PART 4: AND OPERATOR
   ALL conditions must be TRUE
--------------------------------------------*/

-- Both conditions TRUE → Result TRUE
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price > 50 AND StockQuantity > 20;

-- Truth table for AND:
-- TRUE  AND TRUE  = TRUE   ← Row included
-- TRUE  AND FALSE = FALSE  ← Row excluded
-- FALSE AND TRUE  = FALSE  ← Row excluded
-- FALSE AND FALSE = FALSE  ← Row excluded

-- Example with three conditions
SELECT ProductName, Price, StockQuantity, CategoryID
FROM Inventory.Products
WHERE Price > 50 
  AND StockQuantity > 20 
  AND CategoryID = 1;


/*--------------------------------------------
   PART 5: OR OPERATOR
   AT LEAST ONE condition must be TRUE
--------------------------------------------*/

-- Either condition TRUE → Result TRUE
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 30 OR Price > 1000;

-- Truth table for OR:
-- TRUE  OR TRUE  = TRUE   ← Row included
-- TRUE  OR FALSE = TRUE   ← Row included
-- FALSE OR TRUE  = TRUE   ← Row included
-- FALSE OR FALSE = FALSE  ← Row excluded

-- Example with multiple OR conditions
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 
   OR CategoryID = 2 
   OR CategoryID = 3;


/*--------------------------------------------
   PART 6: COMBINING AND / OR
   Order matters!
--------------------------------------------*/

-- AND is evaluated before OR (like multiplication before addition)
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 AND Price > 100 OR CategoryID = 2;

-- This is interpreted as:
-- (CategoryID = 1 AND Price > 100) OR CategoryID = 2
-- Meaning: "Expensive electronics OR any furniture"

-- Different from:
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 AND (Price > 100 OR CategoryID = 2);
-- Meaning: "Category 1 AND (expensive OR category 2)"
-- The second part makes no sense logically!


/*--------------------------------------------
   PART 7: EVALUATION ORDER
   SQL evaluates conditions left to right
--------------------------------------------*/

-- Example 1: Simple left-to-right
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price > 50          -- Evaluated first
  AND StockQuantity > 10  -- Evaluated second
  AND CategoryID = 1;     -- Evaluated third

-- Example 2: Short-circuit evaluation
-- If first condition is FALSE in AND, SQL might skip the rest
SELECT ProductName, Price
FROM Inventory.Products
WHERE 1 = 0               -- FALSE - SQL might stop here
  AND Price > 100;        -- Might not even evaluate this

-- If first condition is TRUE in OR, SQL might skip the rest
SELECT ProductName, Price
FROM Inventory.Products
WHERE 1 = 1               -- TRUE - SQL might stop here
  OR Price > 100;         -- Might not even evaluate this


/*--------------------------------------------
   PART 8: NULL IN CONDITIONS
   NULL = unknown
--------------------------------------------*/

-- NULL comparisons always return NULL (not TRUE or FALSE)
SELECT 
    ProductName,
    SupplierID,
    CASE 
        WHEN SupplierID = 1 THEN 'TRUE'
        WHEN SupplierID <> 1 THEN 'FALSE'
        ELSE 'NULL (neither TRUE nor FALSE)'
    END AS EvaluationResult
FROM Inventory.Products;

-- NULL in AND
-- NULL AND TRUE  = NULL  → Row excluded
-- NULL AND FALSE = FALSE → Row excluded

-- NULL in OR
-- NULL OR TRUE  = TRUE   → Row included!
-- NULL OR FALSE = NULL   → Row excluded

-- Example:
SELECT ProductName, SupplierID, Price
FROM Inventory.Products
WHERE SupplierID = 1      -- TRUE for some, FALSE for some, NULL for NULL values
   OR Price < 50;         -- This can save rows with NULL SupplierID


/*--------------------------------------------
   PART 9: TESTING CONDITIONS
   Verify your logic
--------------------------------------------*/

-- Add a "test" column to see condition results
SELECT 
    ProductName,
    Price,
    StockQuantity,
    CASE 
        WHEN Price > 100 AND StockQuantity > 20 THEN 'MATCH'
        ELSE 'NO MATCH'
    END AS TestResult
FROM Inventory.Products;

-- Count how many rows match
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Price > 100 THEN 1 ELSE 0 END) AS MatchingRows,
    SUM(CASE WHEN Price <= 100 THEN 1 ELSE 0 END) AS NonMatchingRows
FROM Inventory.Products;


/*--------------------------------------------
   PART 10: PRACTICAL EXAMPLES
   Real-world condition evaluation
--------------------------------------------*/

-- Example 1: Find available products in stock
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE StockQuantity > 0    -- Must have stock
  AND Price > 0;           -- Must have price

-- Example 2: Find products needing attention
SELECT 
    ProductName,
    StockQuantity,
    SupplierID,
    CASE 
        WHEN StockQuantity = 0 THEN 'OUT OF STOCK'
        WHEN StockQuantity < 10 THEN 'LOW STOCK'
        WHEN SupplierID IS NULL THEN 'NO SUPPLIER'
        ELSE 'OK'
    END AS Status
FROM Inventory.Products
WHERE StockQuantity < 10        -- Low or no stock
   OR SupplierID IS NULL;       -- Or no supplier


/*--------------------------------------------
   PART 11: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Find products where Price > 100 AND StockQuantity > 50
-- Write your query:


-- 2. Find products where Price < 50 OR StockQuantity = 0
-- Write your query:


-- 3. Find products where (Price > 100 AND CategoryID = 1) OR CategoryID = 2
-- Write your query:


-- 4. Count how many products have Price > 100
-- Write your query:


-- 5. Find products where SupplierID IS NULL OR StockQuantity < 10
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ Conditions return TRUE, FALSE, or NULL
   ✅ Only TRUE rows are included
   ✅ NULL is treated as FALSE in WHERE
   ✅ AND requires ALL conditions TRUE
   ✅ OR requires AT LEAST ONE condition TRUE
   ✅ AND is evaluated before OR
   ✅ Use parentheses for clarity
   
   Truth Values:
   - TRUE → Include row
   - FALSE → Exclude row  
   - NULL → Exclude row (unknown = not true)
   
   NEXT: Lesson 02 - Using Parentheses
============================================*/
