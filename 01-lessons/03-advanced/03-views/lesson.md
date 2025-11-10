# Lesson 3: Views

**Timeline:** 15:04:29 - 15:42:29  
**Duration:** ~38 minutes  
**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Create and manage views
2. Understand view benefits and limitations
3. Use indexed views for performance
4. Update data through views
5. Implement security with views

---

## Part 1: What Are Views?

Views are saved SELECT queries that act as virtual tables.

```sql
CREATE VIEW vw_ActiveProducts AS
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Discontinued = 0;

-- Query the view
SELECT * FROM vw_ActiveProducts WHERE Price > 50;
```

---

## Part 2: Creating Views

```sql
CREATE VIEW vw_CustomerOrders AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalRevenue
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;
```

---

## Part 3: Benefits of Views

### Simplify complex queries

```sql
-- Complex query encapsulated
CREATE VIEW vw_ProductPerformance AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName;

-- Simple query for users
SELECT * FROM vw_ProductPerformance WHERE Revenue > 10000;
```

### Security and abstraction

```sql
-- Hide sensitive columns
CREATE VIEW vw_EmployeePublic AS
SELECT EmployeeID, FirstName, LastName, Department
FROM Employees;
-- Salary, SSN hidden

GRANT SELECT ON vw_EmployeePublic TO PublicRole;
```

### Consistent logic

```sql
-- Business logic in one place
CREATE VIEW vw_ProfitableCustomers AS
SELECT CustomerID, CustomerName
FROM Customers c
WHERE (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) > 5000;
```

---

## Part 4: Modifying Views

```sql
-- Alter view
ALTER VIEW vw_ActiveProducts AS
SELECT ProductID, ProductName, Price, CategoryID, Stock
FROM Products
WHERE Discontinued = 0 AND Stock > 0;

-- Drop view
DROP VIEW vw_ActiveProducts;
```

---

## Part 5: Updatable Views

Simple views can support INSERT, UPDATE, DELETE.

```sql
CREATE VIEW vw_HighPriceProducts AS
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 100;

-- Update through view
UPDATE vw_HighPriceProducts
SET Price = Price * 1.1
WHERE ProductID = 5;

-- Insert through view
INSERT INTO vw_HighPriceProducts (ProductID, ProductName, Price)
VALUES (999, 'New Product', 150);
```

### Limitations

Views with JOINs, aggregates, DISTINCT, or UNION typically can't be updated directly.

---

## Part 6: WITH CHECK OPTION

Prevents updates that would make rows invisible to the view.

```sql
CREATE VIEW vw_CheapProducts AS
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price < 50
WITH CHECK OPTION;

-- This will FAIL (violates WHERE Price < 50)
UPDATE vw_CheapProducts
SET Price = 60
WHERE ProductID = 10;
```

---

## Part 7: Indexed Views (SQL Server)

Indexed views (materialized views) store the result set physically, improving read performance.

```sql
CREATE VIEW vw_CategorySales
WITH SCHEMABINDING
AS
SELECT 
    p.CategoryID,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue,
    COUNT_BIG(*) AS RowCount
FROM dbo.Products p
INNER JOIN dbo.OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.CategoryID;

-- Create unique clustered index
CREATE UNIQUE CLUSTERED INDEX IX_vw_CategorySales ON vw_CategorySales(CategoryID);
```

**Requirements (SQL Server):**
- SCHEMABINDING
- COUNT_BIG(*) if using GROUP BY
- Two-part table names (dbo.TableName)
- No OUTER JOINs, subqueries, or certain functions

---

## Part 8: View Performance

### When views are fast

- Simple views with indexes on underlying tables
- Indexed/materialized views
- Views that filter large tables to small result sets

### When views can be slow

- Views with complex JOINs or aggregates
- Nested views (view referencing another view)
- Views without proper indexes on base tables

**Tip:** Check the execution plan; optimizer may expand the view inline.

---

## Part 9: Practical Examples

### Example 1: Dashboard View

```sql
CREATE VIEW vw_SalesDashboard AS
SELECT 
    CAST(o.OrderDate AS DATE) AS Date,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    SUM(od.Quantity * od.UnitPrice) AS Revenue,
    AVG(od.Quantity * od.UnitPrice) AS AvgOrderValue
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY CAST(o.OrderDate AS DATE);
```

### Example 2: Security View

```sql
-- Show only orders for current user's region
CREATE VIEW vw_MyRegionOrders AS
SELECT o.OrderID, o.OrderDate, o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Region = (SELECT Region FROM Users WHERE UserID = SUSER_SNAME());
```

---

## Part 10: Best Practices

- Name views with prefix (vw_, v_) for clarity
- Document complex view logic
- Avoid nesting views deeply (performance)
- Use indexed views for frequently accessed aggregates
- Keep views simple for updateability
- Grant permissions on views, not base tables (security layer)

---

## Practice Exercises

1. Create a view showing customers with their total order count and revenue.
2. Create an indexed view for category-level sales summaries (SQL Server).
3. Create an updatable view for products in a specific category with CHECK OPTION.
4. Build a security view that shows only rows belonging to the current user.

---

## Key Takeaways

- Views are saved queries that act as virtual tables
- Use views for simplification, security, and abstraction
- Simple views can be updatable
- Indexed views materialize results for performance
- WITH CHECK OPTION enforces view filter on updates

---

## Next Lesson

Continue to [Lesson 4: Stored Procedures](../04-stored-procedures/).
