/*============================================
   LESSON 09: TEST YOUR KNOWLEDGE
   Chapter 05: Querying Multiple Tables
   
   Estimated Time: 45 minutes
   Difficulty: Beginner to Advanced
============================================*/

USE RetailStore;
GO

/*============================================
   SECTION 1: BASIC TWO-TABLE JOINS
   Test fundamental join concepts
============================================*/

-- Exercise 1.1: List all products with their category names


-- Exercise 1.2: Show customers who have placed orders


-- Exercise 1.3: Display products with their supplier names (only products that have suppliers)


-- Exercise 1.4: Find orders with customer names, sorted by date


-- Exercise 1.5: List products with price > $100 and their categories


/*============================================
   SECTION 2: FILTERING JOINED RESULTS
   WHERE clause with joins
============================================*/

-- Exercise 2.1: Products in 'Electronics' category


-- Exercise 2.2: Orders placed in the last 90 days with customer information


-- Exercise 2.3: Products between $50-$200 with category and supplier


-- Exercise 2.4: Customers who placed orders worth more than $500


-- Exercise 2.5: Products with low stock (<20) including category name


/*============================================
   SECTION 3: AGGREGATION WITH JOINS
   GROUP BY and aggregates
============================================*/

-- Exercise 3.1: Count products per category


-- Exercise 3.2: Total sales amount per customer


-- Exercise 3.3: Average product price per category


-- Exercise 3.4: Count orders per customer in the last year


-- Exercise 3.5: Total revenue per product (use OrderDetails)


-- Exercise 3.6: Find categories with more than 10 products


/*============================================
   SECTION 4: THREE-TABLE JOINS
   Combining three tables
============================================*/

-- Exercise 4.1: Products with category and supplier names


-- Exercise 4.2: Orders with customer names and order details


-- Exercise 4.3: Order details with customer, product, and category info


-- Exercise 4.4: Products sold with quantity and customer who bought them


-- Exercise 4.5: Total revenue by category (Orders → OrderDetails → Products → Categories)


/*============================================
   SECTION 5: FOUR+ TABLE JOINS
   Complex multi-table queries
============================================*/

-- Exercise 5.1: Complete order report
-- (Customers, Orders, OrderDetails, Products, Categories)


-- Exercise 5.2: Customer purchase history with product categories
-- Show customer name, order date, product name, category, quantity


-- Exercise 5.3: Sales analysis with all details
-- Include customer, product, category, supplier in one query


-- Exercise 5.4: Revenue report by customer and category
-- Aggregate sales grouped by customer and category


/*============================================
   SECTION 6: DERIVED TABLES (SUBQUERIES)
   Using subqueries in FROM clause
============================================*/

-- Exercise 6.1: Show customers with above-average order count


-- Exercise 6.2: Products with above-average price per category


-- Exercise 6.3: Top 5 customers by total spending
-- Use derived table to calculate totals, then rank


-- Exercise 6.4: Categories with average product price > $100


-- Exercise 6.5: Monthly sales summary
-- Create derived table with monthly aggregates


/*============================================
   SECTION 7: USING SAME TABLE TWICE
   Multiple references to one table
============================================*/

-- Exercise 7.1: Compare products - find products cheaper than Product ID 1


-- Exercise 7.2: Find product pairs in same category


-- Exercise 7.3: Products with similar prices (within $20)


-- Exercise 7.4: Customers from same city


-- Exercise 7.5: Products bought together in same order


/*============================================
   SECTION 8: SELF JOINS
   Hierarchical data
============================================*/

-- Exercise 8.1: List all employees with their manager names


-- Exercise 8.2: Find employees without managers (top-level)


-- Exercise 8.3: Count direct reports for each manager


-- Exercise 8.4: Employees earning more than their manager


-- Exercise 8.5: Show employee, manager, and manager's manager


-- Exercise 8.6: Find employees with same manager (peers)


-- Exercise 8.7: Calculate average team salary for each manager


/*============================================
   SECTION 9: MIXED CHALLENGES
   Combining multiple concepts
============================================*/

-- Exercise 9.1: Customer Segmentation
-- Categorize customers as VIP (>$1000 spent), Premium ($500-$1000), Standard (<$500)
-- Use derived table and joins


-- Exercise 9.2: Product Performance Report
-- Show product name, category, times sold, total quantity, total revenue
-- Only products sold at least 5 times


-- Exercise 9.3: Inventory Value Analysis
-- Calculate total inventory value per category (Price × StockQuantity)
-- Include category name and supplier count


-- Exercise 9.4: Customer Purchase Frequency
-- Find customers who ordered in consecutive months
-- (Advanced: requires self-join on Orders)


-- Exercise 9.5: Cross-Sell Analysis
-- Find top 10 product pairs bought together
-- (Products, OrderDetails self-join)


/*============================================
   SECTION 10: REAL-WORLD SCENARIOS
   Business intelligence queries
============================================*/

-- Exercise 10.1: Executive Sales Dashboard
-- Create comprehensive report with:
-- - Total revenue
-- - Total orders
-- - Average order value
-- - Top category by revenue
-- - Top customer by spending


-- Exercise 10.2: Inventory Alert System
-- Find products that are:
-- - Low stock (< 20 units)
-- - Have been sold in last 30 days
-- - Include category, supplier, last order date


-- Exercise 10.3: Customer Retention Analysis
-- Find customers who:
-- - Placed first order more than 6 months ago
-- - Placed last order within last 30 days
-- - Total orders > 5


