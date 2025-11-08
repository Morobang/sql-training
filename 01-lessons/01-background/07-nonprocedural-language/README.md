# Nonprocedural Language

## 🎯 Learning Objectives

- Understand what makes SQL a nonprocedural language
- Learn the difference between declarative and procedural programming
- Discover how SQL queries are executed behind the scenes
- Appreciate the power of set-based operations

---

## What is a Nonprocedural Language?

**SQL is a DECLARATIVE (nonprocedural) language**

> In SQL, you specify **WHAT** you want, not **HOW** to get it.

The database engine figures out the most efficient way to execute your request.

---

## Procedural vs Declarative

### Procedural Programming (HOW)

**You give step-by-step instructions:**

```python
# Python (Procedural)
# Goal: Find all employees with salary > 70000

high_earners = []
for employee in employees:
    if employee.salary > 70000:
        high_earners.append(employee)

# You specify:
# 1. Create empty list
# 2. Loop through each employee
# 3. Check condition
# 4. Add to list if condition met
```

**Characteristics:**
- You control the flow
- Step-by-step instructions
- Loops, conditions, variables
- You decide the algorithm

---

### Declarative Programming (WHAT)

**You describe the desired result:**

```sql
-- SQL (Declarative)
-- Goal: Find all employees with salary > 70000

SELECT * 
FROM employees 
WHERE salary > 70000;

-- You specify:
-- "Give me employees where salary > 70000"
-- Database decides HOW to get them
```

**Characteristics:**
- You describe the outcome
- No explicit loops
- No step-by-step instructions
- Database optimizes execution

---

## Real-World Analogy

### Procedural (Taxi Driver Instructions)

```
"Drive 2 blocks north, 
turn right at the traffic light, 
go 3 more blocks, 
turn left after the gas station,
park in front of the blue building."
```

You specify every step.

---

### Declarative (GPS/Uber)

```
"Take me to 123 Main Street"
```

The system figures out the best route.

---

## How SQL Queries Work Behind the Scenes

When you write a SQL query, here's what happens:

```
┌──────────────────────────────────────────────────┐
│  1. YOU WRITE (What you want)                    │
│     SELECT name, salary FROM employees           │
│     WHERE dept = 'IT' AND salary > 70000         │
└──────────────┬───────────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────────┐
│  2. PARSER (Checks syntax)                       │
│     ✓ Valid SQL?                                 │
│     ✓ Tables exist?                              │
│     ✓ Columns exist?                             │
└──────────────┬───────────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────────┐
│  3. QUERY OPTIMIZER (Figures out HOW)            │
│     Considers:                                   │
│     • Available indexes                          │
│     • Table sizes                                │
│     • Statistics                                 │
│     • Multiple execution plans                   │
│     Chooses BEST plan                            │
└──────────────┬───────────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────────┐
│  4. EXECUTION ENGINE (Does the work)             │
│     • Reads data from disk/memory                │
│     • Applies filters                            │
│     • Sorts if needed                            │
│     • Joins tables                               │
│     Returns results                              │
└──────────────────────────────────────────────────┘
```

**You only write step 1!** The database handles everything else.

---

## Query Optimizer: The Secret Weapon

The **Query Optimizer** is what makes SQL powerful.

### Example Query:

```sql
SELECT e.name, d.department_name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 70000
AND d.location = 'Boston'
ORDER BY e.salary DESC;
```

### Possible Execution Strategies:

**Option 1:**
1. Read all employees
2. Filter salary > 70000
3. Read all departments
4. Filter location = 'Boston'
5. Join the results
6. Sort by salary

**Option 2:**
1. Use index on salary to find employees > 70000
2. Use index on location to find Boston departments
3. Join these smaller sets
4. Sort results

**Option 3:**
1. Start with smaller table (departments)
2. Filter Boston locations
3. Join with employees
4. Filter salary > 70000
5. Sort results

**The optimizer chooses the fastest option!**

---

## Set-Based Operations

SQL operates on **SETS** of data, not individual rows.

