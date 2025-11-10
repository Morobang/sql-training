# Lesson 07: Data Updates - Modifying Existing Data

## 🎯 What You'll Learn
- UPDATE statement syntax
- Modifying single vs multiple rows
- Using WHERE clause to target specific records
- Updating with calculations
- Common mistakes and how to avoid them
- Transaction safety

---

## ✏️ UPDATE Statement Basics

### Basic Syntax

```sql
UPDATE TableName
SET Column1 = NewValue1,
    Column2 = NewValue2
WHERE condition;
```

### ⚠️ CRITICAL: Always Use WHERE!

```sql
-- ❌ DANGEROUS - Updates ALL rows!
UPDATE Products SET Price = 0;

-- ✅ SAFE - Updates only specific row
UPDATE Products SET Price = 0 WHERE ProductID = 5;
```

---

## 🎨 Visual: Before and After UPDATE

### Before UPDATE

```
Inventory.Products
┌─────────┬──────────┬────────┐
│ProductID│  Name    │ Price  │
├─────────┼──────────┼────────┤
│    1    │ Laptop   │ 999.99 │ ← We want to change this
│    2    │ Mouse    │  19.99 │
│    3    │ Keyboard │  49.99 │
└─────────┴──────────┴────────┘
```

### Execute UPDATE

```sql
UPDATE Inventory.Products
SET Price = 899.99
WHERE ProductID = 1;
```

### After UPDATE

```
Inventory.Products
┌─────────┬──────────┬────────┐
│ProductID│  Name    │ Price  │
├─────────┼──────────┼────────┤
│    1    │ Laptop   │ 899.99 │ ← Price changed!
│    2    │ Mouse    │  19.99 │
│    3    │ Keyboard │  49.99 │
└─────────┴──────────┴────────┘
```

---

## 🎯 Updating Single Rows

### Update by Primary Key (Most Common)

```sql
-- Update specific product price
UPDATE Inventory.Products
SET Price = 899.99
WHERE ProductID = 1;

-- Update specific customer email
UPDATE Sales.Customers
SET Email = 'newemail@example.com'
WHERE CustomerID = 1001;

-- Update employee salary
UPDATE HR.Employees
SET Salary = 65000
WHERE EmployeeID = 5;
```

---

## 📊 Updating Multiple Columns

### Single Row, Multiple Columns

```sql
UPDATE Sales.Customers
SET 
    Email = 'sarah.new@email.com',
    Phone = '555-9999',
    City = 'Portland'
WHERE CustomerID = 1001;
```

### Visual Result

```
Before:
┌──────────┬───────────────────┬──────────┬─────────┐
│CustomerID│ Email             │ Phone    │ City    │
├──────────┼───────────────────┼──────────┼─────────┤
│   1001   │ sarah@email.com   │ 555-1234 │ Seattle │
└──────────┴───────────────────┴──────────┴─────────┘

After:
┌──────────┬─────────────────────┬──────────┬──────────┐
│CustomerID│ Email               │ Phone    │ City     │
├──────────┼─────────────────────┼──────────┼──────────┤
│   1001   │ sarah.new@email.com │ 555-9999 │ Portland │
└──────────┴─────────────────────┴──────────┴──────────┘
```

---

## 🔢 Updating Multiple Rows

### Update All Rows Matching Condition

```sql
-- Give 10% discount to all Electronics products
UPDATE Inventory.Products
SET Price = Price * 0.90
WHERE CategoryID = 1;
```

### Visual: Multiple Row Update

```
Electronics Products (CategoryID = 1):

Before:
┌─────────┬──────────┬──────────┬────────┐
│ProductID│  Name    │CategoryID│ Price  │
├─────────┼──────────┼──────────┼────────┤
│    1    │ Laptop   │    1     │ 999.99 │
│    2    │ Mouse    │    1     │  19.99 │
│    3    │ Keyboard │    1     │  49.99 │
└─────────┴──────────┴──────────┴────────┘

After 10% discount:
┌─────────┬──────────┬──────────┬────────┐
│ProductID│  Name    │CategoryID│ Price  │
├─────────┼──────────┼──────────┼────────┤
│    1    │ Laptop   │    1     │ 899.99 │ ← All prices
│    2    │ Mouse    │    1     │  17.99 │ ← reduced by
│    3    │ Keyboard │    1     │  44.99 │ ← 10%!
└─────────┴──────────┴──────────┴────────┘
```

