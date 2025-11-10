# 📑 Lesson 07: ORDER BY Clause - Sorting Results

## 📋 Overview

**Estimated Time:** 10 minutes  
**Difficulty:** Beginner  
**Prerequisites:** Lessons 01-06 completed  

**What You'll Learn:**
- Sorting results with ORDER BY
- Ascending vs Descending order
- Sorting by multiple columns
- Sorting with TOP
- Handling NULLs in sorting

---

## 🎯 Why ORDER BY?

**ORDER BY** controls the order of your results. Without it, SQL Server returns rows in **no guaranteed order**.

### Without ORDER BY:
```sql
SELECT ProductName, Price FROM Products;
```
**Result (unpredictable order):**
```
ProductName | Price
------------|--------
Keyboard    | 75.50
Laptop      | 1200.00
Mouse       | 25.99
```

### With ORDER BY:
```sql
SELECT ProductName, Price FROM Products ORDER BY Price;
```
**Result (sorted by price):**
```
ProductName | Price
------------|--------
Mouse       | 25.99
Keyboard    | 75.50
Laptop      | 1200.00
```

---

## 📊 Basic Sorting

### Syntax:
```sql
SELECT columns
FROM table
ORDER BY column [ASC|DESC];
```

### ASC vs DESC:

| Direction | Meaning | Numbers | Letters | Dates |
|-----------|---------|---------|---------|-------|
| **ASC** | Ascending (default) | 1→9 | A→Z | Old→New |
| **DESC** | Descending | 9→1 | Z→A | New→Old |

### Examples:

```sql
-- Ascending (low to high) - DEFAULT
SELECT ProductName, Price
FROM Products
ORDER BY Price;
-- OR explicitly:
ORDER BY Price ASC;

-- Descending (high to low)
SELECT ProductName, Price
FROM Products
ORDER BY Price DESC;

-- Alphabetical
SELECT ProductName, Price
FROM Products
ORDER BY ProductName;  -- A to Z

-- Reverse alphabetical
SELECT ProductName, Price
FROM Products
ORDER BY ProductName DESC;  -- Z to A
```

---

## 🔢 Visual: Sorting Direction

### Numbers:

**ASC (Low → High):**
```
25.99  →  75.50  →  350.00  →  1200.00
```

**DESC (High → Low):**
```
1200.00  →  350.00  →  75.50  →  25.99
```

### Letters:

**ASC (A → Z):**
```
Apple  →  Banana  →  Cherry  →  Date
```

**DESC (Z → A):**
```
Date  →  Cherry  →  Banana  →  Apple
```

### Dates:

**ASC (Oldest → Newest):**
```
2025-01-01  →  2025-01-15  →  2025-02-01
```

**DESC (Newest → Oldest):**
```
2025-02-01  →  2025-01-15  →  2025-01-01
```

---

## 📚 Sorting by Multiple Columns

You can sort by multiple columns - **primary sort, then secondary, then tertiary...**

### Syntax:
```sql
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC], column3 [ASC|DESC]
```

### Example: Sort by Category, then Price

```sql
SELECT 
    ProductName,
    CategoryID,
    Price
FROM Products
ORDER BY CategoryID, Price;
```

**Result:**
```
ProductName | CategoryID | Price
------------|------------|--------
Mouse       | 1          | 25.99    ← Category 1, lowest price
Keyboard    | 1          | 75.50    ← Category 1, next price
Laptop      | 1          | 1200.00  ← Category 1, highest price
Chair       | 2          | 200.00   ← Category 2, lowest price
Desk        | 2          | 350.00   ← Category 2, highest price
```

### Visual: Multi-Level Sorting

```
Step 1: Sort by CategoryID
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Category 1 │  │ Category 2 │  │ Category 3 │
└────────────┘  └────────────┘  └────────────┘

Step 2: Within each category, sort by Price
┌────────────┐
│ Category 1 │
├────────────┤
│ 25.99      │ ← Lowest
│ 75.50      │
│ 1200.00    │ ← Highest
└────────────┘
```

### Different Directions:

```sql
-- CategoryID ascending, Price descending
SELECT ProductName, CategoryID, Price
FROM Products
ORDER BY CategoryID ASC, Price DESC;
```

**Result:**
```
ProductName | CategoryID | Price
------------|------------|--------
Laptop      | 1          | 1200.00  ← Category 1, highest first
Keyboard    | 1          | 75.50
Mouse       | 1          | 25.99    ← Category 1, lowest last
Desk        | 2          | 350.00   ← Category 2, highest first
Chair       | 2          | 200.00
```

---

## 👥 Real-World Example: Customer List

