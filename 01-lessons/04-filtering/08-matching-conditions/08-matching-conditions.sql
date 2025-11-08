/*============================================
   LESSON 08: MATCHING CONDITIONS
   Pattern matching with LIKE
   
   Estimated Time: 20 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WILDCARD BASICS
   Understanding pattern characters
--------------------------------------------*/

/*
   % = Any sequence of characters (0 or more)
   _ = Exactly one character
   [] = Any single character within brackets
   [^] = Any single character NOT in brackets
*/

-- % examples
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE 'J%';        -- Starts with J
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '%n';        -- Ends with n
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '%oh%';      -- Contains 'oh'
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '%';         -- Everything (all rows)

-- _ examples
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE 'J___';      -- J + exactly 3 chars (John, Jane)
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '_a%';       -- 2nd character is 'a'

/*--------------------------------------------
   PART 2: STARTS WITH / ENDS WITH / CONTAINS
   Common search patterns
--------------------------------------------*/

-- Starts with
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE 'Laptop%';

-- Ends with
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%Pro';

-- Contains (anywhere)
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%Dell%';

-- Does NOT contain
SELECT ProductName FROM Inventory.Products WHERE ProductName NOT LIKE '%HP%';

/*--------------------------------------------
   PART 3: MULTIPLE WILDCARD COMBINATIONS
   Complex patterns
--------------------------------------------*/

-- Starts with A-Z, ends with 's'
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%s';

-- Contains 'book' but not at start
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '_%book%';

-- Multiple wildcards
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%i%i%';  -- At least 2 i's

/*--------------------------------------------
   PART 4: CHARACTER RANGES []
   Match specific character sets
--------------------------------------------*/

-- Starts with A, B, or C
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '[ABC]%';

-- Starts with vowel
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '[AEIOU]%';

-- Starts with number
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '[0-9]%';

-- Second character is vowel
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '_[AEIOU]%';

/*--------------------------------------------
   PART 5: NEGATED RANGES [^]
   Exclude specific characters
--------------------------------------------*/

-- Does NOT start with vowel
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE '[^AEIOU]%';

-- Does NOT start with A-M
SELECT LastName FROM Sales.Customers WHERE LastName LIKE '[^A-M]%';

-- Does NOT contain numbers
SELECT ProductName FROM Inventory.Products WHERE ProductName NOT LIKE '%[0-9]%';

/*--------------------------------------------
   PART 6: ESCAPING SPECIAL CHARACTERS
   Search for literal %, _, [, ]
--------------------------------------------*/

-- Define escape character
SELECT ProductName FROM Inventory.Products 
WHERE ProductName LIKE '%!%%' ESCAPE '!';  -- Find names with literal %

-- Find underscore
SELECT ProductName FROM Inventory.Products 
WHERE ProductName LIKE '%!_%' ESCAPE '!';  -- Find names with literal _

-- Find bracket
SELECT ProductName FROM Inventory.Products 
WHERE ProductName LIKE '%[[]%';  -- Find names with [

/*--------------------------------------------
   PART 7: CASE SENSITIVITY
   Controlling match behavior
--------------------------------------------*/

-- Default: Case-insensitive
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE 'john%';  -- Matches 'John', 'JOHN', 'john'

-- Force case-sensitive
SELECT FirstName FROM Sales.Customers 
WHERE FirstName COLLATE Latin1_General_CS_AS LIKE 'John%';  -- Only 'John...'

-- Force case-insensitive
SELECT ProductName FROM Inventory.Products 
WHERE LOWER(ProductName) LIKE LOWER('%laptop%');

/*--------------------------------------------
   PART 8: COMBINING LIKE WITH OTHER CONDITIONS
   Complex filtering
--------------------------------------------*/

-- LIKE + range
SELECT ProductName, Price
FROM Inventory.Products
WHERE ProductName LIKE 'Dell%'
  AND Price BETWEEN 500 AND 1500;

-- Multiple LIKE conditions (OR)
SELECT ProductName FROM Inventory.Products
WHERE ProductName LIKE '%Dell%'
   OR ProductName LIKE '%HP%'
   OR ProductName LIKE '%Lenovo%';

-- Multiple LIKE conditions (AND)
SELECT ProductName FROM Inventory.Products
WHERE ProductName LIKE '%Pro%'
  AND ProductName LIKE '%15%';

/*--------------------------------------------
   PART 9: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Find email addresses
-- Assuming Customers has Email column
-- SELECT Email FROM Sales.Customers WHERE Email LIKE '%@gmail.com';
-- SELECT Email FROM Sales.Customers WHERE Email LIKE '%@%' AND Email LIKE '%.%';

-- Example 2: Phone number patterns
-- SELECT Phone FROM Sales.Customers WHERE Phone LIKE '(___) ___-____';

-- Example 3: Product code patterns
SELECT ProductName FROM Inventory.Products 
WHERE ProductName LIKE '[A-Z][A-Z][0-9][0-9][0-9]%';  -- XX999...

-- Example 4: Search customer names
SELECT FirstName, LastName FROM Sales.Customers
WHERE FirstName LIKE 'J%' 
   OR LastName LIKE 'J%';

/*--------------------------------------------
   PART 10: LIKE VS FULL-TEXT SEARCH
   When to use each
--------------------------------------------*/

-- ✅ Use LIKE for:
-- - Simple pattern matching
-- - Wildcard searches
-- - Small datasets

-- ❌ DON'T use LIKE for:
-- - Large text searches (slow)
-- - Word boundary matching
-- - Relevance ranking
-- Instead use: CONTAINS, FREETEXT (Full-Text Search)

/*--------------------------------------------
   PART 11: PERFORMANCE TIPS
--------------------------------------------*/

-- ❌ SLOW: Leading wildcard (can't use index)
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%Laptop';

-- ✅ FASTER: No leading wildcard (can use index)
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE 'Laptop%';

-- ✅ FASTER: Use full-text search for large text
-- CREATE FULLTEXT INDEX...
-- SELECT * FROM Products WHERE CONTAINS(ProductName, 'Laptop');

/*--------------------------------------------
   PART 12: COMMON PATTERNS REFERENCE
--------------------------------------------*/

/*
Pattern                 | Matches
------------------------|----------------------------------
LIKE 'A%'              | Starts with A
LIKE '%z'              | Ends with z
LIKE '%abc%'           | Contains abc
LIKE '_a%'             | Second char is a
LIKE '[ABC]%'          | Starts with A, B, or C
LIKE '[A-Z]%'          | Starts with any letter
LIKE '[0-9]%'          | Starts with digit
LIKE '[^0-9]%'         | Does NOT start with digit
LIKE '____'            | Exactly 4 characters
LIKE '%!%%' ESCAPE '!' | Contains literal %
*/

/*--------------------------------------------
   PART 13: PRACTICE
--------------------------------------------*/

-- 1. Customers with last names starting with 'S'
-- 2. Products containing 'Pro' anywhere
-- 3. Names exactly 4 letters long
-- 4. Products starting with vowel
-- 5. Find all .com email addresses

/*============================================
   NEXT: Lesson 09 - NULL Handling
============================================*/
