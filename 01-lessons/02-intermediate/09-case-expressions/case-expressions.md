# Lesson 9: CASE Expressions

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Write simple and searched CASE expressions
2. Use CASE in SELECT, WHERE, and ORDER BY
3. Perform conditional aggregation with CASE
4. Create derived columns and pivot-like transformations
5. Understand CASE vs IIF and CHOOSE (SQL Server)

---

## Part 1: CASE Expression Basics

### Searched CASE (most flexible)

```sql
SELECT 
    ProductName,
    Price,
    CASE
        WHEN Price < 10 THEN 'Budget'
        WHEN Price < 50 THEN 'Standard'
        WHEN Price < 100 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM Products;
```

### Simple CASE (equality only)

```sql
SELECT 
    OrderID,
    CASE Status
        WHEN 'P' THEN 'Pending'
        WHEN 'S' THEN 'Shipped'
        WHEN 'D' THEN 'Delivered'
        ELSE 'Unknown'
    END AS StatusName
FROM Orders;
```

---

## Part 2: CASE in WHERE Clause

```sql
-- Dynamic filter based on condition
SELECT ProductID, ProductName, Price
FROM Products
WHERE 
    CASE 
        WHEN @FilterType = 'Cheap' THEN CASE WHEN Price < 20 THEN 1 ELSE 0 END
        WHEN @FilterType = 'Expensive' THEN CASE WHEN Price > 100 THEN 1 ELSE 0 END
        ELSE 1
    END = 1;
```

---

## Part 3: CASE in ORDER BY

```sql
-- Custom sort order
SELECT ProductName, CategoryID
FROM Products
ORDER BY 
    CASE CategoryID
        WHEN 1 THEN 1  -- Electronics first
        WHEN 5 THEN 2  -- Books second
        ELSE 3         -- Everything else
    END,
    ProductName;
```

---

## Part 4: Conditional Aggregation

### Pivot-style summaries

```sql
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(CASE WHEN MONTH(OrderDate) = 1 THEN TotalAmount ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(OrderDate) = 2 THEN TotalAmount ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(OrderDate) = 3 THEN TotalAmount ELSE 0 END) AS Mar
FROM Orders
GROUP BY YEAR(OrderDate);
```

### Count with conditions

```sql
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(CASE WHEN Status = 'Shipped' THEN 1 END) AS ShippedOrders,
    COUNT(CASE WHEN Status = 'Pending' THEN 1 END) AS PendingOrders
FROM Orders;
```

---

## Part 5: Nested CASE

```sql
SELECT 
    ProductName,
    Price,
    Stock,
    CASE
        WHEN Stock = 0 THEN 'Out of Stock'
        WHEN Stock < 10 THEN 
            CASE 
                WHEN Price > 100 THEN 'Low Stock - High Value'
                ELSE 'Low Stock'
            END
        ELSE 'In Stock'
    END AS StockStatus
FROM Products;
```

---

## Part 6: IIF and CHOOSE (SQL Server)

### IIF (inline IF)

```sql
SELECT ProductName, IIF(Price > 50, 'Expensive', 'Affordable') AS Category
FROM Products;

-- Equivalent CASE
SELECT ProductName, CASE WHEN Price > 50 THEN 'Expensive' ELSE 'Affordable' END
FROM Products;
```

### CHOOSE

```sql
SELECT CHOOSE(Status, 'Pending', 'Shipped', 'Delivered') AS StatusName
FROM Orders;
```

---

## Part 7: Performance Considerations

- CASE is evaluated row-by-row; complex CASE in WHERE can be slow
- Consider computed columns or indexed views for frequently used CASE logic
- Use simple CASE when possible (slightly faster than searched CASE)

---

## Part 8: Practical Examples

```sql
-- Dynamic discount
SELECT 
    ProductName,
    Price,
    CASE
        WHEN Price > 100 THEN Price * 0.9  -- 10% off
        WHEN Price > 50 THEN Price * 0.95  -- 5% off
        ELSE Price
    END AS DiscountedPrice
FROM Products;

-- Flag high-value customers
SELECT 
    CustomerID,
    TotalSpent,
    CASE
        WHEN TotalSpent > 10000 THEN 'VIP'
        WHEN TotalSpent > 5000 THEN 'Premium'
        WHEN TotalSpent > 1000 THEN 'Standard'
        ELSE 'New'
    END AS CustomerTier
FROM CustomerSpending;
```

---

## Practice Exercises

1. Use CASE to create a 'SizeCategory' column (Small/Medium/Large) based on a numeric Size field.
2. Write a conditional aggregation query showing count of orders by status (Pending, Shipped, Delivered) in separate columns.
3. Use nested CASE to assign shipping cost based on weight and destination.

---

## Key Takeaways

- Searched CASE supports any condition; simple CASE only equality
- Use CASE for conditional columns, filters, sorting, aggregation
- IIF is shorthand for simple two-way CASE (SQL Server)
- CASE evaluates top-to-bottom; first match wins

---

## Next Lesson

Continue to [Lesson 10: Aggregate Functions & GROUP BY](../10-aggregate-functions/10-aggregate-functions.md).
