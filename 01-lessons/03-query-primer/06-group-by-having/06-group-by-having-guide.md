# 📊 Lesson 06: GROUP BY & HAVING - Aggregating Data

## 📋 Overview

**Estimated Time:** 15 minutes  
**Difficulty:** Beginner  
**Prerequisites:** Lessons 01-05 completed  

**What You'll Learn:**
- Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY for grouping rows
- HAVING for filtering groups
- Difference between WHERE and HAVING
- Real-world reporting queries

---

## 🎯 Why GROUP BY?

**GROUP BY** answers summary questions like:
- "How many products per category?"
- "What's the average price by category?"
- "Total sales by customer?"

### Without GROUP BY (Individual Rows):
```sql
SELECT ProductName, Price FROM Products;
```
**Result:**
```
ProductName | Price
------------|--------
Laptop      | 1200.00
Mouse       | 25.99
Keyboard    | 75.50
```

### With GROUP BY (Summarized):
```sql
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID;
```
**Result:**
```
CategoryID | AvgPrice
-----------|----------
1          | 433.83
2          | 275.00
```

---

## 📊 Aggregate Functions

Functions that calculate across multiple rows.

| Function | Purpose | Example |
|----------|---------|---------|
| `COUNT(*)` | Count all rows | Total products |
| `COUNT(column)` | Count non-NULL values | Products with supplier |
| `SUM(column)` | Add all values | Total inventory |
| `AVG(column)` | Calculate average | Average price |
| `MIN(column)` | Find minimum | Cheapest product |
| `MAX(column)` | Find maximum | Most expensive |

### Examples:

```sql
-- Count all products
SELECT COUNT(*) AS TotalProducts
FROM Products;

-- Total inventory
SELECT SUM(StockQuantity) AS TotalStock
FROM Products;

-- Average price
SELECT AVG(Price) AS AvgPrice
FROM Products;

-- Price range
SELECT 
    MIN(Price) AS Cheapest,
    MAX(Price) AS MostExpensive
FROM Products;

-- Multiple aggregates
SELECT 
    COUNT(*) AS TotalProducts,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products;
```

### Visual: How Aggregates Work

**Raw Data:**
```
ProductID | Price
----------|--------
1         | 1200.00
2         | 25.99
3         | 75.50
4         | 350.00
```

**Aggregate Calculations:**
```
COUNT(*) = 4                     (count rows)
SUM(Price) = 1651.49             (add all)
AVG(Price) = 412.87              (sum ÷ count)
MIN(Price) = 25.99               (smallest)
MAX(Price) = 1200.00             (largest)
```

---

## 📦 GROUP BY - Grouping Rows

**Purpose:** Group rows by common values, then calculate aggregates per group.

### Syntax:
```sql
SELECT 
    grouping_column,
    AGGREGATE_FUNCTION(column)
FROM table
GROUP BY grouping_column;
```

### Example: Count Products per Category

**Before GROUP BY (Raw Data):**
```
ProductID | ProductName | CategoryID
----------|-------------|------------
1         | Laptop      | 1
2         | Mouse       | 1
3         | Keyboard    | 1
4         | Desk        | 2
5         | Chair       | 2
```

**Query:**
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;
```

**After GROUP BY (Grouped & Counted):**
```
CategoryID | ProductCount
-----------|-------------
1          | 3            ← Electronics (Laptop, Mouse, Keyboard)
2          | 2            ← Furniture (Desk, Chair)
```

### Visual: GROUP BY Process

```
Step 1: Read all rows
┌────────────┬────────────┐
│ ProductName│ CategoryID │
├────────────┼────────────┤
│ Laptop     │ 1          │
│ Mouse      │ 1          │
│ Keyboard   │ 1          │
│ Desk       │ 2          │
│ Chair      │ 2          │
└────────────┴────────────┘

Step 2: GROUP BY CategoryID
┌─────────────────┐  ┌─────────────────┐
│ CategoryID = 1  │  │ CategoryID = 2  │
├─────────────────┤  ├─────────────────┤
│ Laptop          │  │ Desk            │
│ Mouse           │  │ Chair           │
│ Keyboard        │  │                 │
└─────────────────┘  └─────────────────┘

