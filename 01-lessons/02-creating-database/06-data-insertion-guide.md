# Lesson 06: Data Insertion - Populating Your Tables

## 🎯 What You'll Learn
- INSERT statement syntax
- Adding single rows
- Adding multiple rows at once
- Understanding column order
- Working with IDENTITY columns
- Best practices for data insertion

---

## 📝 INSERT Statement Basics

### Basic Syntax

```sql
INSERT INTO TableName (Column1, Column2, Column3)
VALUES (Value1, Value2, Value3);
```

### Real Example

```sql
INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES ('Electronics', 'Electronic devices and accessories');
```

---

## 🎨 Visual: Before and After INSERT

### Before INSERT (Empty Table)

```
Inventory.Categories
┌────────────┬────────────────┬─────────────────────┐
│ CategoryID │ CategoryName   │ Description         │
├────────────┼────────────────┼─────────────────────┤
│            │                │                     │ ← Empty!
└────────────┴────────────────┴─────────────────────┘
```

### After INSERT

```sql
INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES ('Electronics', 'Electronic devices');
```

```
Inventory.Categories
┌────────────┬────────────────┬─────────────────────┐
│ CategoryID │ CategoryName   │ Description         │
├────────────┼────────────────┼─────────────────────┤
│     1      │ Electronics    │ Electronic devices  │ ← New row!
└────────────┴────────────────┴─────────────────────┘
```

---

## 🔢 Working with IDENTITY Columns

### You DON'T Specify IDENTITY Values

```sql
-- ❌ WRONG - Don't include CategoryID
INSERT INTO Inventory.Categories (CategoryID, CategoryName)
VALUES (1, 'Electronics');  -- Error!

-- ✅ CORRECT - Let IDENTITY auto-generate
INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES ('Electronics', 'Electronic devices');
-- CategoryID automatically becomes 1
```

### How IDENTITY Works

```
First INSERT  → CategoryID = 1
Second INSERT → CategoryID = 2
Third INSERT  → CategoryID = 3
(Automatic!)
```

---

## 📦 Inserting Multiple Rows at Once

### Multiple VALUES

```sql
INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES 
    ('Electronics', 'Electronic devices'),
    ('Furniture', 'Office and home furniture'),
    ('Clothing', 'Apparel and accessories');
```

### Result: 3 Rows Added

```
┌────────────┬────────────────┬──────────────────────────┐
│ CategoryID │ CategoryName   │ Description              │
├────────────┼────────────────┼──────────────────────────┤
│     1      │ Electronics    │ Electronic devices       │
│     2      │ Furniture      │ Office and home furniture│
│     3      │ Clothing       │ Apparel and accessories  │
└────────────┴────────────────┴──────────────────────────┘
```

---

## 🔗 Inserting with Foreign Keys

### Step 1: Insert Parent First

```sql
-- Must insert category BEFORE products
INSERT INTO Inventory.Categories (CategoryName)
VALUES ('Electronics');  -- Gets CategoryID = 1
```

### Step 2: Insert Child with Valid Foreign Key

```sql
-- Now insert products referencing CategoryID = 1
INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES 
    ('Laptop', 1, 999.99),      -- CategoryID 1 exists ✓
    ('Mouse', 1, 19.99),         -- CategoryID 1 exists ✓
    ('Keyboard', 1, 49.99);      -- CategoryID 1 exists ✓
```

### ❌ What Happens If Foreign Key Is Invalid?

```sql
INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES ('Desk', 999, 299.99);  -- CategoryID 999 doesn't exist!

-- Error: The INSERT statement conflicted with the FOREIGN KEY constraint
```

---

## 🎯 Column Order Matters!

### Example Table Structure

```sql
CREATE TABLE Sales.Customers (
    CustomerID INT IDENTITY(1001,1),
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Email VARCHAR(150)
);
```

### Option 1: Specify Column Names (RECOMMENDED)

```sql
INSERT INTO Sales.Customers (FirstName, LastName, Email)
VALUES ('Sarah', 'Johnson', 'sarah@email.com');
-- ✓ Clear and safe - order doesn't have to match table definition
```

### Option 2: Match Table Column Order

```sql
-- Must match exact order: FirstName, LastName, Email
INSERT INTO Sales.Customers 
VALUES ('Mike', 'Chen', 'mike@email.com');
-- ⚠️ Works but risky - if table structure changes, this breaks
```

---

## 🌟 Using DEFAULT Values

### Table with DEFAULTs

```sql
Country NVARCHAR(100) DEFAULT 'USA'
DateJoined DATETIME2 DEFAULT SYSDATETIME()
```

### Option 1: Let DEFAULT Apply

```sql
INSERT INTO Sales.Customers (FirstName, LastName, Email)
VALUES ('Sarah', 'Johnson', 'sarah@email.com');
-- Country automatically set to 'USA'
-- DateJoined automatically set to current datetime
```

### Option 2: Override DEFAULT

```sql
INSERT INTO Sales.Customers (FirstName, LastName, Email, Country)
VALUES ('John', 'Smith', 'john@email.com', 'Canada');
-- Country set to 'Canada' (overrides default)
```

---

## 📊 Visual: Complete Insert Flow

### Inserting a Complete Order

