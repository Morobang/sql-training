# 🟢 Beginner SQL - Hands-On Practice

Welcome to Beginner SQL! This folder contains **hands-on SQL files** where you'll build a complete database from scratch.

## 📁 What's In This Folder

### ⭐ SQL Practice Files (Main Learning Path)
```
01-setup-database.sql      ← START HERE! Creates CompanyDB
03-select-queries.sql      ← Practice SELECT queries (31 examples)
04-create-tables.sql       ← Create tables with DDL
05-modify-data.sql         ← Insert/Update/Delete data
```

### 📚 Markdown Lessons (Read First, Then Practice)
```
01-intro-to-sql/          ← What is SQL?
02-setup-environment/     ← Install SQL Server
03-query-data/            ← SELECT explained
04-ddl-commands/          ← CREATE/ALTER/DROP explained
05-dml-commands/          ← INSERT/UPDATE/DELETE explained
```

---

## 🚀 Quick Start (3 Steps)

### 1. Setup (15 minutes)
```
1. Read: 02-setup-environment/setup-environment.md
2. Install SQL Server + SSMS (or Azure Data Studio)
3. Connect to your local server
```

### 2. Create Database (5 minutes)
```sql
-- Open: 01-setup-database.sql in SSMS
-- Click: Execute (F5)
-- Result: CompanyDB created with Employees table!
```

### 3. Start Learning!
```
Follow the learning path below →
```

---

## 📖 Learning Path

### **Lesson 1-2: Introduction & Setup**
**Read:** `01-intro-to-sql/`, `02-setup-environment/`  
**Run:** `01-setup-database.sql`

**You'll Learn:**
- What is SQL?
- Install SQL Server
- Create CompanyDB database
- Create Employees table with 10 rows

**Time:** 30 min

---

### **Lesson 3: Query Data (SELECT)** ⭐ MOST IMPORTANT
**Read:** `03-query-data/query-data.md`  
**Run:** `03-select-queries.sql`

**You'll Learn:**
- SELECT * and specific columns
- WHERE filtering
- Comparison operators (=, >, <, !=)
- LIKE pattern matching
- IN and BETWEEN
- AND/OR/NOT logic
- ORDER BY sorting
- TOP to limit results

**Practice:** 31 examples + 8 exercises  
**Time:** 1-2 hours

---

### **Lesson 4: DDL Commands**
**Read:** `04-ddl-commands/ddl-commands.md`  
**Run:** `04-create-tables.sql`

**You'll Learn:**
- CREATE TABLE
- Data types (INT, NVARCHAR, DECIMAL, DATE)
- Primary keys & IDENTITY
- Constraints (NOT NULL, CHECK, DEFAULT)
- ALTER TABLE
- DROP and TRUNCATE

**Creates:** Departments, Products, Customers tables  
**Time:** 1 hour

---

### **Lesson 5: DML Commands**
**Read:** `05-dml-commands/dml-commands.md`  
**Run:** `05-modify-data.sql`

**You'll Learn:**
- INSERT single & multiple rows
- UPDATE with WHERE
- DELETE safely
- BEGIN TRANSACTION
- COMMIT and ROLLBACK

**Practice:** 16 examples + 6 exercises  
**Time:** 1-2 hours

---

## 💡 The Incremental Database Approach

**Key Concept:** We build ONE database that grows across all lessons!

```
01-setup-database.sql  →  CompanyDB
                           └─ Employees (10 rows)

04-create-tables.sql   →  CompanyDB  
                           ├─ Employees
                           ├─ Departments (new!)
                           ├─ Products (new!)
                           └─ Customers (new!)

05-modify-data.sql     →  CompanyDB (with more data)
                           ├─ Employees (14+ rows)
                           ├─ Departments
                           ├─ Products (10+ rows)
                           └─ Customers (8+ rows)
```

**This means:**
- ✅ Run `01-setup-database.sql` ONCE
- ✅ Each file builds on previous ones
- ✅ Don't create/drop database in every file
- ❌ Don't skip files - they depend on each other!

---

## ⚠️ How to Use SQL Files

### ❌ DON'T Do This:
```
1. Open SQL file
2. Click Execute on entire file
3. Get overwhelmed by 100 results
```

### ✅ DO This:
```
1. Open SQL file
2. Read the comments
3. Highlight ONE example (Ctrl+Shift+End)
4. Press F5 to run just that section
5. Read the results
6. Understand what happened
7. Move to next example
```

**Example:**
```sql
-- Highlight just these 3 lines:
SELECT FirstName, LastName, Department
FROM Employees
WHERE Department = 'IT';

-- Press F5 → See results → Understand → Continue
```

---

## ✅ Completion Checklist

- [ ] Install SQL Server
- [ ] Install SSMS or Azure Data Studio
- [ ] Run `01-setup-database.sql` successfully
- [ ] Complete all 31 examples in `03-select-queries.sql`
- [ ] Do the 8 SELECT practice exercises
- [ ] Complete `04-create-tables.sql`
- [ ] Create your Projects table (exercise)
- [ ] Complete `05-modify-data.sql`
- [ ] Do all 6 DML exercises
- [ ] Experiment with your own queries!

---

## 🎯 After Completing Beginner

### You'll Be Able To:
✅ Write SELECT queries  
✅ Filter data with WHERE  
✅ Sort with ORDER BY  
✅ Create tables  
✅ Insert data  
✅ Update data  
✅ Delete data  
✅ Use transactions  

### Next Steps:
1. **Practice more** - Redo the exercises
2. **Explore** - `06-additional-topics/` for deep dives  
3. **Level up** - Move to `../02-intermediate/` when ready!

---

## 💬 FAQ

**Q: Can I skip the markdown files?**  
A: No! Read markdown first for concepts, then practice with SQL.

**Q: Do files need to run in order?**  
A: YES! Each builds on the previous.

**Q: What if I get an error?**  
A: Common fixes:
- Run `01-setup-database.sql` first
- Check you're connected to CompanyDB
- Check for typos

**Q: Can I modify the files?**  
A: Yes! That's how you learn. Experiment!

**Q: How long does this take?**  
A: 1-2 weeks with 30-60 min daily practice

---

**Ready? Start with** `01-setup-database.sql` **and let's build something! 🚀**
