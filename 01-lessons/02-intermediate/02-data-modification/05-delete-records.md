# What is DELETE?

## 🗑️ Simple Explanation

**DELETE** is a DML command that **removes** rows from a table.

Unlike DROP (which removes entire tables), DELETE removes **specific rows** of data.

---

## 💡 When to Use DELETE

```
Before DELETE:                   After DELETE:
┌────┬──────┬────────┐          ┌────┬──────┬────────┐
│ ID │ Name │ Status │          │ ID │ Name │ Status │
├────┼──────┼────────┤          ├────┼──────┼────────┤
│ 1  │ John │ Active │          │ 1  │ John │ Active │
│ 2  │ Sara │ Fired  │   →      │ 3  │ Mike │ Active │
│ 3  │ Mike │ Active │          └────┴──────┴────────┘
└────┴──────┴────────┘          Row 2 deleted! ✂️
```

Common scenarios:
- ✅ Remove inactive customers
- ✅ Delete old records
- ✅ Remove test data
- ✅ Clean up duplicates

---

## 📋 Basic Syntax

```sql
DELETE FROM table_name
WHERE condition;
```

⚠️ **CRITICAL:** Always use WHERE! Without it, ALL rows deleted!

---

## 💡 Examples

### Delete One Row
```sql
-- Remove employee 5
DELETE FROM Employees
WHERE EmployeeID = 5;
```

### Delete Multiple Rows
```sql
-- Remove all inactive products
DELETE FROM Products
WHERE IsActive = 0;
```

### Delete with Multiple Conditions
```sql
-- Remove customers who joined before 2020 AND never purchased
DELETE FROM Customers
WHERE JoinDate < '2020-01-01' 
  AND TotalPurchases = 0;
```

---

## ⚠️ Common Mistakes

### ❌ Forgot WHERE Clause
```sql
-- DANGER! This deletes ALL employees!
DELETE FROM Employees;
```

### ✅ Always Use WHERE
```sql
-- Safe: Only deletes employee 5
DELETE FROM Employees
WHERE EmployeeID = 5;
```

---

## 🔄 DELETE vs TRUNCATE

| Command | Speed | Rollback | Reset ID | Logs |
|---------|-------|----------|----------|------|
| DELETE  | Slow  | ✅ Yes   | ❌ No    | ✅ Yes |
| TRUNCATE| Fast  | ❌ No    | ✅ Yes   | ❌ No  |

```sql
-- DELETE: Remove specific rows (can rollback)
DELETE FROM Products WHERE IsActive = 0;

-- TRUNCATE: Remove ALL rows (faster, can't rollback)
TRUNCATE TABLE Products;
```

---

## 🎯 Key Takeaway

**DELETE = Remove specific rows**

Always test with SELECT first:
```sql
-- Step 1: See what you'll delete
SELECT * FROM Employees WHERE EmployeeID = 5;

-- Step 2: Delete it
DELETE FROM Employees WHERE EmployeeID = 5;

-- Step 3: Verify it's gone
SELECT * FROM Employees WHERE EmployeeID = 5;
-- (Should return no rows)
```

💡 **Pro Tip:** Use transactions in production to safely test deletes!
