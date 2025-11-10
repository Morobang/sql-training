# What is a Foreign Key?

## 🔗 Simple Explanation

A **Foreign Key** creates a **relationship** between two tables.

It's a column in one table that **points to** the Primary Key of another table.

---

## 🌉 The Connection

```
Parent Table          Child Table
┌─────────────┐      ┌──────────────────┐
│ Departments │◄─────│ Employees        │
│             │      │                  │
│ DepartmentID│      │ DepartmentID (FK)│
└─────────────┘      └──────────────────┘
        ▲                     │
        └─────────────────────┘
           Foreign Key Link
```

---

## 📊 Visual Example

### Parent Table: **Departments**
```
┌──────────────┬─────────────────┐
│ DepartmentID │ DepartmentName  │
├──────────────┼─────────────────┤
│      1       │ IT              │
│      2       │ Sales           │
└──────────────┴─────────────────┘
```

### Child Table: **Employees**
```
┌────────────┬──────────────┬──────────────┐
│ EmployeeID │ EmployeeName │ DepartmentID │
├────────────┼──────────────┼──────────────┤
│    101     │ John         │      1       │ ← Points to IT
│    102     │ Sarah        │      2       │ ← Points to Sales
│    103     │ Mike         │      1       │ ← Points to IT
└────────────┴──────────────┴──────────────┘
```

**The Connection:**
- John works in Department 1 (IT)
- Sarah works in Department 2 (Sales)
- Mike works in Department 1 (IT)

---

## 📋 The Rules

1. ✅ **Must Match** - Foreign Key must match a PRIMARY KEY in the parent table
2. ❌ **No Orphans** - Cannot insert DepartmentID = 99 if it doesn't exist
3. 🛡️ **Data Protection** - Prevents invalid relationships

---

## ❓ Why Use Foreign Keys?

### 1. **Data Integrity**
Ensures all relationships are valid - no "orphaned" records!

### 2. **Prevents Mistakes**
Can't assign an employee to a department that doesn't exist.

### 3. **Shows Structure**
Makes database relationships clear and documented.

---

## 💡 Quick Example

```sql
-- Step 1: Create PARENT table
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY,
    DepartmentName VARCHAR(50)
);

-- Step 2: Create CHILD table with Foreign Key
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    DepartmentID INT,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

-- Step 3: Insert parent data first
INSERT INTO Departments VALUES (1, 'IT');
INSERT INTO Departments VALUES (2, 'Sales');

-- Step 4: Insert child data
INSERT INTO Employees VALUES (101, 'John', 1);  -- ✓ Works (Dept 1 exists)
INSERT INTO Employees VALUES (102, 'Sarah', 2); -- ✓ Works (Dept 2 exists)
INSERT INTO Employees VALUES (103, 'Mike', 99); -- ❌ FAILS (Dept 99 doesn't exist!)
```

---

## 🎯 Key Takeaway

**Foreign Key = Relationship Between Tables**

It ensures data stays connected and consistent!  

Parent table must exist **before** child table references it.
