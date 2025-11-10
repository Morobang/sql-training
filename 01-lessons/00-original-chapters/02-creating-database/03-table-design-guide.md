# Lesson 03: Table Design Basics - Connecting Your Data

## 🎯 What You'll Learn
- What PRIMARY KEYs are and why every table needs one
- How FOREIGN KEYs create relationships between tables
- Adding UNIQUE constraints to prevent duplicates
- Using CHECK constraints to validate data
- Understanding referential integrity

---

## 🔑 PRIMARY KEY: The Unique Identifier

### What is a PRIMARY KEY?

A **PRIMARY KEY** uniquely identifies each row in a table - like a Social Security Number or Student ID.

### Visual Example

```
Customers Table
┌──────────┬───────────┬──────────┬──────────────────┐
│CustomerID│FirstName  │LastName  │ Email            │ ← PRIMARY KEY
├══════════┼───────────┼──────────┼──────────────────┤
│   1001   │ Sarah     │ Johnson  │sarah@email.com   │
│   1002   │ Mike      │ Chen     │mike@email.com    │
│   1003   │ Lisa      │ Davis    │lisa@email.com    │
└──────────┴───────────┴──────────┴──────────────────┘
    ↑
This must be UNIQUE for each customer
```

### Why Do We Need PRIMARY KEYs?

✅ **Uniquely identifies** each record  
✅ **Prevents duplicates** - can't have two customers with ID 1001  
✅ **Enables relationships** - other tables can reference this ID  
✅ **Improves performance** - makes searches faster  

---

## 🔗 FOREIGN KEY: Connecting Tables

### What is a FOREIGN KEY?

A **FOREIGN KEY** is a column that links to a PRIMARY KEY in another table.

### Visual: Products → Categories Relationship

```
Categories Table (Parent)
┌────────────┬────────────────┐
│ CategoryID │ CategoryName   │ ← PRIMARY KEY
├════════════┼────────────────┤
│     1      │ Electronics    │
│     2      │ Furniture      │
└────────────┴────────────────┘
      ↑
      │ Referenced by...
      │
Products Table (Child)
┌─────────┬──────────┬────────────┬────────┐
│ProductID│  Name    │ CategoryID │ Price  │
├─────────┼──────────┼────────────┼────────┤
│    1    │ Laptop   │     1      │ 999.99 │ ← Points to Electronics
│    2    │ Mouse    │     1      │  19.99 │ ← Points to Electronics  
│    3    │ Desk     │     2      │ 299.99 │ ← Points to Furniture
└─────────┴──────────┴────────────┴────────┘
                          ↑
                    FOREIGN KEY
```

**This means:**
- Every product MUST belong to a valid category
- You can't delete a category if products are using it
- You can't set CategoryID to 999 if category 999 doesn't exist

---

## 🏗️ Database Relationships Map

### Complete RetailStore Relationships

```
┌─────────────┐
│ Categories  │
│ (Parent)    │
└──────┬──────┘
       │
       │ CategoryID
       ↓
┌─────────────┐         ┌─────────────┐
│  Products   │←────────│  Suppliers  │
│             │SupplierID│   (Parent)  │
└──────┬──────┘         └─────────────┘
       │
       │ ProductID
       ↓
┌──────────────┐        ┌─────────────┐
│ OrderDetails │←───────│   Orders    │
│              │ OrderID│             │
└──────────────┘        └──────┬──────┘
                               │
                               │ CustomerID
                               ↓
                        ┌─────────────┐
                        │  Customers  │
                        │  (Parent)   │
                        └─────────────┘

┌─────────────┐
│ Departments │
│  (Parent)   │
└──────┬──────┘
       │
       │ DepartmentID
       ↓
┌─────────────┐
│  Employees  │
└─────────────┘
```

---

## 📊 One-to-Many Relationships

### Example 1: One Category → Many Products

```
Electronics (CategoryID = 1)
    ├── Laptop (ProductID = 1)
    ├── Mouse (ProductID = 2)
    ├── Keyboard (ProductID = 3)
    └── Monitor (ProductID = 4)

Furniture (CategoryID = 2)
    ├── Desk (ProductID = 5)
    └── Chair (ProductID = 6)
```

