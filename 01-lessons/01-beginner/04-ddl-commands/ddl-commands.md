# Lesson 4: DDL Commands

**Level:** 🟢 Beginner

## Learning Objectives

By the end of this lesson, you will be able to:
1. Create databases and tables with CREATE
2. Modify table structures with ALTER
3. Delete database objects with DROP
4. Understand data types for columns
5. Add primary keys and constraints
6. Follow SQL naming conventions

## What is DDL?

**DDL = Data Definition Language**

DDL statements **define and modify database structure** (not data itself).

**DDL Commands:**
```
CREATE   → Build new objects (databases, tables)
ALTER    → Modify existing objects
DROP     → Delete objects permanently
TRUNCATE → Remove all data from table
```

---

## Part 1: CREATE DATABASE

### Creating a Database

```sql
-- Create a new database
CREATE DATABASE CompanyDB;
```

**What it does:**
```
Creates a new container for tables, views, and other objects.
Like creating a new folder for your data.
```

### Using a Database

```sql
-- Switch to the database
USE CompanyDB;
```

**Now all commands will execute in CompanyDB.**

---

## Part 2: CREATE TABLE

### Basic CREATE TABLE

```sql
CREATE TABLE Customers (
    CustomerID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100)
);
```

**Structure:**
```
CREATE TABLE TableName (
    ColumnName DataType,
    ColumnName DataType,
    ...
);
```

### With Primary Key

```sql
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,  -- Unique identifier
    ProductName NVARCHAR(100) NOT NULL,  -- Required field
    Price DECIMAL(10,2),
    StockQuantity INT DEFAULT 0  -- Default value
);
```

**What it does:**
```
ProductID → Must be unique, cannot be NULL
ProductName → Cannot be NULL (required)
Price → Can be NULL (optional)
StockQuantity → Defaults to 0 if not specified
```

### With Auto-Increment

```sql
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,  -- Auto-increment
    CustomerID INT NOT NULL,
    OrderDate DATE DEFAULT GETDATE(),  -- Today's date
    TotalAmount DECIMAL(10,2)
);
```

**IDENTITY(1,1) explained:**
```
(1,1) → Start at 1, increment by 1
Result: 1, 2, 3, 4, 5...

When you INSERT, don't specify OrderID - it's automatic!
```

---

## Part 3: Data Types

### Numeric Types

```sql
CREATE TABLE SampleNumbers (
    SmallNum TINYINT,      -- 0 to 255
    RegularInt INT,        -- -2 billion to +2 billion
    BigNum BIGINT,         -- Very large numbers
    Price DECIMAL(10,2),   -- Exact: 10 total digits, 2 after decimal
    Percentage FLOAT       -- Approximate decimal
);
```

**When to use:**
```
INT          → IDs, counts, whole numbers
DECIMAL(p,s) → Money, prices (exact)
FLOAT        → Scientific calculations (approximate)
```

### Text Types

```sql
CREATE TABLE SampleText (
    FixedCode CHAR(5),        -- Fixed 5 characters: 'ABC  ' (padded)
    Name VARCHAR(100),        -- Variable up to 100 chars (ASCII)
    Description NVARCHAR(500) -- Variable up to 500 chars (Unicode)
);
```

**Difference:**
```
CHAR(n)       → Fixed length, padded with spaces
VARCHAR(n)    → Variable length, up to n characters
NVARCHAR(n)   → Unicode (supports all languages)

Use NVARCHAR for international names/text!
```

### Date/Time Types

```sql
CREATE TABLE SampleDates (
    BirthDate DATE,           -- Date only: 2024-01-15
    CreatedAt DATETIME,       -- Date + Time: 2024-01-15 14:30:00
    Timestamp DATETIME2,      -- More precision
    TimeOnly TIME             -- Time only: 14:30:00
);
```

### Boolean Type

```sql
CREATE TABLE SampleBoolean (
    IsActive BIT,  -- 0 = False, 1 = True
    IsVerified BIT DEFAULT 0
);
```

---

## Part 4: Constraints

### NOT NULL

```sql
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,  -- Required
    LastName NVARCHAR(50) NOT NULL,   -- Required
    MiddleName NVARCHAR(50)           -- Optional (can be NULL)
);
```

### UNIQUE

```sql
CREATE TABLE Users (
    UserID INT PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE,  -- No duplicates allowed
    Email NVARCHAR(100) UNIQUE
);
```

### CHECK

```sql
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2) CHECK (Price >= 0),  -- Must be positive
    StockQuantity INT CHECK (StockQuantity >= 0)
);
```

### DEFAULT

```sql
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATE DEFAULT GETDATE(),  -- Today if not specified
    Status NVARCHAR(20) DEFAULT 'Pending',
    IsActive BIT DEFAULT 1
);
```