-- Exercise 10.4: Product Recommendation Engine
-- For a given product (Product ID 1), find:
-- - Products in same category
-- - Similar price range (±20%)
-- - Different supplier
-- - Sorted by price similarity


-- Exercise 10.5: Sales Trend Analysis
-- Compare revenue by month for current vs previous year
-- Use derived tables to aggregate by year and month


-- Exercise 10.6: Supplier Performance
-- For each supplier, show:
-- - Number of products
-- - Total products sold
-- - Total revenue generated
-- - Average product price


-- Exercise 10.7: Category Profitability
-- Calculate for each category:
-- - Number of products
-- - Total inventory value
-- - Total revenue (sales)
-- - Revenue per product average


-- Exercise 10.8: Customer Lifetime Value
-- For each customer, calculate:
-- - First order date
-- - Last order date
-- - Days as customer
-- - Total orders
-- - Total spent
-- - Average order value
-- - Orders per month


-- Exercise 10.9: Manager Team Analysis
-- For each manager with direct reports:
-- - Manager name
-- - Number of direct reports
-- - Average team salary
-- - Highest paid team member
-- - Lowest paid team member
-- - Salary range


-- Exercise 10.10: Product Substitution Matrix
-- For each product, find suitable alternatives:
-- - Same category
-- - Price within ±15%
-- - Different supplier
-- - Currently in stock


/*============================================
   BONUS CHALLENGES
   Advanced join scenarios
============================================*/

-- Bonus 1: Gap Analysis
-- Find categories that have no products priced between $100-$200


-- Bonus 2: Orphaned Records Detection
-- Find products referencing non-existent categories or suppliers


-- Bonus 3: Circular Reference Check
-- Find if any employee is their own manager (should be none!)


-- Bonus 4: Market Basket Analysis
-- Find the top 5 three-product combinations purchased together


-- Bonus 5: Hierarchical Sales Roll-up
-- If categories had parent categories, roll up sales to parent level
-- (Simulated: Show sales by main category even if sold as subcategory)


-- Bonus 6: Customer Cohort Analysis
-- Group customers by month of first purchase
-- Show retention rate (still buying 3+ months later)


-- Bonus 7: Running Total by Category
-- Show cumulative revenue by category over time
-- (Use window functions with joins)


-- Bonus 8: Price Optimization
-- Find products where reducing price by 10% might increase volume
-- (Products with high price, low sales, high stock)


/*============================================
   ANSWER KEY HINTS
   (Try exercises first!)
============================================*/

-- Hint 1.1: Use INNER JOIN Products and Categories ON CategoryID
-- Hint 2.3: Three-table join with WHERE clause for price range
-- Hint 3.2: GROUP BY CustomerID, use SUM(TotalAmount)
-- Hint 4.5: Four-table join with GROUP BY CategoryID
-- Hint 6.1: Derived table with COUNT grouped by CustomerID, compare to AVG
-- Hint 7.5: Self-join OrderDetails on OrderID where ProductID differs
-- Hint 8.4: Self-join Employees, WHERE emp.Salary > mgr.Salary
-- Hint 9.5: Self-join OrderDetails twice for product pairs

/*============================================
   SCORING GUIDE
============================================*/

/*
   Section 1-3:  15 exercises × 3 points  = 45 points
   Section 4-5:  9 exercises × 5 points   = 45 points
   Section 6:    5 exercises × 6 points   = 30 points
   Section 7-8:  12 exercises × 6 points  = 72 points
   Section 9:    5 exercises × 10 points  = 50 points
   Section 10:   10 exercises × 15 points = 150 points
   Bonus:        8 exercises × 25 points  = 200 points
   
   TOTAL: 592 points possible
   
   Grading Scale:
   500-592 (84-100%): Expert
   440-499 (74-83%):  Advanced
   380-439 (64-73%):  Proficient
   320-379 (54-63%):  Intermediate
   260-319 (44-53%):  Developing
   < 260 (<44%):      Review Chapter 05
*/

/*============================================
   COMMON PATTERNS TO REMEMBER
============================================*/

-- Pattern 1: Simple Join
/*
SELECT columns
FROM table1 t1
INNER JOIN table2 t2 ON t1.fk = t2.pk;
*/

-- Pattern 2: Join with Filter
/*
SELECT columns
FROM table1 t1
INNER JOIN table2 t2 ON t1.fk = t2.pk
WHERE condition;
*/

-- Pattern 3: Join with Aggregate
/*
SELECT t1.column, COUNT(t2.column)
FROM table1 t1
INNER JOIN table2 t2 ON t1.fk = t2.pk
GROUP BY t1.column;
*/

-- Pattern 4: Multiple Joins
/*
SELECT columns
FROM table1 t1
INNER JOIN table2 t2 ON t1.fk1 = t2.pk
INNER JOIN table3 t3 ON t2.fk2 = t3.pk;
*/

-- Pattern 5: Derived Table
/*
SELECT *
FROM (
    SELECT column, AGG(column) AS agg
    FROM table
    GROUP BY column
) AS derived
WHERE agg > value;
*/

-- Pattern 6: Self Join
/*
SELECT e1.name, e2.name AS manager
FROM Employees e1
LEFT JOIN Employees e2 ON e1.ManagerID = e2.EmployeeID;
*/

/*============================================
   END OF CHAPTER 05: QUERYING MULTIPLE TABLES
   
   Next Chapter: 06 - Working with Sets
============================================*/
