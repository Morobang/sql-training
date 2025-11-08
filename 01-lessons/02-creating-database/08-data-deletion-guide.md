# Lesson 08: Data Deletion - Removing Data Safely

## 🎯 What You'll Learn
- DELETE statement syntax
- TRUNCATE vs DELETE differences
- Using WHERE to target specific rows
- CASCADE DELETE behavior
- Recovery options
- Safety best practices

---

## 🗑️ DELETE Statement Basics

### Basic Syntax

```sql
DELETE FROM TableName
WHERE condition;
```

### ⚠️ CRITICAL WARNING

```sql
-- ❌ DANGER - Deletes ALL rows permanently!
DELETE FROM Products;

-- ✅ SAFE - Deletes only specific row
DELETE FROM Products WHERE ProductID = 5;
```

---

## 🎨 Visual: Before and After DELETE

### Before DELETE

```
Inventory.Products
┌─────────┬──────────┬────────┐
│ProductID│  Name    │ Price  │
├─────────┼──────────┼────────┤
│    1    │ Laptop   │ 999.99 │
│    2    │ Mouse    │  19.99 │ ← We want to delete this
│    3    │ Keyboard │  49.99 │
└─────────┴──────────┴────────┘
```

### Execute DELETE

```sql
DELETE FROM Inventory.Products
WHERE ProductID = 2;
```

### After DELETE

```
Inventory.Products
┌─────────┬──────────┬────────┐
│ProductID│  Name    │ Price  │
├─────────┼──────────┼────────┤
│    1    │ Laptop   │ 999.99 │
│    3    │ Keyboard │  49.99 │
└─────────┴──────────┴────────┘
                              ← Row 2 is GONE forever!
```

---

## 🎯 Deleting Single Rows

### Delete by Primary Key (Most Common)

```sql
-- Delete specific product
DELETE FROM Inventory.Products
WHERE ProductID = 5;

-- Delete specific customer
DELETE FROM Sales.Customers
WHERE CustomerID = 1001;

-- Delete specific order
DELETE FROM Sales.Orders
WHERE OrderID = 1000;
```

---

## 📊 Deleting Multiple Rows

### Delete by Condition

```sql
-- Delete all discontinued products
DELETE FROM Inventory.Products
WHERE Discontinued = 1;

-- Delete old orders (older than 1 year)
DELETE FROM Sales.Orders
WHERE OrderDate < DATEADD(year, -1, GETDATE());

-- Delete products with zero stock
DELETE FROM Inventory.Products
WHERE QuantityInStock = 0;
```

### Visual: Multiple Row Deletion

```
Before:
┌─────────┬──────────┬──────────┬─────────────┐
│ProductID│  Name    │InStock   │Discontinued │
├─────────┼──────────┼──────────┼─────────────┤
│    1    │ Laptop   │   50     │      0      │
│    2    │ Mouse    │    0     │      1      │ ← Will delete
│    3    │ Keyboard │   10     │      0      │
│    4    │ OldItem  │    0     │      1      │ ← Will delete
└─────────┴──────────┴──────────┴─────────────┘

DELETE FROM Inventory.Products WHERE Discontinued = 1;

After:
┌─────────┬──────────┬──────────┬─────────────┐
│ProductID│  Name    │InStock   │Discontinued │
├─────────┼──────────┼──────────┼─────────────┤
│    1    │ Laptop   │   50     │      0      │
│    3    │ Keyboard │   10     │      0      │
└─────────┴──────────┴──────────┴─────────────┘
```

---

## ⚡ DELETE vs TRUNCATE

### DELETE (Selective Removal)

```sql
DELETE FROM Products WHERE Price < 10;
```

**Characteristics:**
- ✅ Can use WHERE clause
- ✅ Can delete specific rows
- ✅ Triggers fire (if any)
- ✅ Can be rolled back
- ❌ Slower for large tables
- ❌ Doesn't reset IDENTITY

### TRUNCATE (Remove Everything)

```sql
TRUNCATE TABLE Products;
```

**Characteristics:**
- ✅ Very fast
- ✅ Resets IDENTITY counter
- ✅ Uses minimal logging
- ❌ Cannot use WHERE
- ❌ Deletes ALL rows
- ❌ Triggers don't fire

### Comparison Table

| Feature | DELETE | TRUNCATE |
|---------|--------|----------|
| **WHERE clause** | ✅ Yes | ❌ No |
| **Speed** | Slower | Faster |
| **IDENTITY reset** | ❌ No | ✅ Yes |
| **Can rollback** | ✅ Yes | ✅ Yes (in transaction) |
| **Selective** | ✅ Yes | ❌ All rows only |

---

## 🔗 CASCADE DELETE (Foreign Key Behavior)

### What is CASCADE DELETE?