### Procedural Thinking (Row-by-Row)

```python
# Update all salaries by 10%
for employee in employees:
    employee.salary = employee.salary * 1.10
    save(employee)
# Process: 1 row, 2 row, 3 row...
```

---

### SQL Thinking (Set-Based)

```sql
-- Update all salaries by 10%
UPDATE employees
SET salary = salary * 1.10;

-- Processes ALL rows in one operation!
```

**Advantages:**
- ✅ Faster (batch processing)
- ✅ Less code
- ✅ Database optimized
- ✅ Atomic operation

---

## Examples: Declarative Power

### Example 1: Finding Patterns

**Task:** Find employees earning more than their department average

**Procedural Approach (Pseudo-code):**
```python
# Calculate average salary per department
dept_averages = {}
for employee in employees:
    dept = employee.dept_id
    if dept not in dept_averages:
        dept_averages[dept] = calculate_average(dept)

# Find employees above average
above_average = []
for employee in employees:
    if employee.salary > dept_averages[employee.dept_id]:
        above_average.append(employee)
```

**Declarative SQL:**
```sql
SELECT e.name, e.salary, e.dept_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary) 
    FROM employees e2 
    WHERE e2.dept_id = e.dept_id
);
```

---

### Example 2: Complex Aggregation

**Task:** Monthly sales summary with running total

**Procedural Approach:**
```python
# Group by month
monthly_sales = {}
for order in orders:
    month = order.date.month
    if month not in monthly_sales:
        monthly_sales[month] = 0
    monthly_sales[month] += order.total

# Calculate running total
running_total = 0
for month in sorted(monthly_sales.keys()):
    running_total += monthly_sales[month]
    print(month, monthly_sales[month], running_total)
```

**Declarative SQL:**
```sql
SELECT 
    MONTH(order_date) AS month,
    SUM(total) AS monthly_sales,
    SUM(SUM(total)) OVER (
        ORDER BY MONTH(order_date)
    ) AS running_total
FROM orders
GROUP BY MONTH(order_date);
```

---

## Benefits of Nonprocedural SQL

### 1. Simplicity

**Complex operations in simple syntax:**

```sql
-- Join 3 tables, aggregate, filter, sort
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total) > 1000
ORDER BY lifetime_value DESC;
```

Try doing this in procedural code!

---

### 2. Performance

**Database knows best:**

- Uses indexes automatically
- Caches frequently accessed data
- Parallelizes operations
- Optimizes I/O
- Adjusts based on data statistics

**Example:**
```sql
-- Same query, different execution plans based on data
SELECT * FROM orders WHERE order_date = '2024-11-07';

-- If 1 row: Quick index seek
-- If 1000 rows: Index scan
-- If 1 million rows: Table scan
-- Optimizer chooses automatically!
```

---

### 3. Maintainability

**SQL is self-documenting:**

```sql
-- What does this do? Read it like English!
SELECT product_name, price
FROM products
WHERE category = 'Electronics'
AND price < 500
ORDER BY price;
```

vs procedural equivalent (20+ lines of code)

---

### 4. Portability

**Same SQL works across databases:**

```sql
-- Works in SQL Server, MySQL, PostgreSQL, Oracle
SELECT COUNT(*) FROM employees WHERE status = 'Active';
```

---

### 5. Optimization Evolution

**Your queries get faster as the database improves:**

- Write query once
- Database vendors improve optimizers
- Your query automatically benefits
- No code changes needed!

---

## When SQL Needs Procedural Logic

SQL isn't always enough. Enter **Procedural Extensions:**

### T-SQL (SQL Server)

```sql
-- Variables and control flow
DECLARE @Counter INT = 0;
DECLARE @MaxSalary DECIMAL(10,2);

SET @MaxSalary = (SELECT MAX(salary) FROM employees);

IF @MaxSalary > 100000
BEGIN
    PRINT 'High salary range';
END
ELSE
BEGIN
    PRINT 'Normal salary range';
END

-- Loops
WHILE @Counter < 10
BEGIN
    SET @Counter = @Counter + 1;
    PRINT 'Iteration: ' + CAST(@Counter AS VARCHAR);
END
```

