# Lesson 2: Setup Your Environment

**Level:** 🟢 Beginner

## Learning Objectives

By the end of this lesson, you will be able to:
1. Install SQL Server on your operating system
2. Install and configure a SQL client tool
3. Create sample databases for practice
4. Verify your setup is working correctly
5. Understand basic database connection concepts

## What You'll Need

### System Requirements
```
💻 Computer: Windows, Mac, or Linux
💾 RAM: Minimum 4GB (8GB recommended)
📁 Disk Space: 10GB for SQL Server and databases
⏱️ Time: 30-45 minutes for complete setup
```

---

## Part 1: Install SQL Server

### Option A: Windows

**Step 1: Download SQL Server**
1. Go to: https://www.microsoft.com/sql-server/sql-server-downloads
2. Choose **Developer Edition** (free, full-featured)
3. Download the installer

**Step 2: Run Installation**
```
1. Double-click installer
2. Choose "Basic" installation
3. Accept license terms
4. Select installation location
5. Click "Install"
6. Wait 10-15 minutes
```

**Step 3: Note Connection Details**
```
Server Name: localhost (or .)
Authentication: Windows Authentication (default)
```

### Option B: Mac (Using Docker)

**Step 1: Install Docker Desktop**
```
1. Download from: https://www.docker.com/products/docker-desktop
2. Install and start Docker Desktop
3. Verify: Open terminal, run: docker --version
```

**Step 2: Run SQL Server Container**
```bash
# Pull and run SQL Server 2022
docker run -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=YourStrong!Pass123' \
  -p 1433:1433 \
  --name sql-server \
  -d mcr.microsoft.com/mssql/server:2022-latest

# Verify it's running
docker ps
```

**Connection Details:**
```
Server: localhost,1433
User: sa
Password: YourStrong!Pass123 (use your password)
```

### Option C: Linux (Ubuntu/Debian)

```bash
# Import Microsoft GPG key
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add SQL Server repository
sudo add-apt-repository "$(curl https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2022.list)"

# Install SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server

# Configure SQL Server
sudo /opt/mssql/bin/mssql-conf setup

# Choose: Developer Edition
# Set SA password: YourStrong!Pass123
```

---

## Part 2: Install SQL Client Tools

You need a **client tool** to write and execute SQL queries.

### Option A: SQL Server Management Studio (SSMS) - Windows Only

**Best for:** Windows users, comprehensive features

**Installation:**
```
1. Download: https://aka.ms/ssmsfullsetup
2. Run installer (20-minute install)
3. Launch SSMS
4. Connect to localhost
```

**Features:**
```
✓ Query editor with IntelliSense
✓ Visual database designer
✓ Object explorer (browse tables)
✓ Execution plans
✓ Database diagrams
```

### Option B: Azure Data Studio - Cross-Platform

**Best for:** Mac, Linux, or modern UI preference

**Installation:**
```
1. Download: https://aka.ms/azuredatastudio
2. Install (5-minute install)
3. Launch Azure Data Studio
4. Create connection to localhost
```

**Features:**
```
✓ Modern, VS Code-like interface
✓ Notebooks (like Jupyter)
✓ Git integration
✓ Extensions marketplace
✓ Works on Mac/Linux/Windows
```

### Option C: VS Code with SQL Extension

**Best for:** Developers already using VS Code

**Installation:**
```
1. Install VS Code: https://code.visualstudio.com
2. Install extension: "mssql" by Microsoft
3. Ctrl+Shift+P → "MS SQL: Connect"
```

---

## Part 3: Connect to SQL Server

### Using SSMS

```
1. Launch SSMS
2. Server name: localhost (or . or .\SQLEXPRESS)
3. Authentication: Windows Authentication
4. Click "Connect"
```

**If using SQL Authentication:**
```
Server: localhost
Login: sa
Password: [your password]
```

### Using Azure Data Studio

```
1. Launch Azure Data Studio
2. Click "New Connection"
3. Server: localhost
4. Authentication type: SQL Login
5. Username: sa
6. Password: [your password]
7. Click "Connect"
```

### Test Your Connection

Run this query to verify:

```sql
-- Check SQL Server version
SELECT @@VERSION;

-- Should return:
-- Microsoft SQL Server 2022 (RTM) ...

-- List databases
SELECT name FROM sys.databases;

-- Should show:
-- master
-- tempdb
-- model
-- msdb
```

✅ **If you see results, you're connected!**

---

## Part 4: Create Sample Databases

### Quick Setup (5 Minutes)

We'll create a simple practice database:

```sql
-- Create database
CREATE DATABASE SQLTraining;
GO

-- Switch to new database
USE SQLTraining;
GO

-- Create sample table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100),
    SignupDate DATE DEFAULT GETDATE()
);
GO

-- Insert sample data
INSERT INTO Customers (FirstName, LastName, Email) VALUES
('John', 'Doe', 'john.doe@email.com'),
('Jane', 'Smith', 'jane.smith@email.com'),
('Bob', 'Johnson', 'bob.johnson@email.com'),
('Alice', 'Williams', 'alice.w@email.com'),
('Charlie', 'Brown', 'charlie.b@email.com');
GO

-- Verify data
SELECT * FROM Customers;
```

