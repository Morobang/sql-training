/*============================================
   LESSON 10: TEST YOUR KNOWLEDGE
   Chapter 04: Filtering - Practice Exercises
   
   Estimated Time: 45 minutes
   Difficulty: Beginner to Intermediate
============================================*/

USE RetailStore;
GO

/*============================================
   SECTION 1: CONDITION EVALUATION
   Test basic TRUE/FALSE/NULL logic
============================================*/

-- Exercise 1.1: Write a query that demonstrates TRUE AND TRUE = TRUE


-- Exercise 1.2: Write a query that demonstrates TRUE AND NULL = NULL


-- Exercise 1.3: Write a query that demonstrates FALSE OR NULL = NULL


-- Exercise 1.4: Find products where price > 100 AND stock > 20


-- Exercise 1.5: Find products where price < 50 OR stock < 10


/*============================================
   SECTION 2: USING PARENTHESES
   Control evaluation order
============================================*/

-- Exercise 2.1: Find products that are:
-- (Category 1 OR Category 2) AND Price > 100


-- Exercise 2.2: Find products that are:
-- Category 1 OR (Category 2 AND Price > 100)


-- Exercise 2.3: Find products that are:
-- (Price BETWEEN 50 AND 150) AND (Stock > 10 OR CategoryID = 1)


-- Exercise 2.4: Rewrite using parentheses for clarity:
-- SELECT * FROM Products WHERE Price > 100 OR CategoryID = 1 AND Stock > 20


-- Exercise 2.5: Complex business logic - Find products that are:
-- ((Low price < 50 AND in stock) OR (Premium price > 500)) AND NOT in category 3


/*============================================
   SECTION 3: NOT OPERATOR
   Negation and exclusion
============================================*/

-- Exercise 3.1: Find products NOT in category 1


-- Exercise 3.2: Find products NOT priced between $100-$500


-- Exercise 3.3: Find products where name does NOT contain 'Pro'


-- Exercise 3.4: Find customers who do NOT have 'Smith' as last name


-- Exercise 3.5: Find products where (Price > 100) is NOT true


/*============================================
   SECTION 4: BUILDING CONDITIONS
   Compound filtering
============================================*/

-- Exercise 4.1: Find products with:
-- Price $50-$200 AND Stock 10-50 units AND CategoryID in (1,2,3)


-- Exercise 4.2: Find customers whose:
-- Last name starts with 'J' AND first name has exactly 4 letters


-- Exercise 4.3: Find orders where:
-- Order date in January 2025 AND total amount > $500


-- Exercise 4.4: Find products created this year with price > average price


-- Exercise 4.5: Find employees with salary > $70k who work in specific departments


/*============================================
   SECTION 5: EQUALITY CONDITIONS
   Exact matching
============================================*/

-- Exercise 5.1: Find products with exact price of $99.99


-- Exercise 5.2: Find all customers with last name exactly 'Johnson'


-- Exercise 5.3: Find products where CategoryID = 2 (use explicit equality)


-- Exercise 5.4: Find orders on exactly January 15, 2025


-- Exercise 5.5: Find products where price is NOT equal to $100


/*============================================
   SECTION 6: RANGE CONDITIONS
   BETWEEN and comparison operators
============================================*/

-- Exercise 6.1: Find products priced between $50 and $500


-- Exercise 6.2: Find orders from the last 30 days


-- Exercise 6.3: Find employees with salary between $60,000 and $90,000


-- Exercise 6.4: Find products with stock between 20 and 100 units


-- Exercise 6.5: Find customers with last names from A-M (alphabetically)


-- Exercise 6.6: Find orders NOT in January 2025


-- Exercise 6.7: Find products with price < 50 OR price > 500 (exclude middle)


-- Exercise 6.8: Find orders from Q1 2025 (January-March)


/*============================================
   SECTION 7: MEMBERSHIP CONDITIONS
   IN and NOT IN operators
============================================*/

-- Exercise 7.1: Find products in categories 1, 3, and 5


-- Exercise 7.2: Find customers with last names in ('Smith', 'Jones', 'Williams')


-- Exercise 7.3: Find products NOT in categories 2 and 4


-- Exercise 7.4: Find products in 'Electronics' or 'Books' categories (use subquery)


-- Exercise 7.5: Find customers who have placed at least one order (use IN with subquery)


-- Exercise 7.6: Find customers who have NEVER placed an order (use NOT IN, handle NULLs)


-- Exercise 7.7: Find products with prices in (99.99, 149.99, 199.99, 299.99)


-- Exercise 7.8: Find products created in years 2023, 2024, or 2025


/*============================================
   SECTION 8: MATCHING CONDITIONS
   LIKE operator and wildcards
============================================*/

-- Exercise 8.1: Find customers with last names starting with 'S'


-- Exercise 8.2: Find products containing 'Pro' anywhere in the name


-- Exercise 8.3: Find products with names exactly 6 characters long


-- Exercise 8.4: Find customers with first names ending in 'n'


-- Exercise 8.5: Find products where name starts with a vowel (A, E, I, O, U)


-- Exercise 8.6: Find products where name does NOT contain numbers


-- Exercise 8.7: Find customers where last name has 'a' as the second character


-- Exercise 8.8: Find products with names matching pattern: Letter-Letter-Number-Number-Number


/*============================================
   SECTION 9: NULL HANDLING
   IS NULL, ISNULL, COALESCE
============================================*/

