/*============================================
   LESSON 08: TEST YOUR KNOWLEDGE
   Practice exercises for Chapter 03
   
   Estimated Time: 20 minutes
   Difficulty: Beginner
   
   Instructions:
   1. Read each question carefully
   2. Write your query below the question
   3. Run your query to verify the result
   4. Check your answers at the end
============================================*/

USE RetailStore;
GO

/*============================================
   SECTION 1: BASIC SELECT QUERIES (Easy)
============================================*/

-- Q1: Retrieve all columns from the Products table
-- Your query:


-- Q2: Get ProductName and Price for all products
-- Your query:


-- Q3: Get the first 10 customers (FirstName, LastName, Email)
-- Your query:


-- Q4: Show all unique cities from the Customers table
-- Your query:


-- Q5: Count the total number of products
-- Your query:



/*============================================
   SECTION 2: CALCULATIONS & ALIASES (Easy)
============================================*/

-- Q6: Show ProductName, Price, and Price with 15% tax (alias: PriceWithTax)
-- Your query:


-- Q7: Create full customer names (FirstName + LastName) with alias "FullName"
-- Your query:


-- Q8: Calculate inventory value for each product (Price * StockQuantity)
--     Alias as "InventoryValue"
-- Your query:


-- Q9: Show employee full names and annual salary (Salary * 12)
-- Your query:



/*============================================
   SECTION 3: WHERE CLAUSE (Medium)
============================================*/

-- Q10: Find all products with price greater than $100
-- Your query:


-- Q11: Find all customers from the USA
-- Your query:


-- Q12: Find products with stock quantity less than 20
-- Your query:


-- Q13: Find products priced between $50 and $200 (use BETWEEN)
-- Your query:


-- Q14: Find customers from USA, UK, or Canada (use IN)
-- Your query:


-- Q15: Find products with names starting with 'L'
-- Your query:


-- Q16: Find products that do NOT have a supplier (SupplierID IS NULL)
-- Your query:


-- Q17: Find products in Electronics category (CategoryID = 1) with price > $50
-- Your query:



/*============================================
   SECTION 4: JOINS (Medium)
============================================*/

-- Q18: Show all products with their category names
--      Columns: ProductName, CategoryName
-- Your query:


-- Q19: Show all products with category names and supplier names
--      Use LEFT JOIN for suppliers (some products may not have suppliers)
-- Your query:


-- Q20: Show customer names with their order dates
--      Columns: CustomerName (full), OrderID, OrderDate
-- Your query:


-- Q21: Show complete order details:
--      OrderID, CustomerName, ProductName, Quantity, UnitPrice, LineTotal
--      LineTotal = Quantity * UnitPrice
-- Your query:


-- Q22: Find all products in the 'Electronics' category (use JOIN + WHERE)
-- Your query:



/*============================================
   SECTION 5: GROUP BY & AGGREGATES (Medium-Hard)
============================================*/

-- Q23: Count how many products are in each category
--      Show: CategoryName, ProductCount
-- Your query:


-- Q24: Calculate average price by category
--      Show: CategoryName, AvgPrice
-- Your query:


-- Q25: Find total inventory value by category
--      Show: CategoryName, TotalValue (SUM of Price * StockQuantity)
-- Your query:


-- Q26: Count how many orders each customer has placed
--      Show: CustomerName, OrderCount
-- Your query:


-- Q27: Find the total quantity sold for each product
--      Show: ProductName, TotalQuantitySold
--      Hint: SUM(Quantity) from OrderDetails, JOIN with Products
-- Your query:



/*============================================
   SECTION 6: HAVING (Medium-Hard)
============================================*/

-- Q28: Find categories with more than 2 products
--      Show: CategoryName, ProductCount
-- Your query:


-- Q29: Find categories where average product price is over $150
--      Show: CategoryName, AvgPrice
-- Your query:


-- Q30: Find customers who have placed more than 1 order
--      Show: CustomerName, OrderCount
-- Your query:



/*============================================
   SECTION 7: ORDER BY (Easy-Medium)
============================================*/

-- Q31: Show all products sorted by price (highest first)
-- Your query:


-- Q32: Show top 5 most expensive products
-- Your query:


-- Q33: Show customers sorted by Country, then City, then LastName
-- Your query:


-- Q34: Show products sorted by inventory value (Price * StockQuantity) descending
-- Your query:


-- Q35: Show most recent 10 orders
-- Your query:



/*============================================
   SECTION 8: COMPLEX QUERIES (Hard)
============================================*/

-- Q36: Product Performance Report
--      Show: ProductName, TimesSold (count of orders), TotalRevenue
--      Only include products that have been sold
--      Sort by TotalRevenue descending
-- Your query:


-- Q37: Category Revenue Report
--      Show: CategoryName, TotalProducts, TotalRevenue
--      Include all categories even if no sales
--      Sort by TotalRevenue descending
-- Your query:


-- Q38: Customer Purchase Summary
--      Show: CustomerName, TotalOrders, TotalSpent, AverageOrderValue
--      Only customers who have placed orders
--      Sort by TotalSpent descending
-- Your query:


-- Q39: Low Stock Alert
--      Show products with stock less than 30
--      Include: ProductName, CategoryName, StockQuantity, ReorderStatus
--      ReorderStatus: 'CRITICAL' if < 10, 'LOW' if 10-29
--      Sort by StockQuantity ascending
-- Your query:


-- Q40: Monthly Sales Summary
--      Show: Year, Month, TotalOrders, TotalRevenue
--      Group by year and month
--      Sort by year and month descending
-- Your query:



/*============================================
   CHALLENGE QUESTIONS (Very Hard)
============================================*/

-- Q41: Find products that are more expensive than the average price
--      Show: ProductName, Price, AvgPrice, Difference
-- Your query:


-- Q42: Find categories where at least one product is over $500
--      Show: CategoryName, MaxPrice, ProductCount
-- Your query:


-- Q43: Customer Loyalty Report
--      Find customers who have ordered in multiple different months
--      Show: CustomerName, MonthsActive, TotalOrders, TotalSpent
-- Your query:


-- Q44: Product Pair Analysis
--      Find products that were ordered together in the same order
--      Show: Product1, Product2, TimesOrderedTogether
--      Hint: Self-join OrderDetails
-- Your query:


-- Q45: Department Salary Analysis
--      Show: DepartmentName, EmployeeCount, AvgSalary, MinSalary, MaxSalary, TotalPayroll
--      Only departments with average salary > $65,000
--      Sort by TotalPayroll descending
-- Your query:



/*============================================
   ANSWER KEY - Check Your Solutions
============================================*/

-- Answers will vary based on your data, but here are sample solutions:

-- Q1: SELECT * FROM Inventory.Products;

-- Q2: SELECT ProductName, Price FROM Inventory.Products;

-- Q10: SELECT * FROM Inventory.Products WHERE Price > 100;

-- Q18: SELECT p.ProductName, c.CategoryName 
--      FROM Inventory.Products p 
--      INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Q23: SELECT c.CategoryName, COUNT(*) AS ProductCount
--      FROM Inventory.Products p
--      INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
--      GROUP BY c.CategoryName;

-- Q28: SELECT c.CategoryName, COUNT(*) AS ProductCount
--      FROM Inventory.Products p
--      INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
--      GROUP BY c.CategoryName
--      HAVING COUNT(*) > 2;

-- Q31: SELECT ProductName, Price FROM Inventory.Products ORDER BY Price DESC;

-- Continue checking your queries against these patterns!


/*============================================
   SCORING GUIDE
   
   Questions Correct | Skill Level
   ------------------|------------------
   0-10             | Keep practicing basics
   11-20            | Good foundation
   21-30            | Solid understanding
   31-40            | Excellent!
   41-45            | SQL Master!
   
   If you got stuck:
   - Review the relevant lesson
   - Try breaking complex queries into steps
   - Run parts of the query separately
   - Check for typos in table/column names
   
   NEXT STEPS:
   - If you scored well, move to Chapter 04!
   - If you struggled, review Chapter 03 lessons
   - Practice writing your own variations
============================================*/

/*============================================
   CONGRATULATIONS!
   
   You've completed Chapter 03: Query Primer!
   
   Skills Mastered:
   ✅ Writing SELECT statements
   ✅ Filtering with WHERE
   ✅ Joining multiple tables
   ✅ Grouping and aggregating data
   ✅ Sorting results
   
   Next Chapter: Advanced Filtering Techniques
============================================*/
