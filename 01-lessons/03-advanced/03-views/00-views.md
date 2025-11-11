# Views in SQL Server

## What is a View?

A **view** is a virtual table based on the result of a SELECT query. It doesn't store data itself but provides a saved query that can be referenced like a table.

## Why Use Views?

### 1. **Simplify Complex Queries**
- Hide complexity from users
- Provide a simple interface to complex joins and calculations

### 2. **Security and Data Access Control**
- Show only specific columns or rows to users
- Hide sensitive data while exposing needed information

### 3. **Data Abstraction**
- Protect users from underlying schema changes
- Present data in different formats without changing tables

### 4. **Reusability**
- Write complex logic once, use it everywhere
- Maintain consistency across applications

## Basic Syntax

```sql
CREATE VIEW ViewName AS
SELECT Column1, Column2, ...
FROM TableName
WHERE Condition;
```

## Types of Views

### 1. Simple Views
- Based on a single table
- No complex joins or aggregations
- Often updatable

### 2. Complex Views
- Multiple tables with JOINs
- Aggregations (GROUP BY, SUM, AVG, etc.)
- Calculated columns
- Usually read-only

### 3. Indexed Views (Materialized Views)
- Physically stored result set
- Improved query performance
- Requires maintenance overhead
- Created with `CREATE UNIQUE CLUSTERED INDEX`

## View Limitations

- **Cannot use ORDER BY** (without TOP or OFFSET/FETCH)
- **Cannot contain INTO clause**
- **Cannot reference temporary tables**
- **Limited UPDATE/INSERT/DELETE** operations (depends on view complexity)

## Updatable Views

A view is updatable if:
- ✅ Based on a single table
- ✅ No DISTINCT, GROUP BY, HAVING
- ✅ No aggregate functions
- ✅ All required columns (NOT NULL without defaults) are included

## Performance Considerations

### Views Don't Improve Performance By Default
- Views are just stored queries
- Query optimizer expands the view definition
- Performance same as writing the query directly

### Indexed Views Can Improve Performance
- Physically store the result set
- Useful for expensive aggregations
- Trade-off: storage space and maintenance cost

## Best Practices

1. ✅ **Use descriptive names** (e.g., `vw_ActiveCustomers`, `CustomerSalesView`)
2. ✅ **Keep views simple** when possible
3. ✅ **Document complex views** with comments
4. ✅ **Use schema binding** (`WITH SCHEMABINDING`) to prevent underlying table changes
5. ✅ **Avoid nested views** (views based on other views) - impacts performance
6. ✅ **Use views for security** to limit data access
7. ❌ **Don't use SELECT *** in views - specify columns explicitly

## Common Use Cases

### Security Layer
```sql
CREATE VIEW vw_EmployeePublicInfo AS
SELECT EmployeeID, FirstName, LastName, Department
FROM Employees;
-- Hides salary, SSN, etc.
```

### Data Aggregation
```sql
CREATE VIEW vw_MonthlySales AS
SELECT 
    YEAR(SaleDate) AS Year,
    MONTH(SaleDate) AS Month,
    SUM(TotalAmount) AS Revenue
FROM Sales
GROUP BY YEAR(SaleDate), MONTH(SaleDate);
```

### Joining Multiple Tables
```sql
CREATE VIEW vw_CustomerOrders AS
SELECT 
    c.CustomerName,
    p.ProductName,
    s.SaleDate,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID;
```

## View Management Commands

```sql
-- Create or replace a view
CREATE OR ALTER VIEW ViewName AS ...

-- Drop a view
DROP VIEW IF EXISTS ViewName;

-- Rename a view
EXEC sp_rename 'OldViewName', 'NewViewName';

-- View definition
EXEC sp_helptext 'ViewName';

-- List all views
SELECT * FROM INFORMATION_SCHEMA.VIEWS;
```

## WITH CHECK OPTION

Ensures that all data modifications through the view satisfy the view's WHERE clause:

```sql
CREATE VIEW vw_ActiveProducts AS
SELECT ProductID, ProductName, Price
FROM Products
WHERE IsActive = 1
WITH CHECK OPTION;

-- This will fail (IsActive not in WHERE condition)
UPDATE vw_ActiveProducts SET IsActive = 0 WHERE ProductID = 1;
```

## Summary

Views are powerful tools for:
- 🔒 **Security** - Restrict data access
- 📊 **Simplification** - Hide complex queries
- 🔄 **Reusability** - Use the same logic everywhere
- 🛡️ **Abstraction** - Protect from schema changes

In the practice files, you'll learn to create, modify, and optimize views using the TechStore database.
