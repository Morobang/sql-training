# Chapter 02: Creating and Populating a Database - Complete Guide

## 📁 Files Overview

This chapter contains **comprehensive SQL scripts** for every lesson, allowing you to learn by doing!

---

## 🚀 Quick Start (First Time)

1. **Run Setup Script First:**
   ```bash
   # Open SQL Server Management Studio (SSMS) or Azure Data Studio
   # Connect to your SQL Server instance
   # Open and execute:
   00-setup/complete-setup.sql
   ```
   This creates the `BookStore` database used throughout Chapter 02.

2. **Then Run Any Lesson Script:**
   ```bash
   # Execute lesson scripts in SSMS in any order
   01-creating-mysql-database/examples.sql
   03-data-types-character/examples.sql
   # etc.
   ```

---

## 📚 Lesson Scripts

### **Lesson 01: Creating MySQL Database**
- **File:** `01-creating-mysql-database/examples.sql` (~400 lines)
- **Topics:**
  - Basic database creation
  - Custom file locations and sizes
  - Multiple filegroups
  - Viewing database information
  - Backup and restore operations
  - Database options and configurations
  - Dropping databases safely
  - Best practices

### **Lesson 03: Character Data Types**
- **File:** `03-data-types-character/examples.sql` (~600 lines)
- **Topics:**
  - CHAR vs VARCHAR vs NVARCHAR
  - Fixed-length vs variable-length strings
  - Unicode (NVARCHAR) vs ASCII (VARCHAR)
  - Storage size comparisons
  - Collation and case sensitivity
  - String truncation
  - MAX keyword for large text
  - Common string functions
  - Best practices for choosing types

### **Lesson 04: Numeric Data Types**
- **File:** `04-data-types-numeric/examples.sql` (~700 lines)
- **Topics:**
  - Integer types: TINYINT, SMALLINT, INT, BIGINT
  - Exact numeric: DECIMAL, NUMERIC
  - Approximate numeric: FLOAT, REAL
  - MONEY and SMALLMONEY
  - Storage sizes and ranges
  - Precision and scale
  - Rounding behavior
  - Financial calculations (e-commerce examples)
  - BIT data type for flags
  - Type conversion and casting

### **Lesson 05: Temporal Data Types**
- **File:** `05-data-types-temporal/examples.sql` (~800 lines)
- **Topics:**
  - DATE, TIME, DATETIME, DATETIME2, SMALLDATETIME
  - DATETIMEOFFSET for timezone awareness
  - Precision and storage sizes
  - Date arithmetic (DATEADD, DATEDIFF)
  - Formatting dates (FORMAT, CONVERT)
  - Extracting parts (YEAR, MONTH, DAY)
  - Current date/time functions (GETDATE, SYSDATETIME)
  - Timezone handling
  - Business date calculations (age, duration, SLA)
  - Best practices

### **Lesson 06: Table Creation & Design**
- **File:** `06-table-creation-design/examples.sql` (~600 lines)
- **Topics:**
  - Problems with unnormalized data
  - First Normal Form (1NF)
  - Second Normal Form (2NF)
  - Third Normal Form (3NF)
  - Entity relationships:
    - One-to-one
    - One-to-many
    - Many-to-many (junction tables)
  - Self-referencing relationships
  - Complete library system example
  - Design best practices

### **Lesson 07: Table Refinement**
- **File:** `07-table-creation-refinement/examples.sql` (~700 lines)
- **Topics:**
  - PRIMARY KEY constraints
  - FOREIGN KEY constraints
  - Cascading actions (DELETE CASCADE, UPDATE CASCADE)
  - UNIQUE constraints
  - CHECK constraints (business rules)
  - DEFAULT constraints
  - Computed columns (calculated, PERSISTED)
  - IDENTITY columns (auto-increment)
  - Comprehensive e-commerce example
  - ALTER TABLE to modify constraints
  - Best practices