-- Exercise 9.1: Find products where SupplierID IS NULL


-- Exercise 9.2: Find products where SupplierID IS NOT NULL


-- Exercise 9.3: Display products with SupplierID, replacing NULL with -1 (use ISNULL)


-- Exercise 9.4: Display products with SupplierID, replacing NULL with 'Unknown' text


-- Exercise 9.5: Find products where Price IS NULL or Price = 0


-- Exercise 9.6: Calculate total price, treating NULL as 0 (use ISNULL in SUM)


-- Exercise 9.7: Display customer full name, handling NULL first/last names (use COALESCE)


-- Exercise 9.8: Sort products by SupplierID, placing NULLs at the bottom


/*============================================
   SECTION 10: COMBINED CHALLENGES
   Mix multiple filtering techniques
============================================*/

-- Exercise 10.1: Complex Product Search
-- Find products that:
-- - Are in categories 1, 2, or 3
-- - Have price between $50 and $500
-- - Name contains 'Pro' OR starts with 'Dell'
-- - Stock > 10
-- - SupplierID IS NOT NULL


-- Exercise 10.2: Customer Analysis
-- Find customers who:
-- - Last name starts with A-M
-- - Have placed at least one order (use EXISTS)
-- - Live in specific cities (use IN)


-- Exercise 10.3: Date Range Analysis
-- Find orders that:
-- - Were placed in the last 90 days
-- - Have total amount > $200
-- - CustomerID NOT IN (specific exclusion list)


-- Exercise 10.4: Advanced Pattern Matching
-- Find products where:
-- - Name matches pattern: starts with letter, contains number, ends with 'Pro'
-- - Price NOT BETWEEN $100 AND $1000
-- - Category name contains 'Electronic' (use JOIN)


-- Exercise 10.5: NULL-Safe Reporting
-- Create a report showing:
-- - Product name
-- - Supplier name (or 'No Supplier' if NULL)
-- - Price (or 'Price TBD' if NULL)
-- - Stock status: 'Out of Stock', 'Low Stock' (<20), 'In Stock'


-- Exercise 10.6: Multi-Table Filtering
-- Find customers who:
-- - Have placed orders in the last 60 days
-- - Have total order amount > $1000 (across all orders)
-- - Last name NOT LIKE 'Test%'


-- Exercise 10.7: Complex Business Logic
-- Find products that meet ALL criteria:
-- - (Category 1 AND Price > 200) OR (Category 2 AND Price > 500)
-- - Stock BETWEEN 10 AND 100
-- - Name does NOT contain 'Refurbished'
-- - Created in current year
-- - Supplier IS NOT NULL


-- Exercise 10.8: Exclusion Logic
-- Find products that are:
-- - NOT in categories 3, 4, 5
-- - NOT priced in the range $75-$125
-- - NOT named containing 'Budget' or 'Economy'
-- - Stock NOT NULL


-- Exercise 10.9: Performance-Optimized Search
-- Rewrite this slow query for better performance:
-- SELECT * FROM Products WHERE ProductName LIKE '%Laptop%'
-- HINT: Can you use a different approach for leading wildcard?


-- Exercise 10.10: Real-World Scenario
-- Create a comprehensive product filter for an e-commerce site:
-- - Category: User selects from list (use IN)
-- - Price range: Min and max (use BETWEEN)
-- - Keyword search: Product name (use LIKE)
-- - In stock only: Stock > 0
-- - Exclude refurbished: Name NOT LIKE
-- - Sort by: Price ascending, NULLs last


/*============================================
   BONUS CHALLENGES
   Advanced filtering scenarios
============================================*/

-- Bonus 1: Find customers who ordered in ALL of these categories: 1, 2, 3
-- (Must have orders in all three, not just any)


-- Bonus 2: Find products that have never been ordered but are in stock


-- Bonus 3: Find the top 5 customers by total order amount who:
-- - Have placed > 3 orders
-- - Last name NOT in ('Test', 'Demo', 'Sample')
-- - Have ordered in the last 180 days


-- Bonus 4: Create a single query that categorizes ALL products into:
-- - 'Premium': Price > $500 AND in stock
-- - 'Mid-Range': Price $100-$500
-- - 'Budget': Price < $100
-- - 'Out of Stock': Stock = 0 or NULL
-- - 'No Price': Price IS NULL


-- Bonus 5: Find products where:
-- - Price is within 10% of category average price
-- - Stock is above category median stock
-- - Name does NOT match any previously sold product names


/*============================================
   ANSWER KEY
   (Try exercises first!)
============================================*/

-- Answers provided in separate file: 10-test-answers.sql

/*============================================
   SCORING GUIDE
============================================*/

/*
   Section 1-4:  20 exercises × 2 points = 40 points
   Section 5-9:  35 exercises × 4 points = 140 points
   Section 10:   10 exercises × 10 points = 100 points
   Bonus:        5 exercises × 20 points = 100 points
   
   TOTAL: 380 points possible
   
   Grading Scale:
   340-380 (90-100%): Expert
   300-339 (79-89%):  Advanced
   260-299 (68-78%):  Proficient
   220-259 (58-67%):  Intermediate
   180-219 (47-57%):  Developing
   < 180 (<47%):      Review Chapter 04
*/

/*============================================
   END OF CHAPTER 04: FILTERING
   
   Next Chapter: 05 - Querying Multiple Tables
============================================*/
