# What is UPDATE?

## ✏️ Simple Explanation

**UPDATE** is a DML command that **modifies** existing data in a table.

Unlike INSERT (which adds new rows), UPDATE **changes** existing rows.

---

## 💡 When to Use UPDATE

```
Before UPDATE:                   After UPDATE:
┌────┬──────┬────────┐          ┌────┬──────┬────────┐
│ ID │ Name │ Salary │          │ ID │ Name │ Salary │
├────┼──────┼────────┤          ├────┼──────┼────────┤
│ 1  │ John │ 50000  │   →      │ 1  │ John │ 55000  │ ← Changed!
│ 2  │ Sara │ 60000  │          │ 2  │ Sara │ 66000  │ ← Changed!
└────┴──────┴────────┘          └────┴──────┴────────┘
```

Common scenarios:
- ✅ Update employee salary
- ✅ Change customer address
- ✅ Fix typos in data
- ✅ Update product prices

---

## 📋 Basic Syntax

```sql
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;
```

⚠️ **CRITICAL:** Always use WHERE! Without it, ALL rows update!

---

## 💡 Examples

### Update One Row
```sql
-- Update John's salary
UPDATE Employees
SET Salary = 55000
WHERE EmployeeID = 1;
```

### Update Multiple Columns
```sql
-- Update John's salary AND phone
UPDATE Employees
SET Salary = 55000, Phone = '555-1234'
WHERE EmployeeID = 1;
```

### Update Multiple Rows
```sql
-- Give 10% raise to all IT employees
UPDATE Employees
SET Salary = Salary * 1.10
WHERE DepartmentID = 1;
```

---

## ⚠️ Common Mistakes

### ❌ Forgot WHERE Clause
```sql
-- DANGER! This updates ALL employees!
UPDATE Employees
SET Salary = 100000;
```

### ✅ Always Use WHERE
```sql
-- Safe: Only updates employee 1
UPDATE Employees
SET Salary = 100000
WHERE EmployeeID = 1;
```

---

## 🎯 Key Takeaway

**UPDATE = Modify existing data**

Always test with SELECT first:
```sql
-- Step 1: See what you'll update
SELECT * FROM Employees WHERE EmployeeID = 1;

-- Step 2: Update it
UPDATE Employees SET Salary = 55000 WHERE EmployeeID = 1;

-- Step 3: Verify
SELECT * FROM Employees WHERE EmployeeID = 1;
```
