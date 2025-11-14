# SQL Training Assets

This folder contains supplementary learning resources including cheatsheets, database diagrams, and utility scripts to support your SQL training journey.

---

## 📁 Folder Structure

```
03-assets/
├── cheatsheets/           # Quick reference guides
│   ├── 01-sql-fundamentals.md
│   └── README.md
├── er-diagrams/           # Database schema diagrams
│   ├── techstore-database.md
│   └── README.md
├── sql-scripts/           # Setup and utility scripts
│   ├── sakila-schema-setup.sql
│   ├── generate-sample-data.sql
│   └── README.md
└── README.md             # This file
```

---

## 📚 Cheatsheets

Quick reference guides for common SQL operations and syntax.

### Available Cheatsheets

**01-sql-fundamentals.md** - Comprehensive SQL reference covering:
- **Data Types**: String, numeric, date/time types with size limits
- **SELECT Queries**: Basic queries, column aliases, DISTINCT, TOP
- **WHERE Conditions**: Comparison, logical operators, pattern matching
- **JOIN Operations**: INNER, LEFT, RIGHT, FULL OUTER, CROSS, SELF joins
- **Aggregate Functions**: COUNT, SUM, AVG, MIN, MAX, STRING_AGG
- **GROUP BY & HAVING**: Grouping data and filtering aggregated results
- **Subqueries**: Scalar, IN, EXISTS, correlated subqueries
- **CTEs**: Basic and recursive Common Table Expressions
- **Window Functions**: ROW_NUMBER, RANK, LAG/LEAD, running totals
- **Data Manipulation**: INSERT, UPDATE, DELETE, MERGE operations
- **Data Definition**: CREATE, ALTER, DROP, constraints, indexes
- **Transactions**: BEGIN/COMMIT/ROLLBACK, isolation levels, error handling
- **Common Patterns**: Pagination, date formatting, string manipulation, NULL handling

**Perfect for**:
- Quick syntax lookup during exercises
- Interview preparation
- Refreshing memory on specific SQL features
- Side-by-side reference while coding

---

## 🗺️ ER Diagrams

Entity-Relationship diagrams documenting database schemas used in training projects.

### Available Diagrams

**techstore-database.md** - TechStore E-commerce Platform
- **Schema**: Customers, Products, Orders, OrderDetails (extended)
- **Relationships**: 
  - Customers ↔ Orders (1:Many)
  - Products ↔ Orders (1:Many)
  - Orders ↔ OrderDetails (1:Many)
- **Tables**: 4 core entities with full column specifications
- **Indexes**: Performance optimization indexes documented
- **Sample Queries**: Customer lifetime value, product ranking, orphan detection
- **Used in Projects**:
  - Project 1: Medallion Architecture
  - Project 2: Data Vault 2.0
  - Project 3: Kimball Star Schema
  - Project 4: CDC Pipeline
  - Project 5: Data Quality Monitoring

**Cardinality & Volume**:
- Customers: 10K - 1M rows
- Products: 500 - 50K rows
- Orders: 100K - 10M rows

---

## 🛠️ SQL Scripts

Utility scripts for database setup, sample data generation, and common tasks.

### Available Scripts

#### 1. sakila-schema-setup.sql
**Purpose**: Create the Sakila sample database (DVD rental store schema)

**What it creates**:
- **16 tables**: actor, film, customer, rental, payment, inventory, etc.
- **Relationships**: Many-to-many (film_actor, film_category), hierarchies (address → city → country)
- **Sample data**: 5 films, 5 actors, 3 languages, 6 categories
- **Indexes**: Performance indexes on commonly joined columns

**Use cases**:
- Learning normalized database design
- Practicing complex multi-table JOINs
- Understanding hierarchical data (country → city → address)
- Exploring many-to-many relationships

**Execution**:
```sql
-- Run in SSMS or Azure Data Studio
USE master;
:r sakila-schema-setup.sql
-- OR open file and execute (F5)
```

**Sample queries**:
```sql
-- Find all films by an actor
SELECT f.title, f.release_year
FROM film f
INNER JOIN film_actor fa ON f.film_id = fa.film_id
INNER JOIN actor a ON fa.actor_id = a.actor_id
WHERE a.first_name = 'Tom' AND a.last_name = 'Hanks';

-- Top 10 customers by total payments
SELECT TOP 10
    c.first_name + ' ' + c.last_name AS customer_name,
    SUM(p.amount) AS total_paid
FROM customer c
INNER JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_paid DESC;
```

---

#### 2. generate-sample-data.sql
**Purpose**: Generate realistic TechStore database with 1000+ records

**What it creates**:
- **100 Customers**: Across 28 major US cities, with VIP/Premium/Standard tiers
- **50 Products**: Electronics, Accessories, Home & Garden, Sports, Office categories
- **1000+ Orders**: Distributed over 90-day period with realistic patterns
- **Intentional Quality Issues**: 12 data quality problems for testing validation rules