### Stored Procedures (Hybrid Approach)

```sql
CREATE PROCEDURE ProcessMonthlyBonus
    @MinSalary DECIMAL(10,2),
    @BonusPercent DECIMAL(5,2)
AS
BEGIN
    -- Declarative SQL within procedural wrapper
    DECLARE @EmployeeCount INT;
    
    -- Update salaries (declarative)
    UPDATE employees
    SET salary = salary * (1 + @BonusPercent / 100)
    WHERE salary < @MinSalary;
    
    SET @EmployeeCount = @@ROWCOUNT;
    
    -- Conditional logic (procedural)
    IF @EmployeeCount > 0
        PRINT CAST(@EmployeeCount AS VARCHAR) + ' employees received bonuses';
    ELSE
        PRINT 'No employees qualified for bonus';
END;
```

---

## Thinking in Sets, Not Loops

### ❌ Avoid: Cursor-Based Thinking

```sql
-- Anti-pattern: Procedural thinking in SQL
DECLARE @EmpID INT;
DECLARE emp_cursor CURSOR FOR 
    SELECT employee_id FROM employees;

OPEN emp_cursor;
FETCH NEXT FROM emp_cursor INTO @EmpID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Process one row at a time (SLOW!)
    UPDATE employees 
    SET processed = 1 
    WHERE employee_id = @EmpID;
    
    FETCH NEXT FROM emp_cursor INTO @EmpID;
END;

CLOSE emp_cursor;
DEALLOCATE emp_cursor;
```

---

### ✅ Better: Set-Based Thinking

```sql
-- Set-based approach (FAST!)
UPDATE employees
SET processed = 1;

-- Processes all rows in one operation
-- 100-1000x faster than cursor approach!
```

---

## The Power of Declarative SQL

### Real-World Performance Example

**Task:** Calculate total sales per customer

**Procedural (Python + SQL):**
```python
# Fetch all orders (millions of rows)
orders = db.query("SELECT * FROM orders")

# Process in application (slow)
customer_totals = {}
for order in orders:
    if order.customer_id not in customer_totals:
        customer_totals[order.customer_id] = 0
    customer_totals[order.customer_id] += order.total

# 10 minutes for 10 million rows
```

**Declarative (Pure SQL):**
```sql
-- Let database do the work (fast)
SELECT 
    customer_id,
    SUM(total) AS total_sales
FROM orders
GROUP BY customer_id;

-- 5 seconds for 10 million rows!
```

**Result:** 120x faster! 🚀

---

## 🧠 Key Concepts to Remember

1. SQL is **declarative** - you specify WHAT, not HOW
2. The **query optimizer** determines the best execution plan
3. SQL operates on **sets**, not individual rows
4. Database handles optimization, indexing, caching automatically
5. Set-based operations are much faster than row-by-row
6. SQL is simple to write but powerful in execution
7. Procedural extensions (T-SQL) add logic when needed
8. Think in sets, not loops

---

## 📝 Check Your Understanding

1. What is the difference between declarative and procedural programming?
2. What does the query optimizer do?
3. Why is set-based processing faster than row-by-row?
4. Give an example of a declarative SQL statement
5. When might you need procedural logic in SQL?
6. What are the benefits of SQL being nonprocedural?
7. Why should you avoid cursors when possible?

---

## ⏭️ Next Lesson

Continue with: **[08 - SQL Examples](../08-sql-examples/)** - See practical SQL examples demonstrating these concepts.

---

## 📚 Additional Resources

- [Set-Based vs Procedural T-SQL](https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/sql-server-set-based-operations/)
- [How Query Optimization Works](https://docs.microsoft.com/sql/relational-databases/query-processing-architecture-guide)
- [Thinking in Sets](https://www.sqlservercentral.com/articles/thinking-in-sets)
