-- =============================================
-- Lesson 10: Test Your Knowledge
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Comprehensive exercises covering all set operations
-- Estimated Time: 60 minutes
-- Total Points: 500
-- =============================================

USE RetailStore;
GO

/*
INSTRUCTIONS:
1. Read each question carefully
2. Write your query below the question
3. Test your query and verify the results
4. Check your answers against expected output
5. Each section builds on previous knowledge

SCORING:
• Section 1-3: 5 points each (basics)
• Section 4-6: 8 points each (intermediate)
• Section 7-9: 10 points each (advanced)
• Section 10: 15 points each (real-world)
• Bonus: 20 points each (expert level)

TOTAL: 500 points possible
*/

-- =============================================
-- SECTION 1: UNION Basics (5 points each)
-- =============================================

-- Q1.1: Combine all product names and category names into one list
-- Expected: Single column with all names (no duplicates)
-- Points: 5
-- YOUR QUERY:



-- Q1.2: Combine products from CategoryID 1 and CategoryID 2 using UNION ALL
-- Expected: All products from both categories (keep duplicates if any)
-- Points: 5
-- YOUR QUERY:



-- Q1.3: Create a list of all emails from Customers and Suppliers (remove duplicates)
-- Expected: Single column of unique emails
-- Points: 5
-- YOUR QUERY:



-- Q1.4: Combine OrderID and CustomerID from Orders with ProductID and CategoryID from Products
-- Add a column indicating the source ('Order' or 'Product')
-- Expected: ID, ParentID, Source columns
-- Points: 5
-- YOUR QUERY:



-- Q1.5: Union products with Price > 100 and products with Price < 20
-- Sort by price descending
-- Expected: Sorted list of expensive and cheap products
-- Points: 5
-- YOUR QUERY:



-- =============================================
-- SECTION 2: INTERSECT Basics (5 points each)
-- =============================================

-- Q2.1: Find customers who ordered in both January AND February 2025
-- Expected: CustomerID list
-- Points: 5
-- YOUR QUERY:



-- Q2.2: Find products that exist in CategoryID 1 AND have been ordered
-- Expected: ProductID, ProductName
-- Points: 5
-- YOUR QUERY:



-- Q2.3: Find product IDs that appear in both Products and OrderDetails
-- Expected: List of ProductIDs that have been ordered
-- Points: 5
-- YOUR QUERY:



-- Q2.4: Find customers who ordered in Q1 AND Q2 AND Q3
-- Expected: Loyal customers who ordered in all three quarters
-- Points: 5
-- YOUR QUERY:



-- Q2.5: Find emails that exist in both Customers and Suppliers tables
-- Expected: Shared email addresses
-- Points: 5
-- YOUR QUERY:



-- =============================================
-- SECTION 3: EXCEPT Basics (5 points each)
-- =============================================

-- Q3.1: Find products that have NEVER been ordered
-- Expected: ProductID, ProductName of unsold products
-- Points: 5
-- YOUR QUERY:



-- Q3.2: Find customers who ordered in 2024 but NOT in 2025
-- Expected: Lost/inactive customers
-- Points: 5
-- YOUR QUERY:



-- Q3.3: Find products in CategoryID 1 that cost $100 or less
-- Use EXCEPT to exclude expensive products
-- Expected: Affordable electronics
-- Points: 5
-- YOUR QUERY:



-- Q3.4: Find all customers EXCEPT those who have placed orders
-- Expected: Customers who never purchased
-- Points: 5
-- YOUR QUERY:



-- Q3.5: Find ProductIDs in Products EXCEPT ProductIDs in OrderDetails
-- Sort by ProductID
-- Expected: Never-ordered products sorted
-- Points: 5
-- YOUR QUERY:



-- =============================================
-- SECTION 4: UNION with Calculations (8 points each)
-- =============================================

-- Q4.1: Create a monthly revenue report using UNION ALL for Jan, Feb, Mar 2025
-- Include: Month name, Total Revenue, Order Count
-- Expected: 3 rows with monthly summaries
-- Points: 8
-- YOUR QUERY:



-- Q4.2: Combine top 5 most expensive products with top 5 least expensive products
-- Include: ProductName, Price, Category ('Expensive' or 'Cheap')
-- Expected: 10 products total
-- Points: 8
-- YOUR QUERY:



-- Q4.3: Create a contact list combining Customers and Suppliers
-- Include: Name, Email, Type, City (use NULL if not available)
-- Sort by Type then Name
-- Expected: Combined contact directory
-- Points: 8
-- YOUR QUERY:



-- Q4.4: Union all CategoryIDs from Products with a manually created set of IDs (1,2,3,4,5)
-- Show which IDs exist in Products and which don't
-- Expected: List showing gaps in CategoryID usage
-- Points: 8
-- YOUR QUERY:



-- Q4.5: Create a summary combining:
-- - Total products per category
-- - Total orders per customer
-- Include: Entity name, Count, Type ('Category' or 'Customer')
-- Expected: Mixed summary report
-- Points: 8
-- YOUR QUERY:



-- =============================================
-- SECTION 5: INTERSECT with Joins (8 points each)
-- =============================================

-- Q5.1: Find products ordered by Customer 1 AND Customer 2
-- Expected: Products ordered by both customers
-- Points: 8
-- YOUR QUERY:



-- Q5.2: Find customers who ordered products from ALL categories
-- Hint: Use INTERSECT for each category
-- Expected: Customers with diverse orders
-- Points: 8
-- YOUR QUERY:



-- Q5.3: Find products in CategoryID 1 that were ordered in January 2025
-- AND also ordered in February 2025
-- Expected: Consistently popular products
-- Points: 8
-- YOUR QUERY:



-- Q5.4: Find CustomerIDs who have orders with TotalAmount > 100
-- AND have ordered products from CategoryID 1
-- Expected: High-value electronics customers
-- Points: 8
-- YOUR QUERY:



-- Q5.5: Find products that are:
-- - In CategoryID 1
-- - Price between $50 and $200
-- - Have been ordered at least once
-- Use INTERSECT for all three conditions
-- Expected: Popular mid-range products
-- Points: 8
-- YOUR QUERY:



-- =============================================
-- SECTION 6: EXCEPT with Analysis (8 points each)
-- =============================================

-- Q6.1: Find customers who ordered in January but NOT in February
-- Show customer details
-- Expected: Customers who stopped ordering
-- Points: 8
-- YOUR QUERY:



-- Q6.2: Find products in CategoryID 1 EXCEPT those that cost more than $500
-- Expected: Affordable electronics
-- Points: 8
-- YOUR QUERY:



-- Q6.3: Find all possible ProductIDs (1 through max ProductID)
-- EXCEPT ProductIDs that exist in Products table
-- Shows gaps in ProductID sequence
-- Expected: Missing ProductID values
-- Points: 8
-- YOUR QUERY:



-- Q6.4: Find orders from 2025 EXCEPT orders that include products from CategoryID 1
-- Expected: Orders with no electronics
-- Points: 8
-- YOUR QUERY:



-- Q6.5: Find customers who have placed orders
-- EXCEPT customers whose total spending is > $500
-- Expected: Low-value customers
-- Points: 8
-- YOUR QUERY:



-- =============================================
-- SECTION 7: Complex Set Operations (10 points each)
-- =============================================

-- Q7.1: Find products that are:
-- (In CategoryID 1 OR CategoryID 2) AND (Price > $100) EXCEPT (Already Ordered)
-- Use proper parentheses
-- Expected: Unordered expensive electronics/books
-- Points: 10
-- YOUR QUERY:



-- Q7.2: Find customers who:
-- Ordered in (January OR February) AND spent > $200 total
-- EXCEPT customers with complaints
-- Expected: Good high-value customers
-- Points: 10
-- YOUR QUERY:



-- Q7.3: Create a Venn diagram query showing:
-- - Products in CategoryID 1 only
-- - Products with Price > 100 only
-- - Products in BOTH
-- Label each section
-- Expected: 3 result sets showing overlap
-- Points: 10
-- YOUR QUERY:



-- Q7.4: Find ProductIDs where:
-- (Ordered in Jan OR Ordered in Feb) INTERSECT (Price < $100)
-- Expected: Affordable popular products
-- Points: 10
-- YOUR QUERY:



-- Q7.5: Build a complex query with at least 4 set operations
-- Using UNION, INTERSECT, and EXCEPT with proper parentheses
-- Expected: Meaningful business result of your choice
-- Points: 10
-- YOUR QUERY:



