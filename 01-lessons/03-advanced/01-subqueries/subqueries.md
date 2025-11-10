# Lesson 1: Subqueries

**Timeline:** 13:27:29 - 14:12:29  
**Duration:** ~45 minutes  
**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Write scalar, row, and table subqueries
2. Use subqueries in SELECT, FROM, WHERE, and HAVING
3. Understand correlated vs non-correlated subqueries
4. Use EXISTS and NOT EXISTS for existence checks
5. Optimize subqueries for performance

---

## Part 1: Types of Subqueries

### Scalar Subquery (returns single value)

```sql
-- Show products priced above average
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
```

### Row Subquery (returns single row, multiple columns)

```sql
SELECT ProductName, Price
FROM Products
WHERE (CategoryID, Price) = (SELECT CategoryID, MAX(Price) FROM Products WHERE CategoryID = 1);
```

### Table Subquery (returns multiple rows/columns)

```sql
SELECT *
FROM (
    SELECT ProductName, Price, CategoryID
    FROM Products
    WHERE Price > 50
) AS ExpensiveProducts;
```

---

## Part 2: Subqueries in Different Clauses

### In SELECT

```sql
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS Difference
FROM Products;
```

### In FROM (derived table)

```sql
SELECT CategoryID, AvgPrice
FROM (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
) AS CategoryAvg
WHERE AvgPrice > 50;
```

### In WHERE

```sql
-- Products in categories with avg price > 100
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING AVG(Price) > 100
);
```

---

## Part 3: Correlated Subqueries

Correlated subqueries reference columns from the outer query and execute once per outer row.

```sql
-- Products priced above their category average
SELECT p1.ProductName, p1.Price, p1.CategoryID
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
);
```

**Warning:** Correlated subqueries can be slow; consider window functions or JOINs as alternatives.

---

## Part 4: EXISTS and NOT EXISTS

### EXISTS (check for existence)

```sql
-- Customers who have placed orders
SELECT CustomerID, CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
```

### NOT EXISTS (find missing relationships)

```sql
-- Customers who have NOT placed orders
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
```

**Note:** EXISTS is often faster than IN for large datasets because it stops at first match.

---

## Part 5: IN vs EXISTS

```sql
-- Using IN
SELECT CustomerID
FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- Using EXISTS (often faster)
SELECT CustomerID
FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);
```

**Best practice:** Use EXISTS for correlated checks; IN for small static lists.

---

## Part 6: ALL, ANY, SOME

```sql
-- Products more expensive than ALL products in category 5
SELECT ProductName, Price
FROM Products
WHERE Price > ALL (SELECT Price FROM Products WHERE CategoryID = 5);

-- Products more expensive than ANY product in category 5
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (SELECT Price FROM Products WHERE CategoryID = 5);
```

---

## Part 7: Practical Examples

### Example 1: Top N per Group

```sql
-- Top 3 most expensive products per category (without window functions)
SELECT p1.ProductName, p1.CategoryID, p1.Price
FROM Products p1
WHERE (
    SELECT COUNT(*)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID AND p2.Price > p1.Price
) < 3
ORDER BY p1.CategoryID, p1.Price DESC;
```

### Example 2: Running Total

```sql
-- Running total of orders (without window functions)
SELECT 
    o1.OrderID,
    o1.OrderDate,
    o1.TotalAmount,
    (SELECT SUM(o2.TotalAmount)
     FROM Orders o2
     WHERE o2.OrderDate <= o1.OrderDate) AS RunningTotal
FROM Orders o1
ORDER BY o1.OrderDate;
```

### Example 3: Find Gaps

```sql
-- Products never ordered
SELECT ProductID, ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);
```

---

## Part 8: Subquery Performance Tips

- Avoid correlated subqueries in large tables; use JOINs or window functions
- Use EXISTS instead of IN for correlated checks
- Consider materialized views or temp tables for complex repeated subqueries
- Index columns used in subquery WHERE clauses
- Use EXPLAIN/execution plans to analyze subquery performance

### Rewrite correlated subquery as JOIN

```sql
-- SLOW: Correlated subquery
SELECT p.ProductName, p.Price
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
);

-- FASTER: JOIN to derived table
SELECT p.ProductName, p.Price
FROM Products p
INNER JOIN (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
) AS AvgPrices ON p.CategoryID = AvgPrices.CategoryID
WHERE p.Price > AvgPrices.AvgPrice;
```

---

## Practice Exercises

1. Find employees earning more than the average salary in their department.
2. Use EXISTS to find categories with at least one product priced over $100.
3. Rewrite a correlated subquery as a JOIN for performance.
4. Find the second-highest salary in each department using subqueries.

---

## Key Takeaways

- Scalar subqueries return one value; table subqueries return result sets
- Correlated subqueries reference outer query and can be slow
- EXISTS is faster than IN for existence checks
- Consider JOINs or window functions as alternatives for performance
- Use execution plans to measure subquery impact

---

## Next Lesson

Continue to [Lesson 2: Common Table Expressions (CTEs)](../02-ctes/).
