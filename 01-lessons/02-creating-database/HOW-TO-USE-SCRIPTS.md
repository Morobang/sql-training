# Chapter 02 SQL Scripts - How to Use

## 📁 Overview

This directory contains **practical SQL scripts** that you can run on your SQL Server installation. Each lesson has both comprehensive documentation (README.md) and executable SQL code (examples.sql).

## 🚀 Quick Start

### Step 1: Install SQL Server
- Download [SQL Server 2019 or later](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- Install [SQL Server Management Studio (SSMS)](https://aka.ms/ssmsfullsetup) or [Azure Data Studio](https://aka.ms/azuredatastudio)

### Step 2: Run Setup Script
**IMPORTANT**: Run this FIRST before any lesson scripts!

```sql
-- Run this file in SSMS or Azure Data Studio:
00-setup/complete-setup.sql
```

This creates:
- ✅ BookStore database
- ✅ All necessary tables (Customers, Products, Orders, etc.)
- ✅ Sample data
- ✅ Views and stored procedures

### Step 3: Run Lesson Scripts
After setup, you can run any lesson script:

```sql
-- Example: Learn about character data types
01-creating-mysql-database/examples.sql
03-data-types-character/examples.sql
04-data-types-numeric/examples.sql
05-data-types-temporal/examples.sql
```

### Step 4: Practice Exercises
Test your skills:

```sql
-- Run the exercises file:
../../02-exercises/chapter-02/exercises.sql
```

## 📚 Available Scripts

### 🔧 Setup & Configuration

| File | Purpose | Run First? |
|------|---------|------------|
| `00-setup/complete-setup.sql` | Complete database setup | ✅ **YES** |

### 📖 Lesson Scripts

| Lesson | File | Description |
|--------|------|-------------|
| 01 | `01-creating-mysql-database/examples.sql` | Creating databases, file groups, backups |
| 03 | `03-data-types-character/examples.sql` | CHAR, VARCHAR, NVARCHAR, collation |
| 04 | `04-data-types-numeric/examples.sql` | INT, DECIMAL, FLOAT, MONEY types |
| 05 | `05-data-types-temporal/examples.sql` | DATE, TIME, DATETIME2, timezones |
| 06 | `06-table-creation-design/examples.sql` | Table design, normalization (coming soon) |
| 07 | `07-table-creation-refinement/examples.sql` | Constraints, defaults (coming soon) |
| 08 | `08-building-schema-statements/examples.sql` | Complete schemas (coming soon) |
| 09 | `09-inserting-data/examples.sql` | INSERT statements, bulk operations (coming soon) |
| 10 | `10-updating-data/examples.sql` | UPDATE with JOIN, transactions (coming soon) |
| 11 | `11-deleting-data/examples.sql` | DELETE, TRUNCATE, soft deletes (coming soon) |

### 🎯 Practice & Exercises

| File | Purpose |
|------|---------|
| `02-exercises/chapter-02/exercises.sql` | Hands-on practice exercises |
| `02-exercises/chapter-02/solutions.sql` | Exercise solutions (coming soon) |

## 💡 How to Use the Scripts

### Method 1: SQL Server Management Studio (SSMS)

1. **Open SSMS**
2. **Connect** to your SQL Server instance
3. **File → Open → File**
4. **Select** the .sql file
5. **Click Execute** (F5) or click the green play button

### Method 2: Azure Data Studio

1. **Open Azure Data Studio**
2. **Connect** to your SQL Server
3. **File → Open File**
4. **Select** the .sql file
5. **Click Run** or press F5

### Method 3: Command Line (sqlcmd)

```powershell
# Run setup script
sqlcmd -S localhost -i "00-setup\complete-setup.sql"

# Run lesson script
sqlcmd -S localhost -i "03-data-types-character\examples.sql"
```

## 📋 Script Structure

Each lesson script follows this structure:

```sql
-- ============================================================================
-- SECTION 1: Introduction and Basic Concepts
-- ============================================================================

-- Example code you can run
SELECT * FROM Products;

-- ============================================================================
-- SECTION 2: Intermediate Examples
-- ============================================================================

-- More examples with explanations
-- Comments explain what each query does

-- ============================================================================
-- SECTION 3: Advanced Examples
-- ============================================================================

-- Real-world scenarios and best practices

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================

/*
-- Uncomment to remove test data
DROP TABLE IF EXISTS TestTable;
*/
```

## 🎓 Learning Path

Follow this sequence for best results:

```
1. Run complete-setup.sql (REQUIRED FIRST)
   ↓
2. Study lesson READMEs to understand concepts
   ↓
3. Run corresponding examples.sql files
   ↓
4. Experiment: Modify the code and see what happens
   ↓
5. Complete exercises.sql to test your knowledge
   ↓
6. Compare your solutions with solutions.sql
```

## ⚠️ Important Notes

### Before Running Scripts

- ✅ **Backup**: Always backup important data first
- ✅ **Test Environment**: Use a test SQL Server instance
- ✅ **Read First**: Read the comments in each script
- ✅ **Run Setup**: Always run `complete-setup.sql` first

### Data Paths

Some scripts create files in `C:\SQLData\`. If this path doesn't exist:

```sql
-- Option 1: Create the directory
-- In PowerShell: New-Item -Path "C:\SQLData" -ItemType Directory

-- Option 2: Change the path in the script
-- Edit FILENAME = 'C:\SQLData\...' to your preferred location
```

### Cleanup

Most scripts have a cleanup section at the end (commented out). Uncomment if you want to remove test data:

```sql
/*
-- Uncomment these lines to clean up
DROP TABLE IF EXISTS TestTable;
PRINT 'Cleanup complete';
*/
```

## 🔍 What Each Script Teaches

### 01-creating-mysql-database/examples.sql
- Creating databases with custom settings
- File groups for performance
- Viewing database information
- Backup and restore
- Database options

**Key Takeaways**: Database creation, configuration, and management

### 03-data-types-character/examples.sql
- CHAR vs VARCHAR
- Unicode (NVARCHAR) for international text
- String functions (CONCAT, SUBSTRING, TRIM)
- Collation and case sensitivity
- Pattern matching with LIKE

**Key Takeaways**: Choose the right character type for your data

### 04-data-types-numeric/examples.sql
- Integer types (TINYINT, SMALLINT, INT, BIGINT)
- DECIMAL for exact precision (money)
- FLOAT vs REAL (approximate)
- Mathematical operations
- Type conversion

**Key Takeaways**: Use DECIMAL for money, INT for counts

### 05-data-types-temporal/examples.sql
- DATE, TIME, DATETIME2
- DATETIMEOFFSET for timezones
- Date arithmetic (DATEADD, DATEDIFF)
- Formatting dates
- Practical examples (events, attendance, subscriptions)

**Key Takeaways**: DATETIME2 is preferred over DATETIME

## 🛠️ Troubleshooting

### "Cannot open database"
```sql
-- Solution: Run the setup script first
USE master;
GO
-- Then run: 00-setup/complete-setup.sql
```

### "Invalid object name"
```sql
-- Solution: Make sure you're in the right database
USE BookStore;
GO
```

### "Cannot drop database because it is currently in use"
```sql
-- Solution: Close all connections first
USE master;
GO
ALTER DATABASE BookStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE BookStore;
GO
```

### File path errors
```sql
-- Solution: Create the directory or change the path
-- Check if C:\SQLData exists
-- Or change FILENAME in script to valid path
```

## 📚 Additional Resources

- **SQL Server Documentation**: https://docs.microsoft.com/en-us/sql/
- **T-SQL Reference**: https://docs.microsoft.com/en-us/sql/t-sql/
- **SSMS Keyboard Shortcuts**: F5 (Execute), Ctrl+N (New Query)
- **Practice Sites**: SQLZoo, LeetCode SQL, HackerRank SQL

## 🎯 Tips for Success

1. **Read the Comments**: Every script has detailed comments explaining what's happening
2. **Run Line by Line**: Highlight specific sections and run them (F5 in SSMS)
3. **Experiment**: Modify the code to see what happens
4. **Break Things**: Learn by making mistakes in your test environment
5. **Build Projects**: Use these templates to create your own databases

## 🤝 Need Help?

- Review the lesson README.md files for detailed explanations
- Check the troubleshooting section above
- Run smaller sections of code to isolate issues
- Refer to SQL Server documentation

## ✅ Completion Checklist

Track your progress:

- [ ] Installed SQL Server and SSMS/Azure Data Studio
- [ ] Ran `complete-setup.sql` successfully
- [ ] Completed Lesson 01: Creating databases
- [ ] Completed Lesson 03: Character data types
- [ ] Completed Lesson 04: Numeric data types
- [ ] Completed Lesson 05: Temporal data types
- [ ] Completed all exercises in `exercises.sql`
- [ ] Built your own practice database

## 🚀 Next Steps

After mastering Chapter 02:
- Move to **Chapter 03**: Query Primer (SELECT, FROM, WHERE)
- Build a real project using what you learned
- Explore the Sakila sample database
- Create your own database design

---

**Happy Learning! 🎓**

Remember: The best way to learn SQL is by writing SQL. Don't just read—run the code!
