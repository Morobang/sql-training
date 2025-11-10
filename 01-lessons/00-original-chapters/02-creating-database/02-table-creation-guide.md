# Lesson 02: Table Creation Basics - Building Your Data Structure

## 🎯 What You'll Learn
- What a table is (rows and columns)
- Creating tables with CREATE TABLE
- Choosing the right data types
- Understanding IDENTITY (auto-increment)
- Using DEFAULT values

---

## 📊 What is a Table?

A **table** is like a spreadsheet - it has:
- **Columns** (fields) - What kind of data you store
- **Rows** (records) - Individual entries

### Visual Example: Products Table

```
┌────────────────────────────────────────────────────────┐
│              Inventory.Products Table                  │
├──────────┬──────────────┬──────────┬───────┬──────────┤
│ProductID │ ProductName  │CategoryID│ Price │InStock   │
├──────────┼──────────────┼──────────┼───────┼──────────┤
│    1     │ Laptop       │    1     │ 999.99│   50     │
│    2     │ Mouse        │    1     │  19.99│  200     │
│    3     │ Desk Chair   │    2     │ 149.99│   30     │
└──────────┴──────────────┴──────────┴───────┴──────────┘
     ↑           ↑             ↑         ↑        ↑
  COLUMNS (what data we store)

  ← Each row is one product →
```

---

## 🏗️ The 8 Tables We're Creating

### Inventory Schema (Product Management)

#### 1. **Categories** Table
Stores product categories
```
┌────────────┬────────────────┬─────────────────────┐
│ CategoryID │ CategoryName   │ Description         │
├────────────┼────────────────┼─────────────────────┤
│     1      │ Electronics    │ Electronic devices  │
│     2      │ Furniture      │ Office furniture    │
└────────────┴────────────────┴─────────────────────┘
```

#### 2. **Suppliers** Table
Stores supplier information
```
┌───────────┬──────────────┬─────────────┬──────────┐
│SupplierID │SupplierName  │ContactName  │  Email   │
├───────────┼──────────────┼─────────────┼──────────┤
│     1     │ Tech Corp    │ John Smith  │j@tech.com│
│     2     │ Office Plus  │ Jane Doe    │j@office.c│
└───────────┴──────────────┴─────────────┴──────────┘
```

#### 3. **Products** Table
Stores products for sale
```
┌─────────┬──────────┬──────────┬─────────┬───────┬──────┐
│ProductID│  Name    │CategoryID│Supplier │ Price │Stock │
├─────────┼──────────┼──────────┼─────────┼───────┼──────┤
│    1    │ Laptop   │    1     │    1    │999.99 │  50  │
│    2    │ Mouse    │    1     │    1    │ 19.99 │ 200  │
│    3    │ Desk     │    2     │    2    │299.99 │  15  │
└─────────┴──────────┴──────────┴─────────┴───────┴──────┘
```

### Sales Schema (Customer Orders)

#### 4. **Customers** Table
```
┌──────────┬───────────┬──────────┬──────────────────┐
│CustomerID│FirstName  │LastName  │ Email            │
├──────────┼───────────┼──────────┼──────────────────┤
│   1001   │ Sarah     │ Johnson  │sarah@email.com   │
│   1002   │ Mike      │ Chen     │mike@email.com    │
└──────────┴───────────┴──────────┴──────────────────┘
```

#### 5. **Orders** Table
```
┌────────┬──────────┬────────────┬──────────┬─────────┐
│OrderID │CustomerID│ OrderDate  │  Total   │ Status  │
├────────┼──────────┼────────────┼──────────┼─────────┤
│  1000  │   1001   │ 2025-01-15 │  1019.98 │ Pending │
│  1001  │   1002   │ 2025-01-16 │   299.99 │ Shipped │
└────────┴──────────┴────────────┴──────────┴─────────┘
```

#### 6. **OrderDetails** Table
```
┌──────────┬────────┬─────────┬────────┬──────────┐
│ DetailID │OrderID │ProductID│Quantity│UnitPrice │
├──────────┼────────┼─────────┼────────┼──────────┤
│    1     │  1000  │    1    │   1    │  999.99  │
│    2     │  1000  │    2    │   1    │   19.99  │
│    3     │  1001  │    3    │   1    │  299.99  │
└──────────┴────────┴─────────┴────────┴──────────┘
```

### HR Schema (Employees)

#### 7. **Departments** Table
```
┌────────────┬────────────────┬──────────┐
│DepartmentID│DepartmentName  │ Location │
├────────────┼────────────────┼──────────┤
│     1      │ Sales          │ Floor 1  │
│     2      │ IT             │ Floor 2  │
└────────────┴────────────────┴──────────┘
```

#### 8. **Employees** Table
```
┌──────────┬──────────┬─────────┬──────────┬────────┐
│EmployeeID│FirstName │LastName │  Email   │ Salary │
├──────────┼──────────┼─────────┼──────────┼────────┤
│    1     │ Alice    │ Smith   │a@co.com  │ 50000  │
│    2     │ Bob      │ Jones   │b@co.com  │ 60000  │
└──────────┴──────────┴─────────┴──────────┴────────┘
```

---

## 📐 Understanding Data Types

### Common Data Types