```
Step 1: Insert Customer
┌──────────┬───────────┬──────────┐
│CustomerID│ FirstName │ LastName │
├──────────┼───────────┼──────────┤
│   1001   │ Sarah     │ Johnson  │ ← New customer
└──────────┴───────────┴──────────┘

Step 2: Insert Order (references CustomerID 1001)
┌────────┬──────────┬────────────┬────────┐
│OrderID │CustomerID│ OrderDate  │ Status │
├────────┼──────────┼────────────┼────────┤
│  1000  │   1001   │ 2025-01-15 │Pending │ ← New order
└────────┴──────────┴────────────┴────────┘

Step 3: Insert Order Details (references OrderID 1000)
┌──────────┬────────┬─────────┬────────┬──────────┐
│ DetailID │OrderID │ProductID│Quantity│UnitPrice │
├──────────┼────────┼─────────┼────────┼──────────┤
│    1     │  1000  │    1    │   1    │  999.99  │ ← Item 1
│    2     │  1000  │    2    │   2    │   19.99  │ ← Item 2
└──────────┴────────┴─────────┴────────┴──────────┘
```

---

## 💡 Inserting Data - Best Practices

### ✅ DO:

```sql
-- Specify column names explicitly
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('Sarah', 'Johnson', 'sarah@email.com');

-- Insert multiple rows in one statement
INSERT INTO Categories (CategoryName) 
VALUES ('Electronics'), ('Furniture'), ('Clothing');

-- Insert parent records before children
-- First: Categories → Then: Products
```

### ❌ DON'T:

```sql
-- Don't insert values for IDENTITY columns
INSERT INTO Customers (CustomerID, FirstName)  -- ❌ Bad
VALUES (1, 'Sarah');

-- Don't rely on column order (too risky)
INSERT INTO Customers VALUES ('Sarah', 'Johnson'); -- ❌ Risky

-- Don't insert children before parents
INSERT INTO Products (...) before Categories  -- ❌ Will fail
```

---

## 🔍 Verifying Your INSERTs

### Check What You Inserted

```sql
-- See all customers
SELECT * FROM Sales.Customers;

-- See customers added today
SELECT * FROM Sales.Customers
WHERE CAST(DateJoined AS DATE) = CAST(GETDATE() AS DATE);

-- Count rows in table
SELECT COUNT(*) AS TotalCustomers FROM Sales.Customers;
```

---

## 🧪 Common Scenarios

### Scenario 1: Insert with Some NULL Values

```sql
INSERT INTO Inventory.Suppliers (SupplierName, ContactName, Email)
VALUES ('Tech Corp', 'John Smith', NULL);  -- Email is optional
```

### Scenario 2: Insert with All Columns

```sql
INSERT INTO Sales.Customers 
    (FirstName, LastName, Email, Phone, City, Country)
VALUES 
    ('Sarah', 'Johnson', 'sarah@email.com', '555-1234', 'Seattle', 'USA');
```

### Scenario 3: Bulk Insert Multiple Records

```sql
INSERT INTO Inventory.Products (ProductName, CategoryID, Price, QuantityInStock)
VALUES 
    ('Laptop', 1, 999.99, 50),
    ('Mouse', 1, 19.99, 200),
    ('Keyboard', 1, 49.99, 150),
    ('Monitor', 1, 299.99, 75);
```

---

## ⚠️ Common Errors and Solutions

### Error 1: FOREIGN KEY Violation

```
❌ Error: INSERT statement conflicted with FOREIGN KEY constraint

Problem: Trying to insert CategoryID = 5, but category 5 doesn't exist
Solution: Insert the category first, or use existing CategoryID
```

### Error 2: NULL in NOT NULL Column

```
❌ Error: Cannot insert NULL into column 'ProductName'

Problem: ProductName is required (NOT NULL)
Solution: Provide a value for ProductName
```

### Error 3: UNIQUE Constraint Violation

```
❌ Error: Duplicate key violates UNIQUE constraint

Problem: Trying to insert duplicate email address
Solution: Use a different email (must be unique)
```

### Error 4: CHECK Constraint Violation

```
❌ Error: INSERT statement conflicted with CHECK constraint

Problem: Trying to insert Price = -50 (violates Price >= 0)
Solution: Use positive price value
```

---

## 🎓 Key Takeaways

✅ Use **INSERT INTO** to add data  
✅ **Don't specify IDENTITY** columns - they auto-generate  
✅ **Specify column names** for clarity and safety  
✅ Insert **multiple rows** using multiple VALUES  
✅ Insert **parents before children** (FOREIGN KEY order)  
✅ **DEFAULT values** apply automatically if not specified  

---

## 📋 Quick Reference

```sql
-- Single row
INSERT INTO TableName (Col1, Col2) VALUES (Val1, Val2);

-- Multiple rows
INSERT INTO TableName (Col1, Col2) 
VALUES 
    (Val1, Val2),
    (Val3, Val4),
    (Val5, Val6);

-- Let DEFAULTs apply
INSERT INTO TableName (RequiredCol) VALUES (Value);
-- Optional columns with DEFAULT get automatic values
```

---

## ➡️ Next Steps

- **Lesson 07**: Updating existing data with UPDATE
- **Lesson 08**: Deleting data with DELETE and TRUNCATE
- **Lesson 09**: Practice exercises

---

## 🧪 Try It Yourself!

```sql
-- Insert a new category
INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES ('Books', 'Fiction and non-fiction books');

-- Insert products for that category
INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES 
    ('SQL Guide', 4, 29.99),
    ('Python Basics', 4, 34.99);

-- Verify your inserts
SELECT c.CategoryName, p.ProductName, p.Price
FROM Inventory.Categories c
JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
WHERE c.CategoryName = 'Books';
```