When you delete a parent record, child records are automatically deleted.

### Example: Orders with CASCADE DELETE

```sql
-- Foreign key with CASCADE DELETE
FOREIGN KEY (OrderID) 
    REFERENCES Sales.Orders(OrderID) 
    ON DELETE CASCADE
```

### Visual: CASCADE DELETE in Action

```
Before DELETE:

Orders Table (Parent)
┌────────┬──────────┬────────────┐
│OrderID │CustomerID│ OrderDate  │
├────────┼──────────┼────────────┤
│  1000  │   1001   │ 2025-01-15 │ ← Delete this
└────────┴──────────┴────────────┘
          ↓ Links to...

OrderDetails Table (Child)
┌──────────┬────────┬─────────┬────────┐
│ DetailID │OrderID │ProductID│Quantity│
├──────────┼────────┼─────────┼────────┤
│    1     │  1000  │    1    │   1    │ ← Auto-deleted
│    2     │  1000  │    2    │   2    │ ← Auto-deleted
└──────────┴────────┴─────────┴────────┘

Execute:
DELETE FROM Sales.Orders WHERE OrderID = 1000;

After DELETE:
Both parent and children are GONE!
```

---

## 🛡️ Protected Deletion (Without CASCADE)

### What Happens Without CASCADE?

```sql
-- Try to delete category with products
DELETE FROM Inventory.Categories
WHERE CategoryID = 1;

-- ❌ Error: Cannot delete because Products reference it
```

### Visual: Protected Deletion

```
Categories (Parent)
┌────────────┬────────────────┐
│ CategoryID │ CategoryName   │
├────────────┼────────────────┤
│     1      │ Electronics    │ ← Try to delete
└────────────┴────────────────┘
       ↑
       │ Still referenced by...
       │
Products (Child)
┌─────────┬──────────┬────────────┐
│ProductID│  Name    │ CategoryID │
├─────────┼──────────┼────────────┤
│    1    │ Laptop   │     1      │ ← Blocks deletion!
│    2    │ Mouse    │     1      │ ← Blocks deletion!
└─────────┴──────────┴────────────┘

Result: ❌ DELETE FAILED
"Cannot delete category - products still reference it"
```

### Solution: Delete in Correct Order

```sql
-- Step 1: Delete children first
DELETE FROM Inventory.Products WHERE CategoryID = 1;

-- Step 2: Now delete parent
DELETE FROM Inventory.Categories WHERE CategoryID = 1;
```

---

## 🔄 Safe DELETE Practices

### Practice 1: SELECT Before DELETE

```sql
-- Step 1: Preview what will be deleted
SELECT * FROM Products WHERE Price < 10;

-- Step 2: If correct, delete
DELETE FROM Products WHERE Price < 10;
```

### Practice 2: Use Transactions

```sql
BEGIN TRANSACTION;

DELETE FROM Products WHERE ProductID = 5;

-- Check if correct
SELECT * FROM Products;

-- If correct:
COMMIT;

-- If wrong:
-- ROLLBACK;
```

### Practice 3: Soft Delete (Mark Instead of Delete)

```sql
-- Instead of DELETE, mark as deleted
UPDATE Products 
SET IsDeleted = 1, DeletedDate = GETDATE()
WHERE ProductID = 5;

-- Query only active records
SELECT * FROM Products WHERE IsDeleted = 0;
```

---

## 📋 DELETE Patterns

### Pattern 1: Delete Outdated Records

```sql
DELETE FROM Sales.Orders
WHERE Status = 'Cancelled' 
  AND OrderDate < DATEADD(year, -2, GETDATE());
```

### Pattern 2: Delete Duplicates (Keep One)

```sql
-- Delete duplicate emails, keep lowest ID
DELETE FROM Customers
WHERE CustomerID NOT IN (
    SELECT MIN(CustomerID) 
    FROM Customers 
    GROUP BY Email
);
```

### Pattern 3: Delete with Subquery

```sql
-- Delete products from discontinued suppliers
DELETE FROM Products
WHERE SupplierID IN (
    SELECT SupplierID 
    FROM Suppliers 
    WHERE IsActive = 0
);
```

### Pattern 4: Delete TOP N Rows

```sql
-- Delete oldest 100 orders
DELETE TOP(100) FROM Sales.Orders
ORDER BY OrderDate ASC;
```

---

## ⚠️ Common Mistakes

### Mistake 1: Forgetting WHERE

```sql
-- ❌ DISASTER - Deletes everything!
DELETE FROM Customers;

-- All customers gone forever! 😱
```

### Mistake 2: Wrong Deletion Order

```sql
-- ❌ FAILS - Can't delete parent while children exist
DELETE FROM Categories WHERE CategoryID = 1;

-- ✅ CORRECT ORDER
DELETE FROM Products WHERE CategoryID = 1;  -- Children first
DELETE FROM Categories WHERE CategoryID = 1;  -- Parent second
```