**One** category can have **many** products  
**Each** product belongs to **one** category

### Example 2: One Customer → Many Orders

```
Sarah Johnson (CustomerID = 1001)
    ├── Order #1000 (Jan 15, 2025)
    ├── Order #1005 (Feb 10, 2025)
    └── Order #1012 (Mar 05, 2025)

Mike Chen (CustomerID = 1002)
    └── Order #1001 (Jan 16, 2025)
```

**One** customer can have **many** orders  
**Each** order belongs to **one** customer

---

## ✨ UNIQUE Constraint

### What is UNIQUE?

**UNIQUE** ensures no duplicate values in a column (but allows NULL).

### Examples

```sql
-- Email must be unique for each customer
Email VARCHAR(150) UNIQUE

-- SKU must be unique for each product  
SKU VARCHAR(50) UNIQUE

-- Department name must be unique
DepartmentName NVARCHAR(100) UNIQUE
```

### Visual: Why UNIQUE Matters

```
❌ WITHOUT UNIQUE:
┌──────────┬─────────────────────┐
│CustomerID│ Email               │
├──────────┼─────────────────────┤
│   1001   │ sarah@email.com     │
│   1002   │ sarah@email.com     │ ← DUPLICATE! Bad!
└──────────┴─────────────────────┘

✅ WITH UNIQUE:
┌──────────┬─────────────────────┐
│CustomerID│ Email               │
├──────────┼─────────────────────┤
│   1001   │ sarah@email.com     │
│   1002   │ mike@email.com      │ ← All unique! Good!
└──────────┴─────────────────────┘
```

---

## ✓ CHECK Constraint

### What is CHECK?

**CHECK** validates data before allowing insert/update.

### Examples

```sql
-- Price must be positive
Price DECIMAL(10,2) CHECK (Price >= 0)

-- Quantity must be greater than 0
Quantity INT CHECK (Quantity > 0)

-- Salary must be non-negative
Salary MONEY CHECK (Salary >= 0)
```

### Visual: How CHECK Works

```
Trying to insert: Price = -50.00
                     ↓
              CHECK (Price >= 0)
                     ↓
                  FAIL! ❌
          "Price cannot be negative"


Trying to insert: Price = 99.99
                     ↓
              CHECK (Price >= 0)
                     ↓
                 SUCCESS! ✓
             Data is inserted
```

---

## 🛡️ Referential Integrity

### What is Referential Integrity?

**Referential Integrity** means:
1. FOREIGN KEYs must point to valid PRIMARY KEYs
2. Can't delete a parent record if children exist

### Example: Protected Deletion

```
Try to delete Electronics category:
┌────────────┬────────────────┐
│ CategoryID │ CategoryName   │
├────────────┼────────────────┤
│     1      │ Electronics    │ ← Try to DELETE
└────────────┴────────────────┘
       ↑
       │ Still referenced by...
       │
┌─────────┬──────────┬────────────┐
│ProductID│  Name    │ CategoryID │
├─────────┼──────────┼────────────┤
│    1    │ Laptop   │     1      │ ← Still using it!
│    2    │ Mouse    │     1      │ ← Still using it!
└─────────┴──────────┴────────────┘

Result: ❌ DELETE FAILED
"Cannot delete category because products reference it"
```

**Solution:**
1. First delete all products in that category
2. Then delete the category

---

## 📝 Constraint Types Summary

| Constraint | Purpose | Example |
|------------|---------|---------|
| **PRIMARY KEY** | Unique identifier | `CustomerID` |
| **FOREIGN KEY** | Link to another table | `Products.CategoryID → Categories.CategoryID` |
| **UNIQUE** | No duplicates allowed | `Email` must be unique |
| **CHECK** | Validate data | `Price >= 0` |
| **NOT NULL** | Required field | `FirstName` cannot be empty |
| **DEFAULT** | Automatic value | `Country DEFAULT 'USA'` |

---

## 🔧 Adding Constraints with ALTER TABLE

### Why Use ALTER TABLE?

In Lesson 02, we created tables without constraints. Now we add them!

### Step-by-Step Process

