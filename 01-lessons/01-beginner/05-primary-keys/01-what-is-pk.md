# What is a Primary Key?

## 🔑 Simple Explanation

A **Primary Key** is a column that **uniquely identifies** each row in a table.

No two rows can have the same primary key value!

---

## 🌟 Real-World Examples

Think of it like:
- 🎓 **Student ID number** (each student has ONE unique ID)
- 🆔 **Social Security Number** (unique to each person)
- 🚗 **License plate number** (unique to each car)

---

## 📋 The Rules

1. ✅ **Must be UNIQUE** - No duplicates allowed
2. ✅ **Cannot be NULL** - Must always have a value
3. ✅ **One per table** - Each table should have ONE primary key

---

## 📊 Visual Example

```
Products Table
┌───────────┬──────────────┬─────────┐
│ ProductID │ ProductName  │ Price   │
├───────────┼──────────────┼─────────┤
│     1     │ Mouse        │ $29.99  │ ✓ Unique ID
│     2     │ Keyboard     │ $89.99  │ ✓ Unique ID
│     1     │ Monitor      │ $199.99 │ ❌ ERROR! ID 1 exists!
└───────────┴──────────────┴─────────┘
```

**What happens?**
- Row 1: ✅ ProductID = 1 (OK, first time)
- Row 2: ✅ ProductID = 2 (OK, unique)
- Row 3: ❌ ProductID = 1 (REJECTED! Duplicate!)

---

## ❓ Why Use Primary Keys?

### 1. **Uniqueness Guarantee**
Every row is guaranteed to be unique and identifiable.

### 2. **Performance**
Finding rows by primary key is **extremely fast**.

### 3. **Relationships**
Required for connecting tables together (Foreign Keys).

---

## 💡 Quick Example

```sql
-- Create table WITH primary key
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,  -- ← This is the primary key
    FirstName VARCHAR(50),
    LastName VARCHAR(50)
);

-- This works ✓
INSERT INTO Customers VALUES (1, 'John', 'Smith');

-- This works ✓
INSERT INTO Customers VALUES (2, 'Sarah', 'Johnson');

-- This FAILS ❌ (duplicate CustomerID)
INSERT INTO Customers VALUES (1, 'Mike', 'Williams');
```

---

## 🎯 Key Takeaway

**Primary Key = Unique Identifier**

Every table needs one!  
It's like giving each row its own unique name tag.