Step 3: COUNT(*) per group
┌────────────┬──────────────┐
│ CategoryID │ ProductCount │
├────────────┼──────────────┤
│ 1          │ 3            │
│ 2          │ 2            │
└────────────┴──────────────┘
```

---

## 🎨 GROUP BY Examples

### Example 1: Average Price by Category
```sql
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID;
```

**Result:**
```
CategoryID | AvgPrice
-----------|----------
1          | 433.83
2          | 275.00
3          | 45.00
```

### Example 2: Total Inventory Value by Category
```sql
SELECT 
    CategoryID,
    SUM(Price * StockQuantity) AS TotalValue
FROM Products
GROUP BY CategoryID;
```

**Result:**
```
CategoryID | TotalValue
-----------|------------
1          | 52500.00
2          | 18000.00
3          | 1200.00
```

### Example 3: Multiple Aggregates
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products
GROUP BY CategoryID;
```

---

## 🔗 GROUP BY with JOINs

Show descriptive names instead of IDs.

### Without JOIN (Just IDs):
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;
```
**Result:**
```
CategoryID | ProductCount
-----------|-------------
1          | 5
2          | 2
```

### With JOIN (Descriptive Names):
```sql
SELECT 
    c.CategoryName,
    COUNT(*) AS ProductCount,
    AVG(p.Price) AS AvgPrice
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;
```
**Result:**
```
CategoryName | ProductCount | AvgPrice
-------------|--------------|----------
Electronics  | 5            | 433.83
Furniture    | 2            | 275.00
Clothing     | 1            | 45.00
```

**Much better!** Names are more meaningful than IDs.

---

## 📦 GROUP BY Multiple Columns

Create sub-groups within groups.

### Example: Customers by Country and City
```sql
SELECT 
    Country,
    City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY Country, City
ORDER BY Country, City;
```

**Result:**
```
Country | City        | CustomerCount
--------|-------------|---------------
Canada  | Toronto     | 2
Canada  | Vancouver   | 1
UK      | London      | 3
USA     | Chicago     | 2
USA     | New York    | 5
USA     | Los Angeles | 3
```

### Visual: Multi-Column Grouping

```
First GROUP BY Country:
├── USA
│   └── Then GROUP BY City:
│       ├── New York (5)
│       ├── Chicago (2)
│       └── Los Angeles (3)
├── UK
│   └── Then GROUP BY City:
│       └── London (3)
└── Canada
    └── Then GROUP BY City:
        ├── Toronto (2)
        └── Vancouver (1)
```

---

## 🎯 HAVING - Filter Groups

**HAVING** filters groups AFTER aggregation (like WHERE for groups).

### Syntax:
```sql
SELECT column, AGGREGATE_FUNCTION(column)
FROM table
GROUP BY column
HAVING aggregate_condition;
```

### Example: Categories with More Than 2 Products
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 2;
```

**Result:**
```
CategoryID | ProductCount
-----------|-------------
1          | 5            ← Included (5 > 2)
(CategoryID 2 excluded because count = 2, not > 2)
```

### Example: Categories with High Average Price
```sql
SELECT 
    c.CategoryName,
    AVG(p.Price) AS AvgPrice
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
HAVING AVG(Price) > 100;
```

---

## ⚖️ WHERE vs HAVING

**Critical Difference:**

| Aspect | WHERE | HAVING |
|--------|-------|--------|
| **Filters** | Individual rows | Groups |
| **When** | BEFORE grouping | AFTER grouping |
| **Can Use** | Column values | Aggregate functions |
| **Example** | `WHERE Price > 50` | `HAVING AVG(Price) > 100` |

### Visual: WHERE vs HAVING Flow