```sql
-- Step 1: Add PRIMARY KEY
ALTER TABLE Inventory.Categories
ADD CONSTRAINT PK_Categories PRIMARY KEY (CategoryID);

-- Step 2: Add UNIQUE constraint
ALTER TABLE Inventory.Categories
ADD CONSTRAINT UQ_CategoryName UNIQUE (CategoryName);

-- Step 3: Add CHECK constraint  
ALTER TABLE Inventory.Products
ADD CONSTRAINT CK_Price CHECK (Price >= 0);

-- Step 4: Add FOREIGN KEY
ALTER TABLE Inventory.Products
ADD CONSTRAINT FK_Products_Category 
    FOREIGN KEY (CategoryID) 
    REFERENCES Inventory.Categories(CategoryID);
```

---

## 🎨 Visual: Complete Products Table with All Constraints

```
Inventory.Products Table
┌═══════════════════════════════════════════════════════════┐
│ ProductID      INT (PRIMARY KEY, IDENTITY)                │
│                ↑ Unique identifier                        │
├───────────────────────────────────────────────────────────┤
│ ProductName    NVARCHAR(200) NOT NULL                     │
│                ↑ Required field                           │
├───────────────────────────────────────────────────────────┤
│ CategoryID     INT (FOREIGN KEY → Categories)             │
│                ↑ Must be valid category                   │
├───────────────────────────────────────────────────────────┤
│ SKU            VARCHAR(50) UNIQUE                         │
│                ↑ No duplicate codes                       │
├───────────────────────────────────────────────────────────┤
│ Price          DECIMAL(10,2) CHECK (Price >= 0)           │
│                ↑ Must be positive                         │
├───────────────────────────────────────────────────────────┤
│ QuantityInStock INT DEFAULT 0                            │
│                 ↑ Starts at 0 if not specified           │
└═══════════════════════════════════════════════════════════┘
```

---

## 🧪 Testing Constraints

### Test 1: PRIMARY KEY (Prevents Duplicates)

```sql
INSERT INTO Categories (CategoryID, CategoryName) VALUES (1, 'Electronics');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (1, 'Furniture');
-- ❌ Error: Duplicate PRIMARY KEY
```

### Test 2: FOREIGN KEY (Validates References)

```sql
INSERT INTO Products (ProductName, CategoryID) VALUES ('Laptop', 999);
-- ❌ Error: CategoryID 999 doesn't exist
```

### Test 3: CHECK (Validates Data)

```sql
INSERT INTO Products (ProductName, Price) VALUES ('Mouse', -10.00);
-- ❌ Error: Price cannot be negative
```

### Test 4: UNIQUE (Prevents Duplicates)

```sql
INSERT INTO Customers (Email) VALUES ('sarah@email.com');
INSERT INTO Customers (Email) VALUES ('sarah@email.com');
-- ❌ Error: Email must be unique
```

---

## 🎓 Key Takeaways

✅ **PRIMARY KEY** = Unique identifier for each row  
✅ **FOREIGN KEY** = Links tables together  
✅ **UNIQUE** = No duplicate values allowed  
✅ **CHECK** = Validates data before insert/update  
✅ **Referential Integrity** = Protects relationships  

---

## 💡 Real-World Benefits

### Without Constraints:
```
❌ Duplicate customer emails
❌ Products with negative prices
❌ Orders referencing non-existent customers
❌ Deleted categories with orphaned products
```

### With Constraints:
```
✅ Data integrity guaranteed
✅ Invalid data rejected automatically
✅ Relationships protected
✅ Database self-validates
```

---

## ➡️ Next Steps

- **Lesson 04**: More advanced constraints
- **Lesson 05**: Modifying tables (ALTER TABLE)
- **Lesson 06**: Inserting valid data

---

## 🧪 Try It Yourself!

```sql
-- View all constraints
SELECT 
    OBJECT_SCHEMA_NAME(parent_object_id) AS [Schema],
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.objects
WHERE type_desc LIKE '%CONSTRAINT'
ORDER BY [Schema], TableName;

-- Try to break a constraint (it should fail)
INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES ('Test Product', 9999, -50.00);
-- This should give you TWO errors:
-- 1. Invalid CategoryID (FOREIGN KEY)
-- 2. Negative price (CHECK)
```
