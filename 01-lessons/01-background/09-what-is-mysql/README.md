# What is SQL Server?

## 🎯 Learning Objectives

- Understand what Microsoft SQL Server is
- Learn about SQL Server editions and features
- Explore SQL Server architecture
- Discover T-SQL (Transact-SQL) extensions
- Compare SQL Server with other database systems

---

## What is Microsoft SQL Server?

**Microsoft SQL Server** is a relational database management system (RDBMS) developed by Microsoft.

> SQL Server is an enterprise-grade database platform that stores, retrieves, and manages data for applications ranging from small websites to large enterprise systems.

**First Release:** 1989 (originally developed with Sybase)  
**Current Version:** SQL Server 2022  
**Platform:** Windows, Linux, Docker containers  
**Language:** T-SQL (Transact-SQL)

---

## SQL Server Editions

Microsoft offers several editions to meet different needs and budgets:

### 1. Express Edition (Free) 💚

**Best For:** Learning, small applications, development

**Features:**
- ✅ Free forever
- ✅ Full database engine
- ✅ 10 GB database size limit
- ✅ 1 GB RAM limit
- ✅ Limited to 1 CPU socket

**Use Cases:**
- Learning SQL
- Small websites
- Desktop applications
- Development/testing

**Download:** [Microsoft SQL Server Express](https://www.microsoft.com/sql-server/sql-server-downloads)

---

### 2. Developer Edition (Free) 💚⭐

**Best For:** Development and testing

**Features:**
- ✅ **FREE for dev/test** (not for production)
- ✅ **All Enterprise features**
- ✅ No database size limits
- ✅ No CPU limits
- ✅ Full feature set

**Use Cases:**
- Application development
- Testing
- Learning advanced features
- This course! 🎓

**Licensing:** Free but **cannot be used in production**

---

### 3. Standard Edition 💼

**Best For:** Mid-sized businesses

**Features:**
- Basic business intelligence
- Up to 24 cores or 4 sockets
- 128 GB buffer pool size
- Basic high availability

**Price:** ~$3,700 per core (one-time) or $2,000/year subscription

---

### 4. Enterprise Edition 💼💼💼

**Best For:** Large enterprises, mission-critical systems

**Features:**
- ✅ All features unlocked
- ✅ Unlimited database size
- ✅ Advanced high availability
- ✅ Advanced security
- ✅ In-memory OLTP
- ✅ Advanced analytics

**Price:** ~$14,000 per core (one-time) or ~$7,000/year subscription

**Use Cases:**
- Fortune 500 companies
- Large-scale applications
- Mission-critical systems

---

### Quick Comparison

| Feature | Express | Developer | Standard | Enterprise |
|---------|---------|-----------|----------|------------|
| **Cost** | Free | Free (dev only) | $$$ | $$$$ |
| **Production Use** | ✅ | ❌ | ✅ | ✅ |
| **Database Size** | 10 GB | Unlimited | Unlimited | Unlimited |
| **Memory** | 1 GB | Unlimited | 128 GB | Unlimited |
| **CPUs** | 1 socket | Unlimited | 24 cores | Unlimited |
| **Advanced Features** | Basic | All | Some | All |

---

## SQL Server Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────┐
│              SQL Server Instance                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Relational Engine (Query Processor)      │  │
│  │  • Parser                                        │  │
│  │  • Query Optimizer                               │  │
│  │  • Query Executor                                │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                              │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Storage Engine                           │  │
│  │  • Buffer Manager (Cache)                        │  │
│  │  • Transaction Manager                           │  │
│  │  • Lock Manager                                  │  │
│  │  • File Manager                                  │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                              │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Physical Storage                         │  │
│  │  • Data Files (.mdf, .ndf)                       │  │
│  │  • Log Files (.ldf)                              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Key Components Explained

#### 1. Relational Engine (Query Processor)

**Parser:**
- Checks SQL syntax
- Validates object names
- Converts SQL to internal format

**Query Optimizer:**
- Analyzes query
- Considers indexes, statistics
- Generates execution plan
- Chooses fastest approach

**Query Executor:**
- Executes the plan
- Retrieves data
- Returns results

---

#### 2. Storage Engine

**Buffer Manager:**
- Manages memory cache (buffer pool)
- Keeps frequently accessed data in RAM
- Dramatically speeds up queries

**Transaction Manager:**
- Ensures ACID properties
- Manages BEGIN, COMMIT, ROLLBACK
- Handles concurrent transactions

**Lock Manager:**
- Prevents conflicting operations
- Manages row/page/table locks
- Ensures data consistency

---

#### 3. Database Files

**Primary Data File (.mdf):**
- Contains database objects and data
- Every database has one .mdf file

**Secondary Data Files (.ndf):**
- Additional data files (optional)
- Used for large databases

**Transaction Log File (.ldf):**
- Records all transactions
- Used for recovery
- Essential for backup/restore

**Example:**
```
CompanyDB
├── CompanyDB.mdf       (Primary data file)
├── CompanyDB_Data.ndf  (Secondary data file - optional)
└── CompanyDB_Log.ldf   (Transaction log)
```

---

## SQL Server Instance

An **instance** is a complete installation of SQL Server.

### Default Instance
```
Server Name: COMPUTERNAME
Connection: localhost
            127.0.0.1
            (local)
```

### Named Instance
```
Server Name: COMPUTERNAME\INSTANCENAME
Connection: localhost\SQL2022
```

**You can have multiple instances on one machine!**

---

## T-SQL: Transact-SQL

**T-SQL** is Microsoft's implementation of SQL with procedural programming extensions.

### Standard SQL (Works Everywhere)

```sql
-- Standard SELECT
SELECT first_name, last_name
FROM employees
WHERE salary > 70000;
```

---

### T-SQL Extensions

#### Variables

```sql
DECLARE @MinSalary DECIMAL(10,2) = 50000;
DECLARE @EmployeeCount INT;

SELECT @EmployeeCount = COUNT(*)
FROM employees
WHERE salary > @MinSalary;

PRINT 'Employees above threshold: ' + CAST(@EmployeeCount AS VARCHAR);
```

---

#### Control Flow

```sql
IF EXISTS (SELECT 1 FROM employees WHERE dept_id IS NULL)
BEGIN
    PRINT 'Warning: Employees without departments found';
END
ELSE
BEGIN
    PRINT 'All employees have departments';
END

-- WHILE loop
DECLARE @Counter INT = 1;
WHILE @Counter <= 5
BEGIN
    PRINT 'Iteration: ' + CAST(@Counter AS VARCHAR);
    SET @Counter = @Counter + 1;
END
```

---

#### Error Handling

```sql
BEGIN TRY
    -- Attempt operation
    UPDATE employees
    SET salary = salary * 1.10
    WHERE dept_id = 5;
    
    PRINT 'Update successful';
END TRY
BEGIN CATCH
    -- Handle error
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
    PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
```

---

#### Temporary Tables

```sql
-- Local temporary table (visible in current session)
CREATE TABLE #TempEmployees (
    emp_id INT,
    emp_name VARCHAR(100)
);

INSERT INTO #TempEmployees VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM #TempEmployees;

-- Global temporary table (visible to all sessions)
CREATE TABLE ##GlobalTemp (
    id INT,
    data VARCHAR(50)
);
```

---

#### Built-in Functions (T-SQL Specific)

```sql
-- GETDATE() - Current date/time
SELECT GETDATE() AS current_datetime;

-- NEWID() - Generate GUID
SELECT NEWID() AS unique_id;

-- @@ROWCOUNT - Number of rows affected
UPDATE employees SET salary = salary * 1.05 WHERE dept_id = 10;
PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- @@IDENTITY - Last inserted identity value
INSERT INTO customers (name) VALUES ('John Doe');
SELECT @@IDENTITY AS new_customer_id;

-- SCOPE_IDENTITY() - Better than @@IDENTITY
INSERT INTO orders (customer_id) VALUES (123);
SELECT SCOPE_IDENTITY() AS new_order_id;
```

---

## SQL Server Tools

### 1. SQL Server Management Studio (SSMS) ⭐

**Platform:** Windows only  
**Purpose:** Primary GUI tool for SQL Server

**Features:**
- Object Explorer (navigate databases)
- Query editor with IntelliSense
- Graphical execution plans
- Database diagrams
- Backup/restore wizards
- Performance monitoring

**Download:** [SSMS](https://aka.ms/ssms)

---

### 2. Azure Data Studio

**Platform:** Windows, Mac, Linux  
**Purpose:** Modern, cross-platform tool

**Features:**
- VS Code-based interface
- SQL Notebooks
- Extensions marketplace
- Git integration
- Server groups

**Download:** [Azure Data Studio](https://aka.ms/azuredatastudio)

---

### 3. sqlcmd (Command Line)

**Purpose:** Execute queries from command line

```powershell
# Connect and run query
sqlcmd -S localhost -U sa -P "YourPassword" -Q "SELECT @@VERSION"

# Run script file
sqlcmd -S localhost -U sa -P "YourPassword" -i "script.sql"

# Interactive mode
sqlcmd -S localhost -U sa
```

---

### 4. SQL Server Agent

**Purpose:** Job scheduling and automation

**Use Cases:**
- Scheduled backups
- ETL jobs
- Maintenance tasks
- Report generation

---

## SQL Server vs Other Databases

### SQL Server vs MySQL

| Feature | SQL Server | MySQL |
|---------|------------|-------|
| **Owner** | Microsoft | Oracle (Community: Open Source) |
| **Platform** | Windows, Linux | Windows, Linux, Mac |
| **License** | Paid (Free editions available) | Free (Paid versions available) |
| **Language** | T-SQL | MySQL dialect |
| **GUI Tool** | SSMS | MySQL Workbench |
| **Best For** | Enterprise, Windows shops | Web apps, open source projects |
| **Performance** | Excellent | Excellent |
| **Features** | Very comprehensive | Good (improving) |

---

### SQL Server vs PostgreSQL

| Feature | SQL Server | PostgreSQL |
|---------|------------|------------|
| **Owner** | Microsoft | Open Source |
| **License** | Paid | Free |
| **Compliance** | Full ACID | Full ACID |
| **Extensions** | T-SQL | PL/pgSQL |
| **JSON** | Good support | Excellent support |
| **Best For** | Microsoft ecosystem | Open source, advanced features |

---

### SQL Server vs Oracle

| Feature | SQL Server | Oracle |
|---------|------------|--------|
| **Owner** | Microsoft | Oracle |
| **License** | Paid | Very expensive |
| **Platform** | Windows, Linux | Many platforms |
| **Language** | T-SQL | PL/SQL |
| **Market** | Growing | Established leader |
| **Best For** | Modern enterprises | Large corporations, legacy |

---

## Why Choose SQL Server?

### ✅ Pros

1. **Integration with Microsoft Stack**
   - Windows Server
   - .NET applications
   - Azure cloud
   - Power BI
   - Active Directory

2. **Enterprise Features**
   - Excellent performance
   - Advanced security
   - High availability
   - Disaster recovery

3. **Developer-Friendly**
   - SSMS is powerful
   - Good documentation
   - Strong community
   - Azure Data Studio

4. **Cloud-Ready**
   - Azure SQL Database
   - Azure SQL Managed Instance
   - Hybrid scenarios

5. **Business Intelligence**
   - SQL Server Reporting Services (SSRS)
   - SQL Server Integration Services (SSIS)
   - SQL Server Analysis Services (SSAS)

---

### ⚠️ Cons

1. **Cost** (for production)
   - Standard/Enterprise licenses expensive
   - Per-core licensing model

2. **Windows Heritage**
   - Historically Windows-only
   - Linux support newer (since 2017)

3. **Lock-In**
   - T-SQL not portable
   - Migration to other databases requires work

---

## SQL Server in the Real World

### Companies Using SQL Server

- **Microsoft** (obviously!)
- **Stack Overflow**
- **Hulu**
- **Walmart**
- **Many banks and financial institutions**
- **Healthcare systems**
- **Government agencies**

### Use Cases

- ✅ Line-of-business applications
- ✅ E-commerce platforms
- ✅ Financial systems
- ✅ Healthcare records
- ✅ ERP systems (SAP, Dynamics)
- ✅ CRM systems
- ✅ Data warehousing

---

## 🧠 Key Concepts to Remember

1. SQL Server is Microsoft's enterprise RDBMS
2. Developer Edition is **FREE** and has all features (for dev/test)
3. Express Edition is free for small production apps (10 GB limit)
4. T-SQL adds procedural extensions to standard SQL
5. SSMS is the primary Windows GUI tool
6. SQL Server runs on Windows and Linux
7. Great integration with Microsoft ecosystem
8. Strong enterprise features and support

---

## 📝 Check Your Understanding

1. What is the difference between Express and Developer editions?
2. Can you use Developer Edition in production?
3. What does T-SQL stand for?
4. Name three SQL Server tools
5. What are the three types of database files in SQL Server?
6. What is the main GUI tool for SQL Server on Windows?
7. Give three examples of T-SQL extensions over standard SQL

---

## ⏭️ Next Lesson

Continue with: **[10 - SQL Unplugged](../10-sql-unplugged/)** - Practice thinking about database problems without code.

---

## 📚 Additional Resources

- [SQL Server Documentation](https://docs.microsoft.com/sql/)
- [Download SQL Server](https://www.microsoft.com/sql-server/sql-server-downloads)
- [Download SSMS](https://aka.ms/ssms)
- [T-SQL Reference](https://docs.microsoft.com/sql/t-sql/)
- [SQL Server Blog](https://cloudblogs.microsoft.com/sqlserver/)