### **Lesson 08: Building Schema Statements**
- **File:** `08-building-schema-statements/examples.sql` (~550 lines)
- **Topics:**
  - Complete schema creation (step by step)
  - Dependency ordering (parent → child → junction)
  - Creating indexes for performance
  - Creating views for abstraction
  - Creating stored procedures
  - Populating with sample data
  - Schema validation queries
  - Modular schema scripts (production pattern)
  - Schema change management
  - Documentation with extended properties
  - Transactional deployment
  - Testing strategies
  - Best practices checklist

### **Lesson 09: Inserting Data**
- **File:** `09-inserting-data/examples.sql` (~600 lines)
- **Topics:**
  - Basic INSERT statements
  - Multiple row INSERT
  - OUTPUT clause (returning inserted data)
  - INSERT...SELECT (copying data)
  - IDENTITY handling (SCOPE_IDENTITY)
  - SET IDENTITY_INSERT ON/OFF
  - Foreign key insert order
  - INSERT with DEFAULT values
  - Bulk insert operations
  - Transactions (COMMIT, ROLLBACK)
  - Error handling (TRY...CATCH)
  - Best practices
  - Common patterns (INSERT IF NOT EXISTS)

### **Lesson 10: Updating Data**
- **File:** `10-updating-data/examples.sql` (~650 lines)
- **Topics:**
  - Basic UPDATE statements
  - UPDATE with calculations
  - UPDATE with CASE expressions
  - UPDATE with JOIN
  - UPDATE with subqueries
  - OUTPUT clause (capturing changes)
  - Transactions for updates
  - Best practices (test with SELECT first)
  - Common patterns (conditional updates, batch updates)
  - Performance considerations
  - Common mistakes to avoid
  - Multi-table UPDATE scenarios

### **Lesson 11: Deleting Data**
- **File:** `11-deleting-data/examples.sql` (~700 lines)
- **Topics:**
  - Basic DELETE statements
  - Complex WHERE clauses
  - DELETE with JOIN
  - OUTPUT clause (archiving deleted data)
  - TRUNCATE TABLE
  - **DELETE vs TRUNCATE vs DROP** (comparison table)
  - Cascading DELETE (ON DELETE CASCADE)
  - Soft DELETE pattern (logical delete with flags)
  - Transactions
  - Best practices
  - Common patterns (delete duplicates, old records)
  - Archive and delete pattern
  - Performance and safety tips

---

## 💪 Practice Exercises

### **Exercise Sets** (`02-exercises/chapter-02/`)

**File:** `exercises.sql` (~550 lines)
- **8 comprehensive exercise sets:**
  1. Database and data types
  2. Table design and normalization
  3. Constraints and data integrity
  4. Inserting data
  5. Updating data
  6. Deleting data
  7. Complex queries
  8. Advanced challenges (views, procedures, triggers)

**File:** `solutions.sql` (~800 lines)
- Complete solutions with explanations
- Alternative approaches
- Real-world scenarios (Movie Rental System, Student Enrollment)
- Best practices demonstrated

---

## 📖 Documentation Files

Located in `01-lessons/02-creating-database/`:

1. **HOW-TO-USE-SCRIPTS.md**
   - Detailed usage instructions
   - Prerequisites
   - Execution order
   - Troubleshooting guide

2. **QUICK-START.md**
   - 5-minute getting started guide
   - Essential commands
   - Common operations

3. **DIRECTORY-STRUCTURE.md**
   - Complete file map
   - Navigation guide
   - File descriptions

4. **WHATS-NEW-SCRIPTS.md**
   - Feature overview
   - Benefits of SQL scripts
   - Impact on learning

---

## 🎯 Learning Path

### **Recommended Order:**

1. ✅ **Setup** → Run `00-setup/complete-setup.sql`
2. ✅ **Read** → `README.md` for each lesson (theory)
3. ✅ **Execute** → `examples.sql` for each lesson (practice)
4. ✅ **Practice** → `exercises.sql` (hands-on problems)
5. ✅ **Verify** → `solutions.sql` (check your work)

