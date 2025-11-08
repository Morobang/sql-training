# 🎯 Lesson 03: SELECT Clause - Advanced Techniques

## 📋 Overview

**Estimated Time:** 10 minutes  
**Difficulty:** Beginner  
**Prerequisites:** Lessons 01-02 completed  

**What You'll Learn:**
- Advanced SELECT techniques
- CASE expressions for conditional logic
- String concatenation
- Type conversion (CAST/CONVERT)
- Aggregate functions
- NULL handling

---

## 🎨 SELECT Is More Than Just Retrieving

The SELECT clause is powerful! You can:
- ✅ Calculate new values
- ✅ Apply conditional logic
- ✅ Combine columns
- ✅ Aggregate data
- ✅ Transform data types

---

## 🧮 Part 1: Calculations in SELECT

You can perform math directly in your queries!

### Basic Arithmetic:
```sql
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax,
    Price * 0.85 AS DiscountPrice
FROM Inventory.Products;
```

**Result:**
```
ProductName | Price   | PriceWithTax | DiscountPrice
------------|---------|--------------|---------------
Laptop      | 1200.00 | 1380.00      | 1020.00
Mouse       | 25.99   | 29.89        | 22.09
Keyboard    | 75.50   | 86.83        | 64.18
```

### Complex Calculations:
```sql
SELECT 
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS TotalValue,
    (Price * StockQuantity) * 0.10 AS TenPercentOfValue
FROM Inventory.Products;
```

**Result:**
```
ProductName | Price   | StockQuantity | TotalValue | TenPercentOfValue
------------|---------|---------------|------------|-------------------
Laptop      | 1200.00 | 25            | 30000.00   | 3000.00
Mouse       | 25.99   | 150           | 3898.50    | 389.85
```

### Order of Operations (PEMDAS):
```sql
SELECT 
    ProductName,
    Price,
    Price * 1.15 + 5 AS WrongOrder,      -- Multiply first, then add
    (Price + 5) * 1.15 AS CorrectOrder   -- Parentheses force order
FROM Inventory.Products;
```

**Visual:**
```
Price = 100

Wrong:  100 * 1.15 + 5 = 115 + 5 = 120
Right:  (100 + 5) * 1.15 = 105 * 1.15 = 120.75
```

---

## 🔤 Part 2: String Concatenation

Combine text columns using the `+` operator.

### Basic Concatenation:
```sql
SELECT 
    FirstName + ' ' + LastName AS FullName,
    Email
FROM Sales.Customers;
```

**Result:**
```
FullName     | Email
-------------|----------------------
John Doe     | john.doe@email.com
Jane Smith   | jane.smith@email.com
Mike Johnson | mike.j@email.com
```

### Formatted Strings:
```sql
SELECT 
    'Customer: ' + FirstName + ' ' + LastName AS CustomerInfo,
    'Email: ' + Email AS EmailLabel,
    City + ', ' + Country AS Location
FROM Sales.Customers;
```

**Result:**
```
CustomerInfo        | EmailLabel                   | Location
--------------------|------------------------------|------------------
Customer: John Doe  | Email: john.doe@email.com    | New York, USA
Customer: Jane Smith| Email: jane.smith@email.com  | Los Angeles, USA
```

### Visual Example:
```
FirstName = 'John'
LastName = 'Doe'
Email = 'john@email.com'

Concatenation:
FirstName + ' ' + LastName + ' (' + Email + ')'
   ↓         ↓      ↓         ↓      ↓        ↓
'John'  +  ' '  + 'Doe'  +  ' ('  + 'john@email.com' + ')'
                        ↓
Result: 'John Doe (john@email.com)'
```

---

## 🔄 Part 3: Type Conversion (CAST/CONVERT)

To concatenate numbers with text, convert them first.

### CAST Function (ANSI Standard):
```sql
SELECT 
    ProductName,
    'Price: $' + CAST(Price AS VARCHAR(10)) AS PriceLabel
FROM Inventory.Products;
```

**Result:**
```
ProductName | PriceLabel
------------|----------------
Laptop      | Price: $1200.00
Mouse       | Price: $25.99
Keyboard    | Price: $75.50
```

### CONVERT Function (SQL Server):
```sql
SELECT 
    ProductName,
    'Stock: ' + CONVERT(VARCHAR(10), StockQuantity) + ' units' AS StockLabel
FROM Inventory.Products;
```

**Result:**
```
ProductName | StockLabel
------------|-------------
Laptop      | Stock: 25 units
Mouse       | Stock: 150 units
Keyboard    | Stock: 80 units
```