---

## 🧮 Updating with Calculations

### Increase Values

```sql
-- Increase all salaries by $5000
UPDATE HR.Employees
SET Salary = Salary + 5000;

-- Add 50 units to stock
UPDATE Inventory.Products
SET QuantityInStock = QuantityInStock + 50
WHERE ProductID = 1;
```

### Decrease Values

```sql
-- Reduce price by $10
UPDATE Inventory.Products
SET Price = Price - 10
WHERE ProductID = 3;

-- Subtract sold quantity from stock
UPDATE Inventory.Products
SET QuantityInStock = QuantityInStock - 5
WHERE ProductID = 2;
```

### Percentage Changes

```sql
-- Increase prices by 15%
UPDATE Inventory.Products
SET Price = Price * 1.15
WHERE CategoryID = 2;

-- Reduce prices by 25%
UPDATE Inventory.Products
SET Price = Price * 0.75
WHERE Discontinued = 1;
```

---

## 🎯 WHERE Clause Conditions

### Single Condition

```sql
-- By ID
WHERE ProductID = 5

-- By text match
WHERE CategoryName = 'Electronics'

-- By number comparison
WHERE Price > 100

-- By date
WHERE OrderDate >= '2025-01-01'
```

### Multiple Conditions (AND)

```sql
UPDATE Inventory.Products
SET Price = Price * 0.90
WHERE CategoryID = 1 
  AND Price > 500;
-- Only expensive electronics get discount
```

### Multiple Conditions (OR)

```sql
UPDATE Sales.Orders
SET Status = 'Archived'
WHERE Status = 'Delivered' 
   OR Status = 'Cancelled';
```

### Complex Conditions

```sql
UPDATE Inventory.Products
SET Discontinued = 1
WHERE (QuantityInStock = 0 AND Price < 20)
   OR (CategoryID = 5);
```

---

## 🔄 Updating Based on Other Tables

### Using Subquery

```sql
-- Update product prices based on supplier
UPDATE Inventory.Products
SET Price = Price * 1.10
WHERE SupplierID = (
    SELECT SupplierID 
    FROM Inventory.Suppliers 
    WHERE SupplierName = 'Tech Corp'
);
```

### Visual Flow

```
Step 1: Find SupplierID
┌───────────┬──────────────┐
│SupplierID │SupplierName  │
├───────────┼──────────────┤
│     1     │ Tech Corp    │ ← Found! ID = 1
└───────────┴──────────────┘

Step 2: Update products from that supplier
┌─────────┬──────────┬───────────┬────────┐
│ProductID│  Name    │SupplierID │ Price  │
├─────────┼──────────┼───────────┼────────┤
│    1    │ Laptop   │     1     │ 999.99 │ ← Update
│    2    │ Mouse    │     1     │  19.99 │ ← Update
│    5    │ Desk     │     2     │ 299.99 │ ← Skip
└─────────┴──────────┴───────────┴────────┘
```

---

## 🛡️ UPDATE Safety Practices

### Step 1: SELECT Before UPDATE

```sql
-- First: Preview what will be updated
SELECT * FROM Inventory.Products
WHERE CategoryID = 1;

-- Then: Perform the update
UPDATE Inventory.Products
SET Price = Price * 0.90
WHERE CategoryID = 1;
```

### Step 2: Use Transactions

```sql
BEGIN TRANSACTION;

UPDATE Inventory.Products
SET Price = Price * 0.90
WHERE CategoryID = 1;

-- Check the results
SELECT * FROM Inventory.Products WHERE CategoryID = 1;

-- If correct:
COMMIT;
-- If wrong:
-- ROLLBACK;
```

### Step 3: Limit Scope with TOP

```sql
-- Update only first 10 rows (testing)
UPDATE TOP(10) Inventory.Products
SET Price = Price * 1.10;
```

---

## ⚠️ Common Mistakes

### Mistake 1: Forgetting WHERE Clause

```sql
-- ❌ DISASTER - Updates ALL rows!
UPDATE Products SET Price = 0;

-- Result: Every product now costs $0!
```

**Solution:** Always use WHERE unless you really want to update ALL rows.

### Mistake 2: Wrong WHERE Condition