**Expected Output:**
```
CustomerID | FirstName | LastName | Email                | SignupDate
-----------|-----------|----------|----------------------|------------
1          | John      | Doe      | john.doe@email.com   | 2024-11-09
2          | Jane      | Smith    | jane.smith@email.com | 2024-11-09
3          | Bob       | Johnson  | bob.johnson@email.com| 2024-11-09
4          | Alice     | Williams | alice.w@email.com    | 2024-11-09
5          | Charlie   | Brown    | charlie.b@email.com  | 2024-11-09
```

✅ **If you see this table, your setup is working!**

---

## Part 5: Understanding Your Environment

### Database Server (SQL Server)
```
┌─────────────────────────────┐
│      SQL Server Engine      │
│  - Stores data              │
│  - Executes queries         │
│  - Manages security         │
│  - Runs on port 1433        │
└─────────────────────────────┘
```

### Client Tool (SSMS/Azure Data Studio)
```
┌─────────────────────────────┐
│      Client Tool            │
│  - Write SQL queries        │
│  - View results             │
│  - Manage databases         │
│  - Connect to server        │
└─────────────────────────────┘
```

### Connection Flow
```
You write SQL in client tool
        ↓
Client sends query to SQL Server (localhost:1433)
        ↓
SQL Server executes query
        ↓
Results sent back to client
        ↓
You see results in client tool
```

---

## Part 6: Troubleshooting Common Issues

### Issue 1: Can't Connect to Server

**Symptoms:**
```
Error: "Cannot connect to localhost"
Error: "Login failed for user"
```

**Solutions:**
```
✓ Verify SQL Server is running (Windows Services)
✓ Check server name (localhost, ., .\SQLEXPRESS)
✓ Verify credentials (sa password)
✓ Check firewall (allow port 1433)
✓ Try IP: 127.0.0.1
```

### Issue 2: SA Password Rejected

**Docker Users:**
```bash
# Reset SA password
docker exec -it sql-server /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U SA -P 'OldPassword' \
  -Q "ALTER LOGIN SA WITH PASSWORD='NewPassword'"
```

### Issue 3: Database Not Found

```sql
-- List all databases
SELECT name FROM sys.databases;

-- Make sure you're in correct database
SELECT DB_NAME() AS CurrentDatabase;

-- Switch database
USE SQLTraining;
```

---

## Part 7: Best Practices

### Security
```
✓ Use strong SA password (12+ characters)
✓ Create separate user accounts (not SA)
✓ Grant minimum necessary permissions
✗ Don't use SA for regular work
✗ Don't share passwords
```

### Organization
```
✓ Create separate databases for different projects
✓ Use meaningful database names
✓ Back up databases regularly
✓ Document your database schemas
```

### Performance
```
✓ Close unused query windows
✓ Limit result sets (use TOP or LIMIT)
✓ Index important columns (learn later)
```

---

## Part 8: Backup Your Database

**Create Backup:**
```sql
BACKUP DATABASE SQLTraining
TO DISK = 'C:\Backups\SQLTraining.bak'
WITH FORMAT, INIT, NAME = 'SQLTraining Full Backup';
```

**Restore Backup:**
```sql
RESTORE DATABASE SQLTraining
FROM DISK = 'C:\Backups\SQLTraining.bak'
WITH REPLACE;
```

**Note:** Change path for Mac/Linux:
```sql
-- Mac/Linux (Docker)
BACKUP DATABASE SQLTraining
TO DISK = '/var/opt/mssql/backups/SQLTraining.bak'
WITH FORMAT, INIT;
```

---

## Quick Reference

### Connection Strings

**Windows (Windows Authentication):**
```
Server: localhost
Database: SQLTraining
Authentication: Windows Authentication
```

**SQL Authentication:**
```
Server: localhost,1433
User: sa
Password: YourPassword
Database: SQLTraining
```

**Docker:**
```
Server: localhost,1433
User: sa
Password: YourStrong!Pass123
```

### Common Commands

```sql
-- See current database
SELECT DB_NAME();

-- See all databases
SELECT name FROM sys.databases;

-- Switch database
USE SQLTraining;

-- See all tables
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Check SQL version
SELECT @@VERSION;
```

---

## Key Takeaways

### Setup Checklist
```
✅ SQL Server installed
✅ Client tool installed (SSMS/Azure Data Studio)
✅ Successfully connected to server
✅ Created SQLTraining database
✅ Created Customers table with data
✅ Ran test queries successfully
```

### What You Learned
```
✓ How to install SQL Server on your OS
✓ How to install and use client tools
✓ How to connect to SQL Server
✓ How to create databases and tables
✓ How to verify your setup
```

### You're Ready When...
```
✓ You can connect to SQL Server
✓ You can create a database
✓ You can run SELECT queries
✓ You can see query results
```

---

## Next Lesson

**Continue to [Lesson 3: Query Data (SELECT)](../03-query-data/query-data.md)**  
Learn to write SELECT queries to retrieve data from databases.

---

## Additional Resources

- **SQL Server Documentation:** https://docs.microsoft.com/sql
- **SSMS Documentation:** https://docs.microsoft.com/sql/ssms
- **Azure Data Studio:** https://docs.microsoft.com/sql/azure-data-studio
- **Docker SQL Server:** https://hub.docker.com/_/microsoft-mssql-server

**Environment Setup Complete! Ready to write SQL queries! 🚀**
