# The Relational Model

## 🎯 Learning Objectives

- Understand Dr. E.F. Codd's relational model
- Learn the components of relational databases
- Master the concept of keys (primary, foreign, candidate)
- Understand relationships between tables
- Learn basic normalization principles

---

## The Birth of Relational Databases

In 1970, **Dr. Edgar F. Codd**, a computer scientist at IBM, published a groundbreaking paper: *"A Relational Model of Data for Large Shared Data Banks"*

### The Problem He Solved

Before Codd's model, databases were:
- Hierarchical (tree-like structures)
- Network-based (complex pointer systems)
- Difficult to query and modify
- Required programmers to navigate physical storage

### The Revolutionary Idea

**"Organize data in tables (relations) with mathematical rigor, and use a simple, declarative language to query it."**

This simple idea transformed computing forever.

---

## Core Concepts of the Relational Model

### 1. Relations (Tables)

A **relation** is a mathematical term for what we call a **table**.

**Key Properties:**
- Each relation has a unique name
- Contains rows (tuples) and columns (attributes)
- Each column has a specific data type
- No duplicate rows (each row is unique)
- Order of rows doesn't matter
- Order of columns doesn't matter (technically)

**Example Table: `employees`**
```
┌─────────────┬────────────┬───────────┬────────────────────┬──────────┐
│ employee_id │ first_name │ last_name │ email              │ salary   │
├─────────────┼────────────┼───────────┼────────────────────┼──────────┤
│ 1           │ Alice      │ Smith     │ alice@company.com  │ 75000.00 │
│ 2           │ Bob        │ Johnson   │ bob@company.com    │ 68000.00 │
│ 3           │ Carol      │ Williams  │ carol@company.com  │ 82000.00 │
└─────────────┴────────────┴───────────┴────────────────────┴──────────┘
```

---

### 2. Tuples (Rows)

A **tuple** is a mathematical term for what we call a **row** or **record**.

**Properties:**
- Represents a single entity (one employee, one order, one product)
- Contains values for each column
- Must be unique (no exact duplicate rows)

**Example Tuple:**
```
employee_id: 1
first_name: Alice
last_name: Smith
email: alice@company.com
salary: 75000.00
```

---

### 3. Attributes (Columns)

An **attribute** is what we call a **column** or **field**.

**Properties:**
- Has a name (e.g., `first_name`)
- Has a data type (e.g., VARCHAR, INTEGER, DATE)
- Contains a specific piece of information
- All values in a column are of the same type

**Example Attributes:**
- `employee_id` (INTEGER)
- `first_name` (VARCHAR)
- `hire_date` (DATE)
- `salary` (DECIMAL)

---

### 4. Domain

A **domain** is the set of allowed values for an attribute.

**Examples:**

```sql
-- Domain: Boolean
is_active: {TRUE, FALSE}

-- Domain: Enumerated values
status: {'Pending', 'Approved', 'Rejected', 'Cancelled'}

-- Domain: Numeric range
age: {0, 1, 2, ..., 120}

-- Domain: Email format
email: Valid email address format

-- Domain: Date range
birth_date: Valid date between 1900-01-01 and today
```

**Domain Constraints** ensure data quality by rejecting invalid values.

---

## Keys in Relational Databases

Keys are fundamental to the relational model. They uniquely identify rows and establish relationships.

### Primary Key

A **primary key** uniquely identifies each row in a table.

**Requirements:**
- ✅ Must be unique for each row
- ✅ Cannot contain NULL values
- ✅ Should never change
- ✅ Should be minimal (fewest columns possible)

**Examples:**

```sql
-- Single-column primary key
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

-- Composite primary key (multiple columns)
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);
```

**Good Primary Keys:**
- ✅ `employee_id` (auto-incrementing number)
- ✅ `social_security_number` (unique identifier)
- ✅ `email` (if guaranteed unique)

**Bad Primary Keys:**
- ❌ `name` (not unique, can change)
- ❌ `address` (can change)
- ❌ `phone_number` (can change)

---

### Foreign Key

A **foreign key** links two tables together by referencing a primary key in another table.

**Purpose:**
- Maintains **referential integrity**
- Enforces relationships between tables
- Prevents orphaned records

**Example:**

```sql
-- Parent table
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50)
);

-- Child table with foreign key
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
```

**Visual Representation:**