```sql
-- Intended: Update product 5
-- ❌ WRONG: Uses = instead of IN for multiple values
UPDATE Products SET Price = 100 WHERE ProductID = 5, 6, 7;  -- Error!

-- ✅ CORRECT:
UPDATE Products SET Price = 100 WHERE ProductID IN (5, 6, 7);
```

### Mistake 3: Overwriting Values Instead of Modifying

```sql
-- ❌ WRONG: Sets everyone's salary to 5000
UPDATE Employees SET Salary = 5000;

-- ✅ CORRECT: Adds 5000 to existing salary
UPDATE Employees SET Salary = Salary + 5000;
```

---

## 📋 UPDATE Patterns

### Pattern 1: Fix Typo

```sql
UPDATE Customers
SET LastName = 'Johnson'
WHERE CustomerID = 1001;
```

### Pattern 2: Bulk Status Change

```sql
UPDATE Orders
SET Status = 'Shipped'
WHERE Status = 'Pending' 
  AND OrderDate < DATEADD(day, -7, GETDATE());
```

### Pattern 3: Price Adjustment

```sql
UPDATE Products
SET Price = ROUND(Price * 1.05, 2)  -- 5% increase, round to 2 decimals
WHERE CategoryID = 1;
```

### Pattern 4: Mark as Discontinued

```sql
UPDATE Products
SET Discontinued = 1,
    QuantityInStock = 0
WHERE QuantityInStock = 0 
  AND DATEDIFF(day, DateAdded, GETDATE()) > 365;
```

---

## 🔍 Verifying UPDATEs

### Check Affected Rows

```sql
UPDATE Products
SET Price = 99.99
WHERE ProductID = 1;

-- SQL Server shows: (1 row affected)
```

### Use SELECT to Verify

```sql
-- After update, verify the change
SELECT ProductID, ProductName, Price
FROM Products
WHERE ProductID = 1;
```

### Check Row Count Before and After

```sql
-- Before
SELECT COUNT(*) FROM Products WHERE Price > 100;  -- Result: 5

-- Update
UPDATE Products SET Price = Price * 0.90 WHERE Price > 100;

-- After
SELECT COUNT(*) FROM Products WHERE Price > 100;  -- Result: 2
-- (3 products now below $100)
```

---

## 💡 Advanced UPDATE Techniques

### Update with CASE Statement

```sql
UPDATE Inventory.Products
SET Price = CASE
    WHEN CategoryID = 1 THEN Price * 1.10  -- Electronics +10%
    WHEN CategoryID = 2 THEN Price * 1.05  -- Furniture +5%
    ELSE Price  -- Others unchanged
END;
```

### Update with NULL Handling

```sql
-- Replace NULL emails with default
UPDATE Suppliers
SET Email = 'noemail@company.com'
WHERE Email IS NULL;
```

---

## 🎓 Key Takeaways

✅ **Always use WHERE** to target specific rows  
✅ **SELECT first** to preview what will be updated  
✅ **Use transactions** for important updates  
✅ **Test with TOP(n)** when updating many rows  
✅ Use **calculations** to modify existing values (Price * 1.10)  
✅ **Verify results** with SELECT after UPDATE  

---

## 📋 Quick Reference

```sql
-- Update single column
UPDATE TableName SET Column = Value WHERE ID = 1;

-- Update multiple columns
UPDATE TableName 
SET Col1 = Val1, Col2 = Val2 
WHERE condition;

-- Update with calculation
UPDATE TableName 
SET Price = Price * 1.10 
WHERE CategoryID = 1;

-- Safe update with transaction
BEGIN TRANSACTION;
UPDATE TableName SET Column = Value WHERE condition;
-- Verify, then COMMIT or ROLLBACK
COMMIT;
```

---

## ➡️ Next Steps

- **Lesson 08**: Deleting data (DELETE and TRUNCATE)
- **Lesson 09**: Practice exercises

---

## 🧪 Try It Yourself!

```sql
-- Update a product price
UPDATE Inventory.Products
SET Price = 899.99
WHERE ProductName = 'Laptop';

-- Give all employees a raise
UPDATE HR.Employees
SET Salary = Salary * 1.05;  -- 5% raise

-- Update order status
UPDATE Sales.Orders
SET Status = 'Delivered'
WHERE OrderID = 1000;

-- Verify your changes
SELECT * FROM Inventory.Products WHERE ProductName = 'Laptop';
SELECT * FROM HR.Employees;
SELECT * FROM Sales.Orders WHERE OrderID = 1000;
```