```
All Rows (1000)
      ↓
WHERE Price > 50  ← Filter individual rows
      ↓
Filtered Rows (300)
      ↓
GROUP BY CategoryID  ← Group remaining rows
      ↓
Groups (3 categories)
      ↓
HAVING COUNT(*) > 2  ← Filter groups
      ↓
Final Groups (2 categories)
      ↓
Results
```

### Example: Using Both Together

```sql
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
WHERE Price > 50          -- Filter rows: only products over $50
GROUP BY CategoryID       -- Group by category
HAVING COUNT(*) > 2;      -- Filter groups: only categories with 2+ products
```

**Execution Order:**
1. **WHERE**: Filter products to only those > $50
2. **GROUP BY**: Group remaining products by category
3. **HAVING**: Keep only categories with 2+ products
4. **SELECT**: Calculate AVG and COUNT for each group

---

## 📊 Real-World Examples

### Example 1: Total Sales by Customer
```sql
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;
```

**Result:**
```
CustomerName | TotalOrders | TotalSpent
-------------|-------------|------------
John Doe     | 5           | 3250.00
Jane Smith   | 3           | 1875.50
Mike Johnson | 2           | 950.00
```

### Example 2: Monthly Sales Summary
```sql
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear DESC, OrderMonth DESC;
```

### Example 3: Product Performance
```sql
SELECT 
    p.ProductName,
    COUNT(od.OrderDetailID) AS TimesSold,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(od.OrderDetailID) > 0  -- Only products that sold
ORDER BY TotalRevenue DESC;
```

---

## 🔢 COUNT Variations

Different ways to count:

```sql
-- Count all rows (includes NULLs)
SELECT COUNT(*) AS AllRows 
FROM Products;

-- Count non-NULL values in column
SELECT COUNT(SupplierID) AS WithSupplier 
FROM Products;

-- Count distinct values
SELECT COUNT(DISTINCT CategoryID) AS UniqueCategories 
FROM Products;

-- Compare counts
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(SupplierID) AS WithSupplier,
    COUNT(*) - COUNT(SupplierID) AS WithoutSupplier,
    COUNT(DISTINCT CategoryID) AS UniqueCategories
FROM Products;
```

**Result:**
```
TotalProducts | WithSupplier | WithoutSupplier | UniqueCategories
--------------|--------------|-----------------|------------------
8             | 6            | 2               | 3
```

---

## 🧪 Practice Exercises

### Exercise 1: Basic Aggregation
Count products in each category (show category names)
```sql
-- Your answer:
```

### Exercise 2: SUM by Group
Calculate total stock quantity by category
```sql
-- Your answer:
```

### Exercise 3: HAVING Filter
Find categories with more than 3 products
```sql
-- Your answer:
```

### Exercise 4: WHERE + GROUP BY
Count products over $50, grouped by category
```sql
-- Your answer:
```

### Exercise 5: Complex Report
Show total revenue by customer (only customers who spent > $500)
```sql
-- Your answer:
```

---

## 🎯 Key Takeaways

| Concept | Purpose | Example |
|---------|---------|---------|
| **COUNT(*)** | Count all rows | Total products |
| **SUM()** | Add values | Total inventory |
| **AVG()** | Calculate average | Average price |
| **MIN/MAX()** | Find extremes | Price range |
| **GROUP BY** | Group rows | By category, customer, date |
| **HAVING** | Filter groups | Only groups with count > 5 |

### Remember:
✅ GROUP BY groups rows for aggregation  
✅ WHERE filters BEFORE grouping  
✅ HAVING filters AFTER grouping  
✅ Use JOINs to show names instead of IDs  
✅ Can group by multiple columns  

### Execution Order:
```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
```

---

## 🚀 What's Next?

You now understand:
✅ All aggregate functions  
✅ Grouping data with GROUP BY  
✅ Filtering groups with HAVING  
✅ WHERE vs HAVING  
✅ Real-world reporting  

**Next Lesson:** [07-order-by-clause-guide.md](../07-order-by-clause/07-order-by-clause-guide.md)  
Learn to sort your query results!

---

**Total Time:** 15 minutes  
**Next:** Lesson 07 - ORDER BY Clause
