# What is ALTER TABLE?

## 🛠️ Simple Explanation

**ALTER TABLE** is a DDL command that **modifies** an existing table's structure.

You can:
- ✅ Add new columns
- ✅ Remove columns
- ✅ Change data types
- ✅ Add constraints

---

## 💡 Why ALTER TABLE?

As your application grows, your database needs change:

```
Version 1.0                    Version 2.0
┌──────────────┐              ┌──────────────────────┐
│ Employees    │   ALTER →    │ Employees            │
├──────────────┤              ├──────────────────────┤
│ EmployeeID   │              │ EmployeeID           │
│ EmployeeName │              │ EmployeeName         │
│ DepartmentID │              │ DepartmentID         │
└──────────────┘              │ Email       ← NEW    │
                              │ Phone       ← NEW    │
                              │ Salary      ← NEW    │
                              └──────────────────────┘
```

---

## 📋 Basic Syntax

```sql
ALTER TABLE table_name
ADD column_name datatype;
```

---

## 💡 Quick Example

```sql
-- Our current Employees table from beginner:
-- EmployeeID, EmployeeName, DepartmentID

-- Add email column
ALTER TABLE Employees
ADD Email VARCHAR(100);

-- Add phone column
ALTER TABLE Employees
ADD Phone VARCHAR(20);

-- Add salary column
ALTER TABLE Employees
ADD Salary DECIMAL(10,2);
```

---

## 🎯 Key Takeaway

**ALTER TABLE = Modify existing table**

Don't drop and recreate tables - just ALTER them!  
Existing data stays intact.
