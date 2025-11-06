# 🗄️ Database Setup

Now that you have SQL Server installed, let's set up the sample databases you'll use throughout this course.

---

## 🎯 What You Will Learn
- How to create databases in SQL Server
- How to run SQL scripts to populate databases
- Understanding the sample databases used in this course
- How to verify your database setup

---

## 📚 Sample Databases Overview

This course uses several sample databases:

### 1. **Sakila Database** (Main Training Database)
The Sakila database is a standard sample database that models a DVD rental store. It includes:
- **Tables**: film, actor, customer, rental, payment, inventory, etc.
- **Relationships**: Foreign keys demonstrating table relationships
- **Data**: Realistic sample data for practice

### 2. **HR Database** (Employee Management)
A human resources database for practicing HR-related queries:
- Employee records
- Department structure
- Job roles and salaries
- Location and region data

### 3. **AdventureWorks** (Optional - Advanced)
Microsoft's comprehensive sample database for advanced topics:
- Sales and order management
- Product catalog
- Employee and vendor data

---

## ✅ Step 1: Download Sample Database Scripts

You can find the SQL scripts in the course repository:

```
03-assets/
  sql-scripts/
    sakila-mssql-schema.sql
    sakila-mssql-data.sql
    hr-schema.sql
    hr-data.sql
```

Or download from:
- **Sakila for SQL Server**: [GitHub - Sakila SQL Server Port](https://github.com/jOOQ/jOOQ/tree/main/jOOQ-examples/Sakila)
- **AdventureWorks**: [Microsoft Samples](https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/adventure-works)

---

## ✅ Step 2: Create the Sakila Database

### Option A: Using SSMS (SQL Server Management Studio)

1. **Open SSMS** and connect to your local server
2. **Open a New Query** (Ctrl + N)
3. **Create the database:**

```sql
CREATE DATABASE Sakila;
GO

USE Sakila;
GO
```

4. **Run the schema script:**
   - File → Open → File → Select `sakila-mssql-schema.sql`
   - Click **Execute** (F5)

5. **Run the data script:**
   - File → Open → File → Select `sakila-mssql-data.sql`
   - Click **Execute** (F5)

### Option B: Using Azure Data Studio

1. **Open Azure Data Studio** and connect to localhost
2. **Right-click** on your server → New Query
3. **Follow the same SQL commands** as above
4. **Execute** each script using the Run button or Ctrl + Shift + E

### Option C: Using Command Line (sqlcmd)

```powershell
# Create database
sqlcmd -S localhost -U sa -P "YourPassword" -Q "CREATE DATABASE Sakila"

# Run schema script
sqlcmd -S localhost -U sa -P "YourPassword" -d Sakila -i "C:\path\to\sakila-mssql-schema.sql"

# Run data script
sqlcmd -S localhost -U sa -P "YourPassword" -d Sakila -i "C:\path\to\sakila-mssql-data.sql"
```

---

## ✅ Step 3: Create the HR Database

```sql
CREATE DATABASE HR;
GO

USE HR;
GO

-- Create tables
CREATE TABLE departments (
    department_id INT PRIMARY KEY IDENTITY(1,1),
    department_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    hire_date DATE,
    job_title VARCHAR(50),
    salary DECIMAL(10, 2),
    department_id INT,
    manager_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Insert sample data
INSERT INTO departments (department_name, location) VALUES
('Sales', 'New York'),
('IT', 'San Francisco'),
('HR', 'Chicago'),
('Finance', 'Boston'),
('Marketing', 'Los Angeles');

INSERT INTO employees (first_name, last_name, email, hire_date, job_title, salary, department_id, manager_id) VALUES
('John', 'Smith', 'john.smith@company.com', '2020-01-15', 'CEO', 150000.00, 3, NULL),
('Sarah', 'Johnson', 'sarah.j@company.com', '2020-03-22', 'Sales Manager', 95000.00, 1, 1),
('Mike', 'Williams', 'mike.w@company.com', '2021-05-10', 'Developer', 85000.00, 2, 1),
('Emily', 'Brown', 'emily.b@company.com', '2021-07-01', 'HR Specialist', 65000.00, 3, 1),
('David', 'Lee', 'david.l@company.com', '2022-02-14', 'Financial Analyst', 75000.00, 4, 1);

GO
```

---

## ✅ Step 4: Verify Your Setup

Run these queries to confirm everything is working:

### Check Databases
```sql
SELECT name FROM sys.databases 
WHERE name IN ('Sakila', 'HR');
```

### Check Sakila Tables
```sql
USE Sakila;
GO

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
```

### Test a Sample Query
```sql
-- Should return film titles
SELECT TOP 10 title, release_year, rating
FROM film
ORDER BY title;

-- Should return actor names
SELECT TOP 10 first_name, last_name
FROM actor
ORDER BY last_name;
```

### Check HR Database
```sql
USE HR;
GO

-- Should return employees with departments
SELECT 
    e.first_name,
    e.last_name,
    e.job_title,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id;
```

---

## 📊 Understanding Database Schemas

### Sakila Schema Overview

**Key Tables:**
- `actor` - Information about actors
- `film` - Movie details
- `customer` - Customer information
- `rental` - Rental transactions
- `payment` - Payment records
- `inventory` - Inventory tracking

**Relationships:**
- Films have many actors (many-to-many via `film_actor`)
- Customers make many rentals (one-to-many)
- Rentals have payments (one-to-one or one-to-many)

### View the Schema Diagram

In SSMS:
1. Expand your database
2. Right-click on **Database Diagrams**
3. Create new diagram
4. Add all tables to visualize relationships

---

## 🔧 Troubleshooting

### Script Execution Errors?
- Ensure you're connected to the correct database (check `USE` statements)
- Check for syntax errors specific to SQL Server vs MySQL
- Verify file paths are correct

### Table Already Exists?
```sql
-- Drop and recreate if needed
DROP DATABASE IF EXISTS Sakila;
CREATE DATABASE Sakila;
```

### Permission Issues?
- Ensure you're logged in as `sa` or have appropriate permissions
- Check database ownership and roles

### Large Script Timing Out?
- Increase timeout in your client settings
- Run scripts in smaller batches
- Use `GO` statements to batch commands

---

## 🎯 Best Practices

1. **Keep Scripts Organized**: Save all your database scripts for easy recreation
2. **Use Version Control**: Track changes to your schema over time
3. **Document Changes**: Comment your custom modifications
4. **Regular Backups**: Practice backing up and restoring databases
5. **Separate Environments**: Consider having dev/test/practice databases

---

## 📦 Backup Your Databases

To create a backup in SSMS:
```sql
BACKUP DATABASE Sakila
TO DISK = 'C:\Backups\Sakila.bak'
WITH FORMAT, INIT, NAME = 'Full Backup of Sakila';
```

To restore:
```sql
RESTORE DATABASE Sakila
FROM DISK = 'C:\Backups\Sakila.bak'
WITH REPLACE;
```

---

## ⏭️ Next Steps

Now that your databases are set up:
- Explore the database structure
- Try writing simple SELECT queries
- Move on to [Tools Overview](./03-tools-overview.md)
- Begin [Lesson 01: Background](../01-lessons/01-background/)

---

**Database Setup Complete!** 🎉 You're ready to start querying!