```
┌──────────────────────────┐
│      departments         │
│ ┌──────────────────────┐ │
│ │ department_id (PK)   │ │◄────┐
│ │ department_name      │ │     │
│ └──────────────────────┘ │     │
└──────────────────────────┘     │
                                 │ References
                                 │
┌──────────────────────────┐     │
│       employees          │     │
│ ┌──────────────────────┐ │     │
│ │ employee_id (PK)     │ │     │
│ │ first_name           │ │     │
│ │ last_name            │ │     │
│ │ department_id (FK)   │─┼─────┘
│ └──────────────────────┘ │
└──────────────────────────┘
```

**Referential Integrity** ensures:
- Can't insert an employee with invalid `department_id`
- Can't delete a department that has employees (or set to NULL/CASCADE)

---

### Candidate Key

A **candidate key** is any column (or set of columns) that could serve as a primary key.

**Example Table: `students`**

```
┌────────────┬──────────────────┬──────────────────────┬───────────┐
│ student_id │ email            │ national_id          │ name      │
├────────────┼──────────────────┼──────────────────────┼───────────┤
│ 1001       │ alice@school.edu │ 123-45-6789          │ Alice Lee │
│ 1002       │ bob@school.edu   │ 987-65-4321          │ Bob Chen  │
└────────────┴──────────────────┴──────────────────────┴───────────┘
```

**Candidate Keys:**
- `student_id` ✅
- `email` ✅
- `national_id` ✅
- `name` ❌ (not unique)

We choose **one** candidate key as the **primary key** (usually `student_id`). The others become **alternate keys** or **unique constraints**.

---

### Natural vs Surrogate Keys

**Natural Key:**
- Has business meaning
- Examples: SSN, email, ISBN, VIN
- **Pros:** Meaningful, no extra column
- **Cons:** Can change, may be sensitive, composite

**Surrogate Key:**
- Artificial key (usually auto-incrementing integer)
- Examples: `customer_id`, `order_id`, `product_id`
- **Pros:** Never changes, simple, fast
- **Cons:** No business meaning

**Best Practice:** Use surrogate keys as primary keys, make natural keys unique constraints.

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),  -- Surrogate key
    email VARCHAR(100) UNIQUE NOT NULL,          -- Natural key as unique
    name VARCHAR(100)
);
```

---

## Relationships Between Tables

Relational databases model real-world relationships using foreign keys.

### One-to-Many (1:N) - Most Common

One record in Table A relates to many records in Table B.

**Example: Departments and Employees**
- One department has many employees
- One employee belongs to one department

```
┌─────────────────┐         ┌──────────────────┐
│  departments    │ 1     N │   employees      │
│ ┌─────────────┐ │◄────────┤ ┌──────────────┐ │
│ │ dept_id (PK)│ │         │ │ emp_id (PK)  │ │
│ │ dept_name   │ │         │ │ first_name   │ │
│ └─────────────┘ │         │ │ last_name    │ │
└─────────────────┘         │ │ dept_id (FK) │ │
                            │ └──────────────┘ │
                            └──────────────────┘
```

---

### Many-to-Many (N:M)

Many records in Table A relate to many records in Table B.

**Example: Students and Courses**
- One student takes many courses
- One course has many students

**Implementation:** Requires a junction/bridge table

```
┌────────────┐          ┌──────────────────┐          ┌────────────┐
│  students  │          │   enrollments    │          │  courses   │
│ ┌────────┐ │ N     1  │ ┌──────────────┐ │ 1     N  │ ┌────────┐ │
│ │stu_id  │◄├──────────┤ │ stu_id (FK)  │ ├──────────┤►│crs_id  │ │
│ │ name   │ │          │ │ crs_id (FK)  │ │          │ │ title  │ │
│ └────────┘ │          │ │ grade        │ │          │ └────────┘ │
└────────────┘          │ │ enroll_date  │ │          └────────────┘
                        │ └──────────────┘ │
                        └──────────────────┘
                        Junction Table
```

```sql
-- Students table
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- Courses table
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    title VARCHAR(100)
);

-- Junction table
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    grade CHAR(2),
    enroll_date DATE,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

---

### One-to-One (1:1) - Less Common

One record in Table A relates to exactly one record in Table B.

**Example: Employees and Parking Spots**
- One employee has one parking spot
- One parking spot assigned to one employee

**Uses:**
- Splitting sensitive data (passwords, SSN)
- Optional information (not all employees have parking)
- Large text/binary data (profiles, photos)

```
┌──────────────┐  1     1  ┌───────────────┐
│  employees   │◄──────────┤ parking_spots │
│ ┌──────────┐ │           │ ┌───────────┐ │
│ │ emp_id   │ │           │ │ spot_id   │ │
│ │ name     │ │           │ │ emp_id(FK)│ │
│ └──────────┘ │           │ │ location  │ │
└──────────────┘           │ └───────────┘ │
                           └───────────────┘
```