### **Time Estimates:**

- **Setup:** 5 minutes (one-time)
- **Per Lesson:** 30-45 minutes (read + execute + experiment)
- **Exercises:** 2-3 hours (practice all 8 sets)
- **Total Chapter:** ~8-10 hours for mastery

---

## 🔍 Key Features

### ✨ Every Script Includes:

- ✅ **Extensive comments** explaining every concept
- ✅ **DROP IF EXISTS** for safe re-running
- ✅ **Multiple sections** (8-13 per lesson)
- ✅ **Real-world examples** (e-commerce, library, HR)
- ✅ **Error handling** with TRY...CATCH
- ✅ **OUTPUT statements** to show results
- ✅ **Best practices summaries**
- ✅ **Cleanup sections** (commented out)
- ✅ **Progress indicators** (PRINT statements)

### 🎓 Learning Approach:

- **Theory + Practice:** README for concepts, SQL scripts for hands-on
- **Progressive Complexity:** Simple examples → Complex scenarios
- **Safe Environment:** All scripts can be run multiple times
- **Immediate Feedback:** See results instantly
- **Production-Ready:** Patterns used in real applications

---

## 📊 Script Statistics

| Metric | Value |
|--------|-------|
| **Total Scripts** | 11 lesson scripts + 1 setup + 1 exercises + 1 solutions |
| **Total Lines** | ~8,500+ lines of executable SQL |
| **Topics Covered** | 50+ database concepts |
| **Examples** | 100+ working examples |
| **Sections** | 130+ organized sections |
| **Exercise Problems** | 24 problems across 8 sets |

---

## 🛠️ Prerequisites

- **SQL Server 2019+** (SQL Server 2022 recommended)
- **SSMS** or **Azure Data Studio**
- **Windows, macOS, or Linux**
- **Basic SQL knowledge** (helpful but not required)

---

## 🆘 Troubleshooting

### Common Issues:

**Error: Cannot open database "BookStore"**
- **Solution:** Run `00-setup/complete-setup.sql` first

**Error: Invalid object name**
- **Solution:** Make sure you're connected to the `BookStore` database
- **Check:** `USE BookStore;` at the top of scripts

**Error: File path not found**
- **Solution:** Create the directory or change the path in scripts
- **Example:** Change `C:\SQLData\` to your preferred location

**Script takes long time**
- **Solution:** Normal for comprehensive scripts (contains many examples)
- **Tip:** Execute section by section (highlight and run)

---

## 🎉 What You'll Master

By completing Chapter 02, you will:

✅ Create databases with custom configurations  
✅ Choose appropriate data types for any scenario  
✅ Design normalized tables (1NF, 2NF, 3NF)  
✅ Implement all constraint types  
✅ Build complete schemas with relationships  
✅ Insert data efficiently (single, bulk, transactions)  
✅ Update data safely (with joins, subqueries, CASE)  
✅ Delete data properly (DELETE vs TRUNCATE vs DROP)  
✅ Write complex queries with joins and aggregates  
✅ Create views, procedures, and triggers  
✅ Apply production best practices  

---

## 🚀 Next Steps

After mastering Chapter 02:

1. **Move to Chapter 03:** Query Primer
2. **Practice daily:** Run scripts multiple times
3. **Experiment:** Modify examples with your own data
4. **Build projects:** Apply concepts to real scenarios

---

## 📞 Support

- **Questions?** Review the README.md files for detailed explanations
- **Stuck?** Check solutions.sql for complete answers
- **Need help?** Refer to HOW-TO-USE-SCRIPTS.md

---

**Happy Learning! 🎓**

*Remember: The best way to learn SQL is by writing SQL. Run these scripts, experiment, break things, fix them, and most importantly—have fun!*