### Date Formatting with CONVERT:
```sql
SELECT 
    OrderID,
    CONVERT(VARCHAR(20), OrderDate, 101) AS USFormat,    -- MM/DD/YYYY
    CONVERT(VARCHAR(20), OrderDate, 103) AS UKFormat,    -- DD/MM/YYYY
    CONVERT(VARCHAR(20), OrderDate, 120) AS ISOFormat    -- YYYY-MM-DD
FROM Sales.Orders;
```

**Result:**
```
OrderID | USFormat   | UKFormat   | ISOFormat
--------|------------|------------|--------------------
1       | 01/15/2025 | 15/01/2025 | 2025-01-15 00:00:00
2       | 01/16/2025 | 16/01/2025 | 2025-01-16 00:00:00
```

---

## 🎭 Part 4: CASE Expressions - Conditional Logic

CASE lets you apply IF-THEN-ELSE logic in SELECT.

### Syntax:
```sql
CASE 
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END
```

### Example 1: Price Categories
```sql
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 200 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Inventory.Products;
```

**Result:**
```
ProductName | Price   | PriceCategory
------------|---------|---------------
Laptop      | 1200.00 | Premium
Mouse       | 25.99   | Budget
Keyboard    | 75.50   | Mid-Range
Monitor     | 350.00  | Premium
Charger     | 19.99   | Budget
```

### Visual: How CASE Works
```
Price = 75.50

CASE 
    WHEN 75.50 < 50 THEN 'Budget'        → FALSE, skip
    WHEN 75.50 < 200 THEN 'Mid-Range'    → TRUE, return 'Mid-Range'
    ELSE 'Premium'                       → Never reached
END

Result: 'Mid-Range'
```

### Example 2: Stock Status
```sql
SELECT 
    ProductName,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'OUT OF STOCK'
        WHEN StockQuantity < 10 THEN 'CRITICAL'
        WHEN StockQuantity < 50 THEN 'LOW'
        ELSE 'GOOD'
    END AS StockStatus
FROM Inventory.Products;
```

**Result:**
```
ProductName | StockQuantity | StockStatus
------------|---------------|-------------
Laptop      | 25            | LOW
Mouse       | 150           | GOOD
Keyboard    | 80            | GOOD
Webcam      | 5             | CRITICAL
Charger     | 0             | OUT OF STOCK
```

### Example 3: Multiple CASE Expressions
```sql
SELECT 
    FirstName,
    LastName,
    Country,
    CASE 
        WHEN Country = 'USA' THEN 'Domestic'
        ELSE 'International'
    END AS CustomerType,
    CASE 
        WHEN City = 'New York' THEN 'NY'
        WHEN City = 'Los Angeles' THEN 'LA'
        WHEN City = 'Chicago' THEN 'CHI'
        ELSE City
    END AS CityCode
FROM Sales.Customers;
```

---

## 📊 Part 5: Aggregate Functions

Calculate summary values across multiple rows.

### Common Aggregate Functions:

| Function | Purpose | Example |
|----------|---------|---------|
| `COUNT(*)` | Count all rows | Total products |
| `COUNT(column)` | Count non-NULL values | Products with supplier |
| `SUM(column)` | Add all values | Total inventory |
| `AVG(column)` | Calculate average | Average price |
| `MIN(column)` | Find minimum | Cheapest product |
| `MAX(column)` | Find maximum | Most expensive |

### Example: All Aggregates Together
```sql
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(SupplierID) AS ProductsWithSupplier,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Inventory.Products;
```

**Result:**
```
TotalProducts | ProductsWithSupplier | TotalStock | AvgPrice | MinPrice | MaxPrice
--------------|----------------------|------------|----------|----------|----------
8             | 6                    | 535        | 298.37   | 19.99    | 1200.00
```

### Visual: How Aggregates Work

**Raw Data:**
```
Price
-------
1200.00
25.99
75.50
350.00
89.99
599.99
45.00
19.99
```

**Aggregates:**
```
COUNT(*) = 8              (count rows)
SUM(Price) = 2406.46      (add all)
AVG(Price) = 300.81       (sum / count)
MIN(Price) = 19.99        (smallest)
MAX(Price) = 1200.00      (largest)
```

---

## 🌟 Part 6: DISTINCT - Unique Values

Remove duplicate values from results.

### Basic DISTINCT:
```sql
SELECT DISTINCT City 
FROM Sales.Customers;
```

**Without DISTINCT:**
```
City
------------
New York
Los Angeles
New York      ← Duplicate
Chicago
New York      ← Duplicate
```

**With DISTINCT:**
```
City
------------
New York
Los Angeles
Chicago
```