```sql
SELECT 
    FirstName,
    LastName,
    City,
    Country
FROM Customers
ORDER BY Country, City, LastName;
```

**Result:**
```
FirstName | LastName | City        | Country
----------|----------|-------------|--------
Sarah     | Anderson | Toronto     | Canada
Mike      | Wilson   | Toronto     | Canada
Emma      | Brown    | London      | UK
John      | Smith    | London      | UK
Bob       | Davis    | Chicago     | USA
Alice     | Johnson  | Chicago     | USA
Jane      | Williams | New York    | USA
John      | Doe      | New York    | USA
```

**Sort Order:**
1. **Country** (alphabetical)
2. **City** within each country (alphabetical)
3. **LastName** within each city (alphabetical)

---

## 🏆 Sorting with TOP

Combine ORDER BY with TOP to get the first N results.

### Syntax:
```sql
SELECT TOP n columns
FROM table
ORDER BY column [ASC|DESC];
```

### Examples:

```sql
-- Top 5 most expensive products
SELECT TOP 5
    ProductName,
    Price
FROM Products
ORDER BY Price DESC;

-- Top 3 cheapest products
SELECT TOP 3
    ProductName,
    Price
FROM Products
ORDER BY Price ASC;

-- Most recent 10 orders
SELECT TOP 10
    OrderID,
    OrderDate,
    CustomerID
FROM Orders
ORDER BY OrderDate DESC;
```

### Visual: TOP with ORDER BY

```
All Products (sorted by price DESC):
1. Laptop      - $1200.00  ←┐
2. Tablet      - $599.99     │
3. Monitor     - $350.00     │ TOP 5 selected
4. Desk        - $275.00     │
5. Keyboard    - $75.50    ←┘
6. Webcam      - $89.99    ← Not included
7. Headphones  - $45.00
8. Mouse       - $25.99
```

---

## 📊 Sorting with Percentages

Get the top percentage of results.

### Syntax:
```sql
SELECT TOP n PERCENT columns
FROM table
ORDER BY column [ASC|DESC];
```

### Example:

```sql
-- Top 10% of products by price
SELECT TOP 10 PERCENT
    ProductName,
    Price
FROM Products
ORDER BY Price DESC;
```

**If you have 100 products:**
- TOP 10 PERCENT = 10 products
- TOP 25 PERCENT = 25 products

---

## 🎨 Sorting by Aliases and Calculations

You can sort by calculated columns or aliases.

### Example 1: Sort by Calculated Value
```sql
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax
FROM Products
ORDER BY PriceWithTax DESC;
```

### Example 2: Sort by Concatenated Column
```sql
SELECT 
    FirstName + ' ' + LastName AS FullName,
    Email
FROM Customers
ORDER BY FullName;
```

### Example 3: Sort by CASE Result
```sql
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 200 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Products
ORDER BY PriceCategory;
```

**Result (alphabetical by category):**
```
ProductName | Price   | PriceCategory
------------|---------|---------------
Mouse       | 25.99   | Budget       ← B first
Headphones  | 45.00   | Budget
Keyboard    | 75.50   | Mid-Range    ← M second
Desk        | 150.00  | Mid-Range
Laptop      | 1200.00 | Premium      ← P last
```

---

## ❓ Sorting NULL Values

**NULL values have special sort behavior:**

| Sort Direction | NULL Position |
|----------------|---------------|
| **ASC** | NULLs appear FIRST |
| **DESC** | NULLs appear LAST |

### Example:

```sql
SELECT ProductName, SupplierID
FROM Products
ORDER BY SupplierID;
```

**Result (ASC - NULLs first):**
```
ProductName | SupplierID
------------|------------
Keyboard    | NULL       ← NULL appears first
Monitor     | NULL
Laptop      | 1          ← Then sorted values
Mouse       | 2
```

```sql
SELECT ProductName, SupplierID
FROM Products
ORDER BY SupplierID DESC;
```

**Result (DESC - NULLs last):**
```
ProductName | SupplierID
------------|------------
Monitor     | 3          ← Sorted values first
Mouse       | 2
Laptop      | 1
Keyboard    | NULL       ← NULL appears last
```

### Force NULL Handling:

```sql
-- Treat NULL as a specific value
SELECT ProductName, ISNULL(SupplierID, 9999) AS SupplierID
FROM Products
ORDER BY SupplierID;
```

---

## 🔗 Sorting with JOINs

Sort results from joined tables.

### Example:

```sql
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
ORDER BY c.CategoryName, p.Price DESC;
```

