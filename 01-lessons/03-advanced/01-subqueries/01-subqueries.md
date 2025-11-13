# Subqueries - Advanced SQL

## 📚 Overview

Subqueries are queries nested inside another query. They allow you to break down complex problems into smaller, manageable pieces and perform operations that would be difficult or impossible with a single query.

---

## 🎯 What You'll Learn

- Simple subqueries in WHERE clause
- Subqueries in SELECT clause
- Subqueries in FROM clause (derived tables)
- Correlated subqueries
- EXISTS and NOT EXISTS
- IN and NOT IN with subqueries
- Subquery performance considerations

---

## 💡 Key Concepts

### **Types of Subqueries:**

**1. Scalar Subquery** - Returns single value
```sql
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
```

**2. Row Subquery** - Returns single row
```sql
SELECT * FROM Products
WHERE (Category, Price) = (SELECT Category, MAX(Price) FROM Products WHERE Category = 'Peripherals');
```

**3. Table Subquery** - Returns multiple rows/columns
```sql
SELECT * FROM Products
WHERE ProductID IN (SELECT ProductID FROM Sales);
```

**4. Correlated Subquery** - References outer query
```sql
SELECT ProductName, Price
FROM Products p1
WHERE Price > (SELECT AVG(Price) FROM Products p2 WHERE p2.Category = p1.Category);
```

---

## 🎓 When to Use Subqueries

✅ **Use subqueries when:**
- Need to filter based on aggregated data
- Need to compare against a derived value
- Breaking down complex logic into steps
- Checking for existence of related records

❌ **Avoid when:**
- JOIN would be more efficient
- Result set is very large
- Query becomes too nested (hard to read)

---

## 📊 Real-World Applications with TechStore

### Find products priced above category average
```sql
SELECT ProductName, Category, Price
FROM Products p1
WHERE Price > (
    SELECT AVG(Price) 
    FROM Products p2 
    WHERE p2.Category = p1.Category
);
```

### Find customers who made purchases
```sql
SELECT CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID 
    FROM Sales
);
```

### Find top-selling products
```sql
SELECT ProductName, Price
FROM Products
WHERE ProductID IN (
    SELECT ProductID
    FROM Sales
    GROUP BY ProductID
    HAVING COUNT(*) >= 2
);
```

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-simple-subqueries.sql` - Basic WHERE clause subqueries
2. `02-subquery-in-select.sql` - Subqueries in SELECT
3. `03-subquery-in-from.sql` - Derived tables
4. `04-correlated-subqueries.sql` - Subqueries that reference outer query
5. `05-exists-not-exists.sql` - Testing for existence
6. `06-in-not-in.sql` - Membership testing
7. `07-practical-subqueries.sql` - Real-world examples

---

## 💡 Pro Tips

- Start with JOINs, use subqueries when needed
- Use EXISTS instead of IN for better performance with large datasets
- Avoid deeply nested subqueries (max 2-3 levels)
- Consider CTEs for complex queries (covered in next lesson)
- Test subquery independently before embedding

---

**Ready to master subqueries? Start with `01-simple-subqueries.sql`! 🚀**