### Mistake 3: No Backup/Transaction

```sql
-- ❌ RISKY - No way to undo!
DELETE FROM Products WHERE Price < 100;

-- ✅ SAFE - Can rollback if needed
BEGIN TRANSACTION;
DELETE FROM Products WHERE Price < 100;
-- Verify, then COMMIT or ROLLBACK
```

---

## 🔍 Verifying Deletions

### Check Row Count

```sql
-- Before
SELECT COUNT(*) FROM Products;  -- 100 rows

-- Delete
DELETE FROM Products WHERE Price < 10;
-- (15 rows affected)

-- After
SELECT COUNT(*) FROM Products;  -- 85 rows
```

### Verify Specific Records Are Gone

```sql
-- Should return 0 rows
SELECT * FROM Products 
WHERE ProductID = 5;
```

---

## 💾 Recovery Options

### Option 1: ROLLBACK (Before COMMIT)

```sql
BEGIN TRANSACTION;
DELETE FROM Products WHERE ProductID = 5;
-- Oops, wrong product!
ROLLBACK;  -- Undone! ✓
```

### Option 2: Restore from Backup

```
❌ Already committed? 
→ Restore from database backup
→ Or use transaction log backup (if available)
```

### Option 3: Soft Delete (Recommended)

```sql
-- Add IsDeleted column
ALTER TABLE Products ADD IsDeleted BIT DEFAULT 0;

-- "Delete" by marking
UPDATE Products SET IsDeleted = 1 WHERE ProductID = 5;

-- Can "undelete"
UPDATE Products SET IsDeleted = 0 WHERE ProductID = 5;
```

---

## 🧪 TRUNCATE Examples

### Truncate Entire Table

```sql
-- Remove all rows, reset IDENTITY
TRUNCATE TABLE TempData;
```

### When to Use TRUNCATE

✅ **Good use cases:**
- Clearing temporary/staging tables
- Resetting test data
- Removing all data quickly

❌ **Don't use when:**
- You need WHERE clause
- Foreign keys reference this table
- You want to keep IDENTITY values

---

## 📊 DELETE Performance

### Small Deletes (< 1000 rows)

```sql
DELETE FROM Products WHERE CategoryID = 5;
-- Fast enough ✓
```

### Large Deletes (> 10,000 rows)

```sql
-- ❌ Slow - Single large DELETE
DELETE FROM Orders WHERE OrderDate < '2020-01-01';

-- ✅ Faster - Delete in batches
WHILE 1=1
BEGIN
    DELETE TOP(1000) FROM Orders 
    WHERE OrderDate < '2020-01-01';
    
    IF @@ROWCOUNT = 0 BREAK;  -- No more rows
    WAITFOR DELAY '00:00:01'; -- Pause 1 second
END
```

---

## 🎓 Key Takeaways

✅ **Always use WHERE** unless deleting entire table  
✅ **SELECT first** to preview what will be deleted  
✅ **Use transactions** for important deletions  
✅ **Delete children before parents** (unless CASCADE)  
✅ **TRUNCATE** is fast but removes everything  
✅ **Soft delete** (mark as deleted) is safest  
✅ **Backups** are your last resort  

---

## 📋 Quick Reference

```sql
-- Delete specific row
DELETE FROM TableName WHERE ID = 1;

-- Delete multiple rows
DELETE FROM TableName WHERE condition;

-- Delete all rows (keep table)
DELETE FROM TableName;  -- Slow
TRUNCATE TABLE TableName;  -- Fast, resets IDENTITY

-- Safe delete with transaction
BEGIN TRANSACTION;
DELETE FROM TableName WHERE condition;
SELECT * FROM TableName;  -- Verify
COMMIT;  -- or ROLLBACK
```

---

## ➡️ Next Steps

- **Lesson 09**: Practice exercises combining all CRUD operations
- Apply everything you've learned: CREATE, INSERT, UPDATE, DELETE

---

## 🧪 Try It Yourself!

```sql
-- Delete a specific product
DELETE FROM Inventory.Products WHERE ProductID = 5;

-- Delete all orders from last year
DELETE FROM Sales.Orders 
WHERE YEAR(OrderDate) = 2024;

-- Safe delete with verification
BEGIN TRANSACTION;
DELETE FROM Inventory.Categories WHERE CategoryID = 10;
SELECT * FROM Inventory.Categories;  -- Check
ROLLBACK;  -- Practice rolling back!

-- Truncate a table (removes all data)
TRUNCATE TABLE Sales.OrderDetails;

-- Verify deletion
SELECT COUNT(*) FROM Sales.OrderDetails;  -- Should be 0
```