**Result:**
```
CategoryName | ProductName | Price
-------------|-------------|--------
Clothing     | T-Shirt     | 25.00
Electronics  | Laptop      | 1200.00  ← Highest in Electronics
Electronics  | Tablet      | 599.99
Electronics  | Webcam      | 89.99
Electronics  | Keyboard    | 75.50
Electronics  | Mouse       | 25.99    ← Lowest in Electronics
Furniture    | Desk        | 350.00
Furniture    | Chair       | 200.00
```

---

## 📈 Sorting Grouped Results

ORDER BY works great with GROUP BY.

### Example:

```sql
SELECT 
    c.CategoryName,
    COUNT(*) AS ProductCount,
    AVG(p.Price) AS AvgPrice
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY AvgPrice DESC;
```

**Result:**
```
CategoryName | ProductCount | AvgPrice
-------------|--------------|----------
Electronics  | 5            | 398.19   ← Highest avg
Furniture    | 2            | 275.00
Clothing     | 1            | 25.00    ← Lowest avg
```

---

## 🎯 Custom Sort Order with CASE

Create custom sort logic.

### Example: Prioritize Specific Category

```sql
SELECT 
    ProductName,
    CategoryID,
    Price
FROM Products
ORDER BY 
    CASE CategoryID
        WHEN 1 THEN 1  -- Electronics first
        WHEN 2 THEN 2  -- Furniture second
        ELSE 3         -- Everything else last
    END,
    Price DESC;
```

### Example: Status Priority

```sql
SELECT 
    OrderID,
    Status,
    OrderDate
FROM Orders
ORDER BY 
    CASE Status
        WHEN 'Pending' THEN 1    -- Urgent first
        WHEN 'Processing' THEN 2
        WHEN 'Shipped' THEN 3
        WHEN 'Delivered' THEN 4  -- Completed last
    END,
    OrderDate DESC;
```

---

## 📅 Sorting Dates

Common date sorting patterns.

### Examples:

```sql
-- Oldest to newest
SELECT OrderID, OrderDate
FROM Orders
ORDER BY OrderDate ASC;

-- Newest to oldest (most common)
SELECT OrderID, OrderDate
FROM Orders
ORDER BY OrderDate DESC;

-- By year, then month
SELECT 
    OrderID,
    OrderDate,
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth
FROM Orders
ORDER BY YEAR(OrderDate) DESC, MONTH(OrderDate) DESC;
```

---

## 🧪 Practice Exercises

### Exercise 1: Basic Sort
Show all products sorted by price (cheapest first)
```sql
-- Your answer:
```

### Exercise 2: TOP
Show top 10 most expensive products
```sql
-- Your answer:
```

### Exercise 3: Multi-Column Sort
Show customers sorted by country, city, then last name
```sql
-- Your answer:
```

### Exercise 4: JOIN + Sort
Show products with categories, sorted by category name then product name
```sql
-- Your answer:
```

### Exercise 5: Grouped + Sorted
Show product counts by category, sorted by count (highest first)
```sql
-- Your answer:
```

### Exercise 6: Calculated Sort
Show products sorted by inventory value (Price * StockQuantity) descending
```sql
-- Your answer:
```

---

## 🎯 Key Takeaways

| Concept | Syntax | Use Case |
|---------|--------|----------|
| **ASC** | `ORDER BY column ASC` | Low to high, A to Z, old to new |
| **DESC** | `ORDER BY column DESC` | High to low, Z to A, new to old |
| **Multiple Columns** | `ORDER BY col1, col2, col3` | Primary, secondary, tertiary sort |
| **TOP** | `SELECT TOP 10 ... ORDER BY` | First N results |
| **TOP PERCENT** | `SELECT TOP 10 PERCENT` | First N% of results |
| **By Alias** | `ORDER BY AliasName` | Sort by calculated column |

### Remember:
✅ ORDER BY happens **LAST** in query execution  
✅ ASC is default (you can omit it)  
✅ Can sort by multiple columns  
✅ NULLs appear first (ASC) or last (DESC)  
✅ Always use ORDER BY with TOP  

### Common Patterns:
```sql
ORDER BY Price DESC          -- Most expensive first
ORDER BY OrderDate DESC      -- Most recent first
ORDER BY LastName            -- Alphabetical
ORDER BY Category, Price     -- Group then sort within
```

---

## 🚀 What's Next?

You now understand:
✅ Sorting with ORDER BY  
✅ ASC vs DESC  
✅ Multi-column sorting  
✅ TOP with ORDER BY  
✅ NULL handling  

**Next Lesson:** [08-test-your-knowledge.sql](../08-test-your-knowledge/08-test-your-knowledge.sql)  
Practice everything you've learned with 45 exercises!

---

**Total Time:** 10 minutes  
**Next:** Lesson 08 - Practice Exercises (Test Your Knowledge)

**🎉 You're almost done with Chapter 03!**