---

## Data Integrity

The relational model enforces data integrity through constraints.

### Types of Integrity:

**1. Entity Integrity**
- Primary key cannot be NULL
- Primary key must be unique
- Ensures each row can be identified

**2. Referential Integrity**
- Foreign keys must reference existing primary keys
- Prevents orphaned records
- Maintains valid relationships

**3. Domain Integrity**
- Values must match column data type
- Values must fall within domain constraints
- Enforced through CHECK constraints

**Example:**

```sql
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,                    -- Entity integrity
    first_name VARCHAR(50) NOT NULL,                -- Domain integrity
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,                      -- Alternate key
    age INT CHECK (age >= 18 AND age <= 100),       -- Domain integrity
    salary DECIMAL(10,2) CHECK (salary > 0),        -- Domain integrity
    department_id INT,
    FOREIGN KEY (department_id)                     -- Referential integrity
        REFERENCES departments(department_id)
);
```

---

## Introduction to Normalization

**Normalization** is the process of organizing data to reduce redundancy and improve data integrity.

### Why Normalize?

**Problems with Unnormalized Data:**

```
┌────────┬──────────┬────────┬────────────┬─────────┬────────────┐
│ emp_id │ emp_name │ skills │ dept_name  │ dept_loc│ manager    │
├────────┼──────────┼────────┼────────────┼─────────┼────────────┤
│ 1      │ Alice    │ SQL,   │ IT         │ Boston  │ John Smith │
│        │          │ Python │            │         │            │
│ 2      │ Bob      │ Java   │ IT         │ Boston  │ John Smith │ ← Redundant!
│ 3      │ Carol    │ SQL    │ Sales      │ NYC     │ Jane Doe   │
└────────┴──────────┴────────┴────────────┴─────────┴────────────┘
```

**Issues:**
- Duplicate department info (IT, Boston, John Smith)
- Update anomaly: Change John's name in multiple places
- Insert anomaly: Can't add department without employee
- Delete anomaly: Delete all IT employees, lose department info

---

### Normal Forms (Brief Overview)

**1st Normal Form (1NF):**
- Eliminate repeating groups
- Each column contains atomic values

**2nd Normal Form (2NF):**
- Must be in 1NF
- Remove partial dependencies

**3rd Normal Form (3NF):**
- Must be in 2NF
- Remove transitive dependencies

**After Normalization:**

```
-- employees table
┌────────┬──────────┬──────────────┐
│ emp_id │ emp_name │ dept_id (FK) │
├────────┼──────────┼──────────────┤
│ 1      │ Alice    │ 10           │
│ 2      │ Bob      │ 10           │
│ 3      │ Carol    │ 20           │
└────────┴──────────┴──────────────┘

-- departments table
┌─────────┬───────────┬──────────┬─────────────┐
│ dept_id │ dept_name │ location │ manager     │
├─────────┼───────────┼──────────┼─────────────┤
│ 10      │ IT        │ Boston   │ John Smith  │ ← Once!
│ 20      │ Sales     │ NYC      │ Jane Doe    │
└─────────┴───────────┴──────────┴─────────────┘
```

**Benefits:**
- No redundancy
- Easy to update
- Data integrity maintained

*(We'll cover normalization in detail in later chapters)*

---

## 🧠 Key Concepts to Remember

1. The relational model organizes data in tables (relations)
2. Primary keys uniquely identify rows
3. Foreign keys create relationships between tables
4. Three main relationship types: one-to-many, many-to-many, one-to-one
5. Constraints enforce data integrity
6. Normalization reduces redundancy and improves data quality

---

## 📝 Check Your Understanding

1. What is a relation in database terms?
2. What are the requirements for a primary key?
3. What is the purpose of a foreign key?
4. Explain the difference between a natural key and a surrogate key
5. What is a junction table and when do you need one?
6. What are the three types of integrity in the relational model?
7. Why do we normalize databases?

---

## ⏭️ Next Lesson

Continue with: **[04 - SQL Terminology](../04-sql-terminology/)** - Master the essential vocabulary used in SQL and databases.

---

## 📚 Additional Resources

- [E.F. Codd's Original Paper (1970)](https://www.seas.upenn.edu/~zives/03f/cis550/codd.pdf)
- [Database Normalization Explained](https://www.essentialsql.com/get-ready-to-learn-sql-database-normalization-explained-in-simple-english/)
- [Primary vs Foreign Keys](https://docs.microsoft.com/sql/relational-databases/tables/primary-and-foreign-key-constraints)