| Data Type | What It Stores | Example | When to Use |
|-----------|----------------|---------|-------------|
| **INT** | Whole numbers | `42`, `1000`, `-5` | IDs, quantities, ages |
| **NVARCHAR(n)** | Text (Unicode) | `'John'`, `'电脑'` | Names, addresses (any language) |
| **VARCHAR(n)** | Text (ASCII only) | `'john@email.com'` | Emails, codes (English only) |
| **DECIMAL(10,2)** | Exact numbers | `19.99`, `1234.56` | Money, prices |
| **MONEY** | Currency | `$1,234.56` | Salary, prices |
| **BIT** | True/False | `0` or `1` | Yes/No flags |
| **DATE** | Date only | `2025-01-15` | Birthdate, hire date |
| **DATETIME2** | Date + time | `2025-01-15 14:30:00` | Order timestamp |

### Data Type Sizes

```
NVARCHAR(100)  →  Up to 100 characters (any language)
VARCHAR(50)    →  Up to 50 characters (English/ASCII)
DECIMAL(10,2)  →  10 total digits, 2 after decimal
                  Example: 12345678.90
```

---

## 🔢 IDENTITY: Auto-Incrementing IDs

**IDENTITY(start, increment)** automatically generates unique numbers.

### Example: IDENTITY(1,1)
```sql
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1)  -- Starts at 1, adds 1 each time
);
```

**What happens when you insert data:**
```
INSERT INTO Products (Name) VALUES ('Laptop');   → ProductID = 1
INSERT INTO Products (Name) VALUES ('Mouse');    → ProductID = 2
INSERT INTO Products (Name) VALUES ('Keyboard'); → ProductID = 3
```

### Different Starting Points

```sql
-- Start at 1001 (good for customer IDs)
CustomerID INT IDENTITY(1001,1)

-- Start at 1000 (good for order IDs)
OrderID INT IDENTITY(1000,1)
```

---

## ⚙️ DEFAULT Values

**DEFAULT** provides automatic values if you don't specify one.

### Example 1: Default Date
```sql
DateJoined DATETIME2 DEFAULT SYSDATETIME()
```
If you don't provide a date, it uses the current date/time automatically.

### Example 2: Default Country
```sql
Country NVARCHAR(100) DEFAULT 'USA'
```
If you don't specify a country, it assumes 'USA'.

### Example 3: Default Quantity
```sql
QuantityInStock INT DEFAULT 0
```
New products start with 0 in stock.

---

## 🛠️ CREATE TABLE Syntax

### Basic Structure
```sql
CREATE TABLE SchemaName.TableName (
    ColumnName DataType,
    ColumnName DataType,
    ColumnName DataType
);
```

### Real Example
```sql
CREATE TABLE Inventory.Categories (
    CategoryID INT IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500)
);
```

**Breakdown:**
- `Inventory.Categories` → Schema.TableName
- `CategoryID INT IDENTITY(1,1)` → Auto-incrementing ID
- `NVARCHAR(100)` → Text up to 100 characters
- `NOT NULL` → This field is required

---

## 🎨 Visual: Table Relationships (Preview)

Here's how our tables connect (we'll add these relationships in Lesson 03):

```
Categories ──────┐
                 │
                 ↓ CategoryID
              Products ────────┐
                 ↑             │
                 │             ↓ ProductID
Suppliers ───────┘         OrderDetails
                                ↑
                                │
                             Orders
                                ↑
                                │
                            Customers

Departments ──────→ Employees
    (DepartmentID)
```

---

## 📝 Column Naming Best Practices

✅ **Good Names:**
- `FirstName` (clear, descriptive)
- `OrderDate` (tells you what it is)
- `QuantityInStock` (specific)

❌ **Bad Names:**
- `FN` (unclear abbreviation)
- `Date` (which date?)
- `Qty` (not descriptive enough)

---

## 🔍 What NOT NULL Means

```sql
ProductName NVARCHAR(200) NOT NULL  -- Required field
Description NVARCHAR(500)           -- Optional (can be empty)
```

**NOT NULL** = This field MUST have a value  
**No NOT NULL** = This field is optional

---

## ✅ After Running This Script

You'll have **8 empty tables** ready for data:

```
Inventory.Categories    ✓ Created (empty)
Inventory.Suppliers     ✓ Created (empty)
Inventory.Products      ✓ Created (empty)
Sales.Customers         ✓ Created (empty)
Sales.Orders            ✓ Created (empty)
Sales.OrderDetails      ✓ Created (empty)
HR.Departments          ✓ Created (empty)
HR.Employees            ✓ Created (empty)
```

---

## 🎓 Key Takeaways

✅ Tables store data in rows (records) and columns (fields)  
✅ Choose data types based on what you're storing  
✅ IDENTITY auto-generates unique IDs  
✅ DEFAULT provides automatic values  
✅ NOT NULL makes fields required  

---

## ➡️ Next Steps

- **Lesson 03**: Add PRIMARY KEYs, FOREIGN KEYs, and relationships
- **Lesson 04**: Add constraints (UNIQUE, CHECK)
- **Lesson 06**: Insert data into your tables

---

## 🧪 Try It Yourself!

After running the script, try:

```sql
-- See all your tables
SELECT 
    SCHEMA_NAME(schema_id) AS [Schema],
    name AS TableName
FROM sys.tables
WHERE SCHEMA_NAME(schema_id) IN ('Inventory', 'Sales', 'HR')
ORDER BY [Schema], TableName;

-- See columns in a specific table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Products';
```
