# 🟢 Beginner SQL - TechStore Database

Welcome to Beginner SQL! Learn SQL by building a **TechStore** database from scratch.

## 📁 What's In This Folder

### 🎯 Simple, Progressive Learning Path
```
01-create-database/       ← START HERE! Create TechStore
02-create-first-table/    ← Make your first Products table
03-insert-data/           ← Add products to your store
04-query-data/            ← View and filter products
05-add-more-tables/       ← Add Customers and Orders
06-table-relationships/   ← Connect tables with JOIN
```

### 📚 Old Lessons (To Be Updated)
```
01-intro-to-sql/          ← Concepts (being updated)
02-setup-environment/     ← Installation guide
03-query-data/            ← Query concepts
04-ddl-commands/          ← DDL concepts
05-dml-commands/          ← DML concepts
```

---

## 🚀 Quick Start Guide

### Step 1: Install SQL Server
1. Read: `02-setup-environment/setup-environment.md`
2. Install SQL Server + SSMS
3. Connect to your server

### Step 2: Follow The Lessons In Order
Each folder builds on the previous one!

---

## 📖 Learning Path (Follow In Order!)

### **Lesson 1: Create Database** (5 min)
📁 `01-create-database/`

```sql
CREATE DATABASE TechStore;  -- That's it!
USE TechStore;              -- Now use it
```

**What you'll learn:**
- How to create a database
- How to switch to using it

---

### **Lesson 2: Create First Table** (10 min)
📁 `02-create-first-table/`

```sql
CREATE TABLE Products (
    ProductID INT,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
```

**What you'll learn:**
- CREATE TABLE syntax
- Simple data types
- View table structure

---

### **Lesson 3: Insert Data** (15 min)
📁 `03-insert-data/`

```sql
INSERT INTO Products VALUES (1, 'Wireless Mouse', 29.99);
```

**What you'll learn:**
- Insert single record
- Insert multiple records

---

### **Lesson 4: Query Data** (30 min)
📁 `04-query-data/`

```sql
SELECT * FROM Products;              -- See all
SELECT ProductName FROM Products;    -- Specific columns
SELECT * FROM Products WHERE Price < 50;  -- Filter
SELECT * FROM Products ORDER BY Price;    -- Sort
```

**What you'll learn:**
- SELECT basics
- WHERE filtering
- ORDER BY sorting

---

### **Lesson 5: Add More Tables** (20 min)
📁 `05-add-more-tables/`

```sql
CREATE TABLE Customers (...);
CREATE TABLE Orders (...);
```

**What you'll learn:**
- Create Customers table
- Create Orders table
- Connect them with IDs

---

### **Lesson 6: Table Relationships** (30 min)
📁 `06-table-relationships/`

```sql
SELECT Customers.FirstName, Orders.OrderDate
FROM Customers
JOIN Orders ON Customers.CustomerID = Orders.CustomerID;
```

**What you'll learn:**
- JOIN two tables
- JOIN three tables
- See complete order information

---

## 💡 How These Lessons Work

### ✅ Simple Approach
- **One concept per file**
- **No complex IF statements**
- **No system queries**
- **Just pure SQL basics**

### 🎯 Run Files In Order
```
Lesson 1 → Lesson 2 → Lesson 3 → etc.
```
Each builds on the previous one!

### 📝 Each File Is Short
- 5-15 lines of actual SQL
- Easy to understand
- Quick to run

---

## ✅ Completion Checklist

- [ ] Create TechStore database
- [ ] Create Products table
- [ ] Insert 5 products
- [ ] Query all products
- [ ] Filter products by price
- [ ] Sort products
- [ ] Create Customers table
- [ ] Create Orders table
- [ ] Insert customer data
- [ ] Insert order data
- [ ] JOIN Customers and Orders
- [ ] JOIN all three tables

---

## 🎯 After Completing Beginner

### You'll Know:
✅ CREATE DATABASE  
✅ CREATE TABLE  
✅ INSERT data  
✅ SELECT queries  
✅ WHERE filtering  
✅ ORDER BY sorting  
✅ JOIN tables  

### Next Steps:
📁 Move to `../02-intermediate/` for:
- Primary Keys
- Foreign Keys
- Constraints
- Advanced JOINs
- Subqueries
- Functions

---

**Ready? Open** `01-create-database/01-create-database.sql` **and let's start! 🚀**