---

## Part 5: ALTER TABLE

### Add a Column

```sql
-- Add new column to existing table
ALTER TABLE Customers
ADD PhoneNumber VARCHAR(20);
```

**Before:**
```
Customers
├── CustomerID
├── FirstName
├── LastName
└── Email
```

**After:**
```
Customers
├── CustomerID
├── FirstName
├── LastName
├── Email
└── PhoneNumber  ← New column (all rows = NULL initially)
```

### Add Column with Default

```sql
ALTER TABLE Customers
ADD Country NVARCHAR(50) DEFAULT 'USA';
```

**New rows:** Country = 'USA' if not specified  
**Existing rows:** Country = 'USA' (filled with default)

### Drop a Column

```sql
ALTER TABLE Customers
DROP COLUMN PhoneNumber;
```

**⚠️ Warning:** Data in that column is permanently deleted!

### Modify Column Type

```sql
-- Make Email column bigger
ALTER TABLE Customers
ALTER COLUMN Email NVARCHAR(200);
```

**Before:** Email NVARCHAR(100)  
**After:** Email NVARCHAR(200)

### Add Constraint

```sql
-- Add CHECK constraint to existing table
ALTER TABLE Products
ADD CONSTRAINT CK_Price_Positive CHECK (Price >= 0);
```

---

## Part 6: DROP

### Drop Table

```sql
-- Delete table and all its data
DROP TABLE OldTable;
```

**⚠️ Warning:**
```
✗ Table structure deleted
✗ All data deleted
✗ Cannot undo!

Always backup before dropping!
```

### Drop Database

```sql
-- Delete entire database
DROP DATABASE OldDatabase;
```

**⚠️ Even more dangerous:**
```
Deletes:
✗ All tables
✗ All data
✗ All views, procedures, etc.
```

---

## Part 7: TRUNCATE

### TRUNCATE vs DELETE

```sql
-- Remove all data, keep table structure
TRUNCATE TABLE Logs;
```

**TRUNCATE vs DELETE:**

| Feature | TRUNCATE | DELETE |
|---------|----------|--------|
| Speed | ⚡ Very fast | 🐌 Slower |
| WHERE clause | ❌ No | ✅ Yes |
| Reset IDENTITY | ✅ Yes | ❌ No |
| Can rollback | ⚠️ Depends | ✅ Yes |
| Use case | Clear entire table | Delete specific rows |

**Example:**
```sql
-- DELETE: Can filter rows
DELETE FROM Orders WHERE OrderDate < '2020-01-01';

-- TRUNCATE: Always all rows
TRUNCATE TABLE Logs;  -- Removes everything
```

---

## Part 8: Real-World Examples

### Example 1: E-Commerce Schema

```sql
CREATE DATABASE ECommerceDB;
GO

USE ECommerceDB;
GO

CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    CreatedDate DATE DEFAULT GETDATE()
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50),
    Price DECIMAL(10,2) CHECK (Price > 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0)
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE DEFAULT GETDATE(),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20) DEFAULT 'Pending'
);
```

### Example 2: Adding Features Later

```sql
-- Add loyalty points column
ALTER TABLE Customers
ADD LoyaltyPoints INT DEFAULT 0;

-- Add constraint for valid status values
ALTER TABLE Orders
ADD CONSTRAINT CK_ValidStatus 
    CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'));

-- Add timestamp tracking
ALTER TABLE Products
ADD LastUpdated DATETIME DEFAULT GETDATE();
```

---

## Part 9: Best Practices

### Naming Conventions

```sql
-- ✅ GOOD
CREATE TABLE Customers (...)
CREATE TABLE OrderDetails (...)
CREATE TABLE ProductCategories (...)

-- ❌ BAD
CREATE TABLE customer (...)      -- Use PascalCase
CREATE TABLE tbl_orders (...)    -- Don't use prefixes
CREATE TABLE product_category (...) -- Not snake_case in SQL Server
```

### Always Use Primary Keys

```sql
-- ✅ GOOD
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    ...
);

-- ❌ BAD
CREATE TABLE Employees (
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
    -- No primary key!
);
```

### Use NOT NULL Where Appropriate

```sql
-- ✅ GOOD: Clear what's required
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,  -- Required
    Description NVARCHAR(500),           -- Optional
    Price DECIMAL(10,2) NOT NULL,        -- Required
    DiscountPrice DECIMAL(10,2)          -- Optional
);
```

### Use Meaningful Data Types