### DISTINCT on Multiple Columns:
```sql
SELECT DISTINCT City, Country 
FROM Sales.Customers;
```

**Result (unique combinations):**
```
City        | Country
------------|--------
New York    | USA
Los Angeles | USA
London      | UK
Paris       | France
```

### Count Distinct Values:
```sql
SELECT 
    COUNT(*) AS TotalCustomers,
    COUNT(DISTINCT City) AS UniqueCities,
    COUNT(DISTINCT Country) AS UniqueCountries
FROM Sales.Customers;
```

**Result:**
```
TotalCustomers | UniqueCities | UniqueCountries
---------------|--------------|----------------
15             | 8            | 4
```

---

## ❓ Part 7: NULL Handling

NULL means "unknown" or "missing" - handle it carefully!

### Find NULL Values:
```sql
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NULL;
```

### Replace NULL with Default (ISNULL):
```sql
SELECT 
    ProductName,
    ISNULL(SupplierID, 0) AS SupplierID
FROM Inventory.Products;
```

**Result:**
```
ProductName | SupplierID
------------|------------
Laptop      | 1
Mouse       | 0          ← Was NULL, now 0
Keyboard    | 2
```

### COALESCE (More Flexible):
```sql
-- Returns first non-NULL value
SELECT 
    ProductName,
    COALESCE(SupplierID, AlternateSupplierID, 999) AS SupplierID
FROM Inventory.Products;
```

### Visual: NULL Behavior
```
Price = 100
Tax = NULL

Price + Tax = NULL    ← Any calculation with NULL = NULL
Price * Tax = NULL
Price - Tax = NULL

Solution:
Price + ISNULL(Tax, 0) = 100 + 0 = 100
```

---

## 🔍 Part 8: Subqueries in SELECT

Use a query inside another query.

### Compare to Average:
```sql
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Inventory.Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Inventory.Products) AS Difference
FROM Inventory.Products;
```

**Result:**
```
ProductName | Price   | AvgPrice | Difference
------------|---------|----------|------------
Laptop      | 1200.00 | 298.37   | 901.63
Mouse       | 25.99   | 298.37   | -272.38
Keyboard    | 75.50   | 298.37   | -222.87
```

### Count Related Records:
```sql
SELECT 
    c.CategoryName,
    (SELECT COUNT(*) 
     FROM Inventory.Products p 
     WHERE p.CategoryID = c.CategoryID) AS ProductCount
FROM Inventory.Categories c;
```

**Result:**
```
CategoryName | ProductCount
-------------|-------------
Electronics  | 5
Furniture    | 2
Clothing     | 1
```

---

## 🧪 Practice Exercises

### Exercise 1: Formatted Product List
Create: "Product: [Name] - Price: $[Price]"
```sql
-- Your answer:
```

### Exercise 2: Employee Salary Categories
Categorize employees:
- < $60,000 = 'Entry Level'
- $60,000-$80,000 = 'Mid Level'
- > $80,000 = 'Senior Level'
```sql
-- Your answer:
```

### Exercise 3: Inventory Value Percentage
Calculate each product's inventory value and show what % it is of total
```sql
-- Your answer:
```

### Exercise 4: NULL City Handling
Show customer info, replace NULL cities with 'Unknown'
```sql
-- Your answer:
```

### Exercise 5: Stock Alerts
Categorize products:
- < 10 = 'CRITICAL'
- < 50 = 'LOW'
- >= 50 = 'GOOD'
```sql
-- Your answer:
```

---

## 🎯 Key Takeaways

| Technique | Use Case | Example |
|-----------|----------|---------|
| **Calculations** | Math operations | `Price * 1.15` |
| **Concatenation** | Combine text | `FirstName + ' ' + LastName` |
| **CAST/CONVERT** | Change data types | `CAST(Price AS VARCHAR)` |
| **CASE** | Conditional logic | `CASE WHEN ... THEN ... END` |
| **Aggregates** | Summary values | `COUNT(*), AVG(Price)` |
| **DISTINCT** | Unique values | `SELECT DISTINCT City` |
| **NULL Handling** | Replace missing | `ISNULL(column, default)` |

---

## 🚀 What's Next?

You now understand:
✅ Advanced SELECT techniques  
✅ CASE expressions for logic  
✅ Type conversion and concatenation  
✅ Aggregate functions  
✅ NULL handling  

**Next Lesson:** [04-from-clause-guide.md](../04-from-clause/04-from-clause-guide.md)  
Learn how to join multiple tables together!

---

**Total Time:** 10 minutes  
**Next:** Lesson 04 - FROM Clause & Joins
