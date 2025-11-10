# Lesson 01: Database Creation - Understanding the Foundation

## 🎯 What You'll Learn
- What a database is
- How databases organize data with schemas
- Creating your first database
- Understanding the three-tier structure: Database → Schema → Tables

---

## 📚 Database Structure Explained

Think of a database like an office building:

```
🏢 BUILDING (Database: RetailStore)
│
├── 📂 Floor 1 (Schema: Inventory)
│   ├── 📋 Categories Table
│   ├── 📋 Suppliers Table
│   └── 📋 Products Table
│
├── 📂 Floor 2 (Schema: Sales)
│   ├── 📋 Customers Table
│   ├── 📋 Orders Table
│   └── 📋 OrderDetails Table
│
└── 📂 Floor 3 (Schema: HR)
    ├── 📋 Departments Table
    └── 📋 Employees Table
```

---

## 🗄️ What is a Database?

A **database** is a container that holds all your data in an organized way.

### Real-World Analogy
- **Database** = Your entire filing cabinet
- **Schema** = Drawers in the cabinet (organized by department)
- **Tables** = Individual folders in each drawer

---

## 📊 The RetailStore Database Structure

### Database: `RetailStore`
Our sample database for a retail business

### Three Schemas (Organized Sections):

#### 1️⃣ **Inventory** Schema
Manages products and suppliers
- `Categories` - Product categories (Electronics, Clothing, etc.)
- `Suppliers` - Companies that supply products
- `Products` - Items for sale

#### 2️⃣ **Sales** Schema
Manages customer orders
- `Customers` - Customer information
- `Orders` - Customer orders
- `OrderDetails` - Items in each order

#### 3️⃣ **HR** Schema
Manages employees
- `Departments` - Company departments
- `Employees` - Employee records

---

## 🔍 Visual: Database Hierarchy

```
┌─────────────────────────────────────────────┐
│         DATABASE: RetailStore               │
│  (The entire data storage system)           │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │Inventory│ │ Sales  │  │   HR   │
   │ Schema │  │ Schema │  │ Schema │
   └────────┘  └────────┘  └────────┘
        │           │           │
        ▼           ▼           ▼
   [Tables]    [Tables]    [Tables]
```

---

## 💡 Why Use Schemas?

**Without Schemas:**
```
RetailStore Database:
├── Categories
├── Suppliers
├── Products
├── Customers
├── Orders
├── OrderDetails
├── Departments
└── Employees
```
❌ Hard to tell which tables are related!

**With Schemas:**
```
RetailStore Database:
├── Inventory.Categories
├── Inventory.Suppliers
├── Inventory.Products
├── Sales.Customers
├── Sales.Orders
├── Sales.OrderDetails
├── HR.Departments
└── HR.Employees
```
✅ Clear organization by business function!

---

## 🛠️ SQL Script Breakdown

### Step 1: Create the Database
```sql
CREATE DATABASE RetailStore;
```
Creates an empty container named `RetailStore`

### Step 2: Use the Database
```sql
USE RetailStore;
```
Tells SQL Server: "I want to work inside this database"

### Step 3: Create Schemas
```sql
CREATE SCHEMA Inventory;  -- For product management
CREATE SCHEMA Sales;      -- For customer orders
CREATE SCHEMA HR;         -- For employees
```

---

## 📋 Quick Reference

| Term | Definition | Example |
|------|------------|---------|
| **Database** | Main container for all data | `RetailStore` |
| **Schema** | Logical grouping within database | `Inventory`, `Sales`, `HR` |
| **Table** | Actual data storage (rows/columns) | `Inventory.Products` |
| **Full Table Name** | Schema.TableName | `Sales.Customers` |

---

## ✅ What Happens When You Run the Script?

1. **CREATE DATABASE** → Empty database created
2. **USE RetailStore** → You're now "inside" the database
3. **CREATE SCHEMA** (x3) → Three organizational sections created
4. **Verification Query** → Shows all schemas in your database

### Expected Output:
```
schema_name
-----------
dbo
Inventory
Sales
HR
```

---

## 🎓 Key Takeaways

✅ A **database** is the top-level container  
✅ **Schemas** organize tables by purpose  
✅ **Tables** will be created in the next lesson  
✅ Full table names use format: `SchemaName.TableName`  

---

## ➡️ Next Steps

Now that you have a database with schemas, you're ready for:
- **Lesson 02**: Creating tables with columns and data types
- **Lesson 03**: Adding relationships between tables

---

## 🧪 Try It Yourself!

After running `01-database-creation.sql`, try these queries:

```sql
-- See all schemas
SELECT * FROM sys.schemas 
WHERE name IN ('Inventory', 'Sales', 'HR');

-- Check which database you're using
SELECT DB_NAME() AS CurrentDatabase;

-- List all databases on your server
SELECT name FROM sys.databases;
```