```sql
-- ✅ GOOD
CREATE TABLE Events (
    EventDate DATE,              -- Just the date
    EventTime TIME,              -- Just the time
    Price DECIMAL(10,2),         -- Exact money
    IsActive BIT                 -- Boolean
);

-- ❌ BAD
CREATE TABLE Events (
    EventDate VARCHAR(50),       -- Should be DATE
    Price FLOAT,                 -- Should be DECIMAL for money
    IsActive VARCHAR(10)         -- Should be BIT
);
```

---

## Part 10: Common Mistakes

### Mistake 1: Forgetting PRIMARY KEY

```sql
-- ❌ WRONG
CREATE TABLE Users (
    Username VARCHAR(50),
    Email VARCHAR(100)
);

-- ✅ CORRECT
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) UNIQUE,
    Email VARCHAR(100) UNIQUE
);
```

### Mistake 2: Wrong Data Type

```sql
-- ❌ WRONG: Using wrong types
CREATE TABLE Prices (
    Amount FLOAT  -- Bad for money (rounding errors)
);

-- ✅ CORRECT
CREATE TABLE Prices (
    Amount DECIMAL(10,2)  -- Exact for money
);
```

### Mistake 3: No Constraints

```sql
-- ❌ WRONG: No validation
CREATE TABLE Products (
    Price DECIMAL(10,2)  -- Could be negative!
);

-- ✅ CORRECT
CREATE TABLE Products (
    Price DECIMAL(10,2) CHECK (Price >= 0)
);
```

---

## Practice Exercises

### Exercise 1: Create Tables
```sql
-- Create a database and tables for a library system:
-- - Database: LibraryDB
-- - Table: Books (BookID, Title, Author, ISBN, PublishedYear, Pages)
-- - Table: Members (MemberID, FirstName, LastName, Email, JoinDate)

-- Write your solution:
```

### Exercise 2: Alter Tables
```sql
-- Add these features to the Books table:
-- - Add column: Genre (NVARCHAR(50))
-- - Add column: IsAvailable (BIT with default 1)
-- - Add constraint: Pages must be greater than 0

-- Write your solution:
```

### Exercise 3: Constraints
```sql
-- Create an Orders table with:
-- - OrderID (auto-increment primary key)
-- - MemberID (required)
-- - BookID (required)
-- - BorrowDate (defaults to today)
-- - ReturnDate (optional)
-- - Status (must be 'Borrowed', 'Returned', or 'Overdue')

-- Write your solution:
```

---

## Key Takeaways

### DDL Commands
```
CREATE   → Make new database/table
ALTER    → Modify existing structure
DROP     → Delete permanently
TRUNCATE → Remove all data (keep structure)
```

### Essential Data Types
```
INT              → Whole numbers
DECIMAL(10,2)    → Money/exact decimals
NVARCHAR(n)      → Text (Unicode)
DATE             → Dates
DATETIME         → Date + Time
BIT              → True/False
```

### Must-Know Constraints
```
PRIMARY KEY      → Unique identifier
NOT NULL         → Required field
UNIQUE           → No duplicates
CHECK            → Validation rule
DEFAULT          → Auto-fill value
IDENTITY(1,1)    → Auto-increment
```

### Best Practices
```
✓ Always use PRIMARY KEY
✓ Use NOT NULL for required fields
✓ Add CHECK constraints for validation
✓ Use appropriate data types
✓ Follow naming conventions
✗ Don't use SELECT * in production
✗ Don't forget to backup before DROP
```

---

## Quick Reference

```sql
-- CREATE DATABASE
CREATE DATABASE MyDB;
USE MyDB;

-- CREATE TABLE
CREATE TABLE TableName (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Price DECIMAL(10,2) CHECK (Price >= 0),
    Status NVARCHAR(20) DEFAULT 'Active',
    CreatedDate DATE DEFAULT GETDATE()
);

-- ALTER TABLE
ALTER TABLE TableName ADD NewColumn VARCHAR(50);
ALTER TABLE TableName DROP COLUMN OldColumn;
ALTER TABLE TableName ALTER COLUMN Name NVARCHAR(200);

-- DROP
DROP TABLE TableName;
DROP DATABASE DatabaseName;

-- TRUNCATE
TRUNCATE TABLE TableName;
```

---

## Next Lesson

**Continue to [Lesson 5: DML Commands](../05-dml-commands/dml-commands.md)**  
Learn to insert, update, and delete data with INSERT, UPDATE, DELETE.

---

## Additional Resources

- **CREATE TABLE:** https://docs.microsoft.com/sql/t-sql/statements/create-table
- **ALTER TABLE:** https://docs.microsoft.com/sql/t-sql/statements/alter-table
- **Data Types:** https://docs.microsoft.com/sql/t-sql/data-types/data-types

**Great work! You now know how to create and modify database structures! 🏗️**