-- =============================================
-- SECTION 8: Set Operations with Sorting (10 points each)
-- =============================================

-- Q8.1: Combine all products and categories into one list
-- Sort by name, but put categories first, then products
-- Hint: Add a sort order column
-- Expected: Categories, then products, alphabetically within each
-- Points: 10
-- YOUR QUERY:



-- Q8.2: Create top 5 products from each category using UNION ALL
-- Sort the final result by Price DESC
-- Expected: 15 products total (5 per category) sorted by price
-- Points: 10
-- YOUR QUERY:



-- Q8.3: Combine customers with no orders and products never ordered
-- Create unified "Inactive" report with Type, Name, Reason
-- Sort by Type then Name
-- Expected: Combined inactive items report
-- Points: 10
-- YOUR QUERY:



-- Q8.4: Create a quarterly comparison:
-- Show CustomerID, Quarter, OrderCount for Q1, Q2, Q3
-- Use UNION ALL and sort by CustomerID, Quarter
-- Expected: Customer ordering patterns by quarter
-- Points: 10
-- YOUR QUERY:



-- Q8.5: Build a price range report:
-- Group products into ranges (0-50, 51-100, 101-200, 201+)
-- Count products in each range using UNION ALL
-- Sort by range
-- Expected: Product distribution by price range
-- Points: 10
-- YOUR QUERY:



-- =============================================
-- SECTION 9: Set Operation Precedence (10 points each)
-- =============================================

-- Q9.1: Write and compare:
-- (A UNION B) EXCEPT C
-- vs
-- A UNION (B EXCEPT C)
-- Where A = CategoryID 1, B = CategoryID 2, C = Price > 200
-- Expected: Two different results with explanation
-- Points: 10
-- YOUR QUERY:



-- Q9.2: Create a nested query:
-- ((Cat1 UNION Cat2) INTERSECT Price>50) EXCEPT AlreadyOrdered
-- Use proper parentheses
-- Expected: Available mid-range products from categories 1 and 2
-- Points: 10
-- YOUR QUERY:



-- Q9.3: Build a 3-level nested set operation
-- Innermost: UNION
-- Middle: INTERSECT
-- Outer: EXCEPT
-- Expected: Complex filtered result
-- Points: 10
-- YOUR QUERY:



-- Q9.4: Compare performance:
-- Set operation version vs JOIN/WHERE version
-- Find products in Cat 1 AND Price > 100
-- Use SET STATISTICS TIME ON
-- Expected: Both queries with time comparison
-- Points: 10
-- YOUR QUERY:



-- Q9.5: Create a query mixing UNION ALL, INTERSECT, and EXCEPT
-- With at least 5 subqueries and proper precedence control
-- Expected: Complex business logic query
-- Points: 10
-- YOUR QUERY:



-- =============================================
-- SECTION 10: Real-World Scenarios (15 points each)
-- =============================================

-- Q10.1: Customer Segmentation
-- Segment customers into:
-- - VIPs: Total orders > $1000
-- - Regular: Total orders $100-$1000
-- - Occasional: Total orders < $100
-- - Never Ordered: No orders
-- Use UNION ALL to combine all segments
-- Expected: All customers categorized
-- Points: 15
-- YOUR QUERY:



-- Q10.2: Product Performance Analysis
-- Create a report showing:
-- - Best sellers (ordered more than 10 times)
-- - Slow movers (ordered 1-5 times)
-- - Never sold (never ordered)
-- Include: ProductName, Category, Status, OrderCount
-- Expected: Complete product analysis
-- Points: 15
-- YOUR QUERY:



-- Q10.3: Customer Retention Analysis
-- Find customers who:
-- - Ordered in Q1 2024
-- - But did NOT order in Q2, Q3, or Q4 2024
-- - Show: CustomerName, LastOrderDate, TotalSpent
-- Expected: Churned customers from Q1
-- Points: 15
-- YOUR QUERY:



-- Q10.4: Inventory Gap Analysis
-- Find products that should be reordered:
-- - In Products table (we sell them)
-- - Ordered in last 90 days (popular)
-- - BUT stock quantity < 10 (low inventory)
-- Expected: Products needing restock
-- Points: 15
-- YOUR QUERY:



-- Q10.5: Cross-Sell Opportunity
-- Find customers who:
-- - Ordered from CategoryID 1
-- - Never ordered from CategoryID 2
-- - Total spending > $500
-- Expected: Electronics customers who might buy books
-- Points: 15
-- YOUR QUERY:



-- Q10.6: Data Quality Check
-- Find discrepancies:
-- - OrderDetails with ProductIDs not in Products (orphaned)
-- - Products with CategoryIDs not in Categories (orphaned)
-- - Orders with CustomerIDs not in Customers (orphaned)
-- Expected: Data integrity report
-- Points: 15
-- YOUR QUERY:



-- =============================================
-- BONUS CHALLENGES (20 points each)
-- =============================================

-- BONUS 1: Create a complete customer lifecycle report
-- Show customers in each stage:
-- - Prospects (in mailing list, never ordered)
-- - New (first order in last 30 days)
-- - Active (ordered in last 90 days)
-- - At Risk (last order 90-180 days ago)
-- - Churned (last order > 180 days ago)
-- Include counts and revenue for each stage
-- Points: 20
-- YOUR QUERY:



-- BONUS 2: Product Category Migration
-- Find products that:
-- - Were in CategoryID 1 in 2024
-- - But are now in different category in 2025
-- - Or were removed entirely
-- Show: ProductID, OldCategory, NewCategory, Status
-- Points: 20
-- YOUR QUERY:



-- BONUS 3: Market Basket Analysis
-- Find products frequently bought together:
-- - Products ordered by same customer
-- - In same order
-- - Exclude single-item orders
-- Use set operations to find common combinations
-- Points: 20
-- YOUR QUERY:



-- BONUS 4: Advanced Set Theory
-- Implement: (A ∪ B) ∩ (C ∪ D) - (E ∩ F)
-- Where:
-- A = Products CategoryID 1
-- B = Products CategoryID 2
-- C = Price > 50
-- D = Price < 200
-- E = Ordered products
-- F = Stock < 5
-- Expected: Available mid-range products from cat 1 or 2
-- Points: 20
-- YOUR QUERY:



-- BONUS 5: Performance Optimization Challenge
-- Rewrite this set operation query as a single SELECT with JOIN/WHERE:
/*
SELECT CustomerID FROM Orders WHERE OrderDate > '2025-01-01'
INTERSECT
SELECT CustomerID FROM Orders GROUP BY CustomerID HAVING SUM(TotalAmount) > 500
EXCEPT
SELECT CustomerID FROM Complaints
*/
-- Compare performance with SET STATISTICS TIME ON
-- Points: 20
-- YOUR QUERY:



-- =============================================
-- ANSWER KEY & SCORING
-- =============================================
/*
SCORING GUIDE:
0-200 points: Review chapters 1-6
201-300 points: Good understanding, practice more
301-400 points: Very good! Ready for advanced topics
401-500 points: Excellent! Master of set operations

SELF-ASSESSMENT:
□ I understand UNION vs UNION ALL
□ I can use INTERSECT effectively
□ I know when to use EXCEPT
□ I can handle column count/type matching
□ I understand precedence and parentheses
□ I can combine multiple set operations
□ I can optimize set queries
□ I can solve real-world problems

NEXT STEPS:
- Review missed questions
- Practice with larger datasets
- Move to Chapter 07: Data Generation and Manipulation
*/

-- =============================================
-- Hints for Difficult Questions
-- =============================================
/*
HINTS:

Q5.2 (Customers who ordered from ALL categories):
- Use INTERSECT for each category
- Category 1 INTERSECT Category 2 INTERSECT Category 3

Q6.3 (Find gaps in ProductID):
- Generate sequence of numbers 1 to MAX(ProductID)
- EXCEPT existing ProductIDs

Q7.3 (Venn diagram):
- Query 1: A only (A EXCEPT B)
- Query 2: B only (B EXCEPT A)
- Query 3: Both (A INTERSECT B)

Q9.4 (Performance comparison):
- Set operation: Use INTERSECT
- JOIN version: Use WHERE clause
- Compare execution times

Q10.6 (Data quality):
- Check foreign key integrity
- Find orphaned records
- Use EXCEPT to find mismatches

BONUS 4 (Complex set theory):
- Work inside-out
- Use parentheses for each operation
- Test incrementally

Good luck!
*/