**Data quality issues included** (for testing):
```sql
-- Completeness
- 1 customer with NULL FirstName
- 2 customers with NULL Email

-- Accuracy
- 1 product with negative price (-$49.99)
- 1 product with negative stock (-10)
- 1 order with negative amount (-$100)
- 1 order with suspicious high amount ($999,999.99)

-- Timeliness
- 2 products with stale restock dates (180 days old)
- 1 order loaded 25 hours after order date

-- Consistency
- 2 orphan orders (invalid CustomerID and ProductID references)
```

**Execution**:
```sql
-- Run in SSMS or Azure Data Studio
USE master;
:r generate-sample-data.sql
-- Takes ~10-15 seconds
```

**Verification**:
```sql
-- Check row counts
SELECT 'Customers' AS tbl, COUNT(*) AS rows FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders;

-- Expected: Customers=101, Products=50, Orders=1002
```

**Use cases**:
- Populating database for project work
- Testing data quality monitoring rules
- Performance testing with realistic volumes
- Demonstrating ETL transformations
- Practicing aggregations and analytics

---

## 🎯 How to Use These Assets

### During Lessons
1. **Reference cheatsheets** when you forget syntax
2. **Review ER diagrams** to understand table relationships before writing queries
3. **Run setup scripts** to create databases for hands-on practice

### During Exercises
1. Use **01-sql-fundamentals.md** for quick syntax lookup
2. Generate **sample data** to test your queries
3. Verify table structure in **ER diagrams** before joining tables

### During Projects
1. **Sakila database**: Practice normalized design patterns
2. **TechStore database**: Build data warehouse projects (Projects 1-5)
3. **Sample data generator**: Populate databases for testing

---

## 💡 Pro Tips

### Cheatsheet Usage
- **Bookmark** 01-sql-fundamentals.md for quick access
- Use **Ctrl+F** to search for specific SQL keywords
- Keep it **open in a second monitor** while coding

### ER Diagram Best Practices
- **Always review relationships** before writing JOINs
- Check **cardinality** (1:1, 1:Many, Many:Many) to avoid Cartesian products
- Verify **foreign key constraints** match your JOIN conditions

### Script Execution
- **Test on dev/local** environments first
- Review scripts **before execution** to understand what they create
- Use **transactions** when modifying production-like data:
  ```sql
  BEGIN TRANSACTION;
      -- Your changes
  ROLLBACK;  -- Or COMMIT when ready
  ```

---

## 📖 Learning Path Recommendations

### Beginner Path
1. Start with **01-sql-fundamentals.md** - Read "Data Types" and "SELECT Queries" sections
2. Run **sakila-schema-setup.sql** to create practice database
3. Practice queries from Sakila "Sample Queries" section
4. Reference cheatsheet for syntax as needed

### Intermediate Path
1. Study **JOINs, Subqueries, CTEs** in cheatsheet
2. Run **generate-sample-data.sql** for TechStore database
3. Review **techstore-database.md** ER diagram
4. Practice complex analytical queries (lifetime value, rankings)

### Advanced Path
1. Master **Window Functions** and **Recursive CTEs** from cheatsheet
2. Use sample databases for **performance testing**
3. Implement all 5 data engineering projects using TechStore
4. Create your own data quality monitoring rules

---

## 🔄 Asset Updates

**Last Updated**: November 14, 2025

**Version History**:
- v1.0 (2025-11-14): Initial release
  - SQL Fundamentals cheatsheet
  - TechStore ER diagram
  - Sakila schema setup script
  - Sample data generator

**Planned Additions**:
- MySQL vs SQL Server syntax comparison cheatsheet
- Sakila ER diagram (visual)
- Banking database schema (for Project 2)
- Performance tuning cheatsheet
- Common SQL anti-patterns guide

---

## 📞 Support & Feedback

**Found an error?**
- Review the script/cheatsheet carefully
- Check SQL Server version compatibility (2016+ required)
- Verify you have proper database permissions

**Want to contribute?**
- Create custom cheatsheets for specific topics
- Add more sample databases
- Document additional query patterns
- Share your project implementations

---

## 🎓 Related Resources

**Within this Repository**:
- `00-getting-started/` - Installation and setup guides
- `01-lessons/` - Structured lessons on SQL topics
- `02-exercises/` - Practice problems for each chapter
- `04-projects/` - Real-world data engineering projects

**External Resources**:
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [T-SQL Language Reference](https://docs.microsoft.com/en-us/sql/t-sql/)
- [Execution Plan Analysis](https://www.sqlskills.com/help/execution-plans/)
- [Database Normalization Guide](https://www.guru99.com/database-normalization.html)

---

**Happy Learning! 🚀**

*These assets are designed to accelerate your SQL mastery. Use them frequently, reference them often, and practice consistently.*
