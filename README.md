# 🎓 SQL Training: Fundamentals to Advanced

> A complete, project-based SQL learning path for absolute beginners to advanced database professionals

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 📖 About This Course

This comprehensive SQL training program takes you from absolute beginner to advanced database professional. Learn SQL using **Microsoft SQL Server** through hands-on exercises, real-world projects, and industry best practices.

### 🎯 What You'll Learn

- **Fundamentals**: Database concepts, SQL syntax, basic queries
- **Data Manipulation**: INSERT, UPDATE, DELETE, and transaction management
- **Advanced Queries**: Joins, subqueries, set operations, CTEs
- **Performance**: Indexing, query optimization, execution plans
- **Database Design**: Normalization, constraints, relationships
- **Advanced Features**: Views, stored procedures, triggers, analytics
- **Real-World Skills**: Projects simulating actual business scenarios

### ⚡ New: Executable SQL Scripts!

**Learn by doing!** Every lesson now includes practical `.sql` files you can run on your own SQL Server:

- 🔧 **Setup Scripts**: One-click database setup
- 📝 **Example Scripts**: Working code for every concept
- 🎯 **Exercise Scripts**: Hands-on practice with solutions
- ✅ **Run & Learn**: Execute on your system, see real results

👉 See [HOW-TO-USE-SCRIPTS.md](./01-lessons/02-creating-database/HOW-TO-USE-SCRIPTS.md) to get started!

### 👥 Who This Course Is For

- ✅ **Complete Beginners** - No prior SQL or database experience needed
- ✅ **Developers** - Add SQL skills to your programming toolkit
- ✅ **Data Analysts** - Master data querying and analysis
- ✅ **Database Administrators** - Learn administration and optimization
- ✅ **Students** - Build a strong foundation for career advancement

---

## 🗂️ Course Structure

### [00 - Getting Started](./00-getting-started/)
Set up your complete SQL learning environment

- **[Installation Guide](./00-getting-started/01-installation-guide.md)** - Install SQL Server and client tools
- **[Database Setup](./00-getting-started/02-database-setup.md)** - Create sample databases (Sakila, HR)
- **[Tools Overview](./00-getting-started/03-tools-overview.md)** - Master SSMS, Azure Data Studio, VS Code

**Time:** 1-2 hours | **Difficulty:** Beginner

---

### [01 - Lessons](./01-lessons/) - New 3-Level Progressive Learning Path

## 🟢 [BEGINNER LEVEL](./01-lessons/01-beginner/) 
**Duration:** ~1 hour 44 minutes | **5 Lessons**

Master the fundamentals of SQL and database operations.

| # | Lesson | Duration | What You'll Learn |
|---|--------|----------|-------------------|
| 1 | [Intro to SQL](./01-lessons/01-beginner/01-intro-to-sql/) | 15 min | What SQL is, why databases matter, RDBMS concepts |
| 2 | [Setup Environment](./01-lessons/01-beginner/02-setup-environment/) | 12 min | SQL Server setup, tools (SSMS/Azure Data Studio) |
| 3 | [Query Data](./01-lessons/01-beginner/03-query-data/) | 58 min | SELECT, WHERE, ORDER BY, basic filtering |
| 4 | [DDL Commands](./01-lessons/01-beginner/04-ddl-commands/) | 11 min | CREATE, ALTER, DROP tables and databases |
| 5 | [DML Commands](./01-lessons/01-beginner/05-dml-commands/) | 24 min | INSERT, UPDATE, DELETE, basic transactions |

**After completing**: You'll be able to create databases, tables, and perform CRUD operations.

---

## 🟡 [INTERMEDIATE LEVEL](./01-lessons/02-intermediate/)
**Duration:** ~10 hours | **14 Lessons**

Advanced querying, functions, and analytical techniques.

| # | Lesson | Duration | What You'll Learn |
|---|--------|----------|-------------------|
| 1 | [Filtering Data](./01-lessons/02-intermediate/01-filtering-data/) | 40 min | Advanced WHERE, BETWEEN, IN, LIKE, NULL handling |
| 2 | [SQL Joins - Basics](./01-lessons/02-intermediate/02-sql-joins-basics/) | 40 min | INNER JOIN, table aliases, multi-table joins |
| 3 | [SQL Joins - Advanced](./01-lessons/02-intermediate/03-sql-joins-advanced/) | 35 min | LEFT/RIGHT/FULL/CROSS, SELF JOIN, APPLY |
| 4 | [Set Operators](./01-lessons/02-intermediate/04-set-operators/) | 45 min | UNION, INTERSECT, EXCEPT |
| 5 | [String Functions](./01-lessons/02-intermediate/05-string-functions/) | 26 min | UPPER, LOWER, TRIM, SUBSTRING, CONCAT |
| 6 | [Numeric Functions](./01-lessons/02-intermediate/06-numeric-functions/) | 4 min | ROUND, CEILING, FLOOR, ABS, POWER |
| 7 | [Date & Time Functions](./01-lessons/02-intermediate/07-date-time-functions/) | 96 min | GETDATE, DATEADD, DATEDIFF, formatting |
| 8 | [NULL Functions](./01-lessons/02-intermediate/08-null-functions/) | 32 min | COALESCE, ISNULL, NULLIF, three-valued logic |
| 9 | [CASE Expressions](./01-lessons/02-intermediate/09-case-expressions/) | 38 min | Searched/Simple CASE, conditional logic |
| 10 | [Aggregate Functions](./01-lessons/02-intermediate/10-aggregate-functions/) | 75 min | COUNT, SUM, AVG, GROUP BY, HAVING |
| 11 | [Window Functions - Basics](./01-lessons/02-intermediate/11-window-functions-basics/) | 57 min | OVER(), PARTITION BY, running totals |
| 12 | [Window Functions - Aggregates](./01-lessons/02-intermediate/12-window-functions-aggregates/) | 52 min | Window frames, moving averages, ROWS vs RANGE |
| 13 | [Window Functions - Ranking](./01-lessons/02-intermediate/13-window-functions-ranking/) | 68 min | ROW_NUMBER, RANK, DENSE_RANK, NTILE |
| 14 | [Window Functions - Value](./01-lessons/02-intermediate/14-window-functions-value/) | 74 min | LAG, LEAD, FIRST_VALUE, LAST_VALUE |

**After completing**: You'll master complex queries, analytics, and data transformations.

---

## � [ADVANCED LEVEL](./01-lessons/03-advanced/)
**Duration:** ~10 hours | **12 Lessons**

Professional database development, optimization, and administration.

| # | Lesson | Duration | What You'll Learn |
|---|--------|----------|-------------------|
| 1 | [Subqueries](./01-lessons/03-advanced/01-subqueries/) | 45 min | Scalar, row, table subqueries; EXISTS, correlated |
| 2 | [CTEs](./01-lessons/03-advanced/02-ctes/) | 52 min | Common Table Expressions, recursive CTEs |
| 3 | [Views](./01-lessons/03-advanced/03-views/) | 38 min | Creating views, indexed views, security |
| 4 | [Stored Procedures](./01-lessons/03-advanced/04-stored-procedures/) | 65 min | Parameters, error handling, business logic |
| 5 | [Functions (UDFs)](./01-lessons/03-advanced/05-functions/) | 42 min | Scalar, inline, multi-statement functions |
| 6 | [Triggers](./01-lessons/03-advanced/06-triggers/) | 48 min | DML/DDL triggers, audit logging |
| 7 | [Indexes & Performance](./01-lessons/03-advanced/07-indexes-performance/) | 72 min | Clustered/non-clustered indexes, design strategies |
| 8 | [Execution Plans](./01-lessons/03-advanced/08-execution-plans/) | 58 min | Reading plans, query tuning |
| 9 | [Transactions Deep Dive](./01-lessons/03-advanced/09-transactions/) | 55 min | ACID, isolation levels, deadlock prevention |
| 10 | [Query Optimization](./01-lessons/03-advanced/10-query-optimization/) | 68 min | Performance tuning, hints, statistics |
| 11 | [Partitioning & Sharding](./01-lessons/03-advanced/11-partitioning/) | 50 min | Table partitioning, scalability patterns |
| 12 | [Advanced Analytics](./01-lessons/03-advanced/12-advanced-analytics/) | 47 min | Modern SQL, BI integration, big data |

**After completing**: You'll be ready for production database development and DBA roles.

---

### � [Original 18-Chapter Archive](./01-lessons/00-original-chapters/)

The original sequential 18-chapter structure is preserved in the archive folder for reference. See [CONTENT-MIGRATION-MAP.md](./CONTENT-MIGRATION-MAP.md) for how content was reorganized into the new 3-level structure.

---

---

### [02 - Exercises](./02-exercises/)
Practice problems for each chapter with solutions

- 📝 **Chapter-by-chapter exercises** (18 chapters)
- 💡 **Difficulty levels:** Easy, Medium, Hard
- ✅ **Solutions provided** with explanations
- 🎯 **Progressive difficulty** building on previous concepts

**Time:** 20-30 hours | **Skill Development:** Essential

---

### [03 - Assets](./03-assets/)
Supporting materials and resources

- **[Cheatsheets](./03-assets/cheatsheets/)** - Quick reference guides
- **[ER Diagrams](./03-assets/er-diagrams/)** - Visual database schemas
- **[SQL Scripts](./03-assets/sql-scripts/)** - Reusable code templates

---

### [04 - Projects](./04-projects/)
Real-world projects to solidify your skills

#### Project 1: Library Management System
Design and implement a complete library database with book tracking, member management, and lending functionality.

**Skills:** Database design, CRUD operations, relationships, basic queries  
**Time:** 6-8 hours | **Difficulty:** Beginner-Intermediate

#### Project 2: E-Commerce Analysis
Analyze sales data, customer behavior, and product performance for an online store using advanced queries and analytics.

**Skills:** Complex joins, aggregations, window functions, reporting  
**Time:** 8-10 hours | **Difficulty:** Intermediate-Advanced

#### Project 3: Employee Database
Build an HR database with organizational hierarchy, payroll calculations, and employee analytics.

**Skills:** Self-joins, recursive queries, calculated fields, views  
**Time:** 8-10 hours | **Difficulty:** Intermediate

#### Project 4: Sales Reporting System
Create a comprehensive sales reporting system with dashboards, KPIs, and time-based analysis.

**Skills:** Complex aggregations, pivoting, stored procedures, optimization  
**Time:** 10-12 hours | **Difficulty:** Advanced

**Total Project Time:** 32-40 hours

---

## 🚀 Getting Started

### Prerequisites

- **Computer:** Windows, Mac, or Linux
- **RAM:** Minimum 4GB (8GB recommended)
- **Disk Space:** 10GB for SQL Server and sample databases
- **Time Commitment:** 2-5 hours per week recommended

### Quick Start (30 minutes)

1. **Install SQL Server**
   ```powershell
   # Download from: https://www.microsoft.com/sql-server/sql-server-downloads
   # Choose Developer or Express edition (free)
   ```

2. **Install a SQL Client**
   - Windows: [SQL Server Management Studio (SSMS)](https://aka.ms/ssms)
   - Cross-platform: [Azure Data Studio](https://aka.ms/azuredatastudio)

3. **Set Up Sample Databases**
   ```sql
   -- Follow instructions in 00-getting-started/02-database-setup.md
   CREATE DATABASE Sakila;
   ```

4. **Test Your Setup**
   ```sql
   SELECT @@VERSION;
   SELECT * FROM sys.databases;
   ```

5. **Start Learning**
   - Begin with [00-getting-started](./00-getting-started/)
   - Then proceed to [01-lessons/01-background](./01-lessons/01-background/)

---

## 📚 Learning Path

### 🌱 Beginner Track (Weeks 1-4)
**Goal:** Understand databases and write basic queries

- Complete Getting Started setup
- Chapters 1-3: Background, Creating Databases, Query Primer
- Exercises for Chapters 1-3
- Project 1: Library Management System

**Outcome:** Can create databases, tables, and write SELECT queries with filtering and sorting

---

### 🌿 Intermediate Track (Weeks 5-10)
**Goal:** Master complex queries and data manipulation

- Chapters 4-9: Filtering, Joins, Sets, Functions, Grouping, Subqueries
- Exercises for Chapters 4-9
- Project 2: E-Commerce Analysis
- Project 3: Employee Database

**Outcome:** Can write complex multi-table queries with aggregations and subqueries

---

### 🌳 Advanced Track (Weeks 11-16)
**Goal:** Optimize performance and use advanced features

- Chapters 10-18: Advanced Joins, Transactions, Indexes, Views, Analytics, Big Data
- Exercises for Chapters 10-18
- Project 4: Sales Reporting System
- Performance tuning and optimization

**Outcome:** Can design efficient databases, optimize queries, and use advanced SQL features

---

## 💡 Study Tips

### Best Practices

1. **Practice Daily** - Even 30 minutes a day is better than cramming
2. **Type Every Query** - Don't copy-paste; muscle memory matters
3. **Experiment** - Modify examples to see what happens
4. **Use Test Data** - Practice on sample databases, not production!
5. **Read Execution Plans** - Understand how queries actually run
6. **Document Your Learning** - Keep a notebook or blog

### Effective Learning Strategies

- **Pomodoro Technique:** 25 min study + 5 min break
- **Active Recall:** Try to write queries from memory
- **Spaced Repetition:** Review older topics regularly
- **Teach Others:** Explain concepts to solidify understanding
- **Build Projects:** Apply skills to real-world scenarios

### Common Pitfalls to Avoid

- ❌ Skipping foundational concepts
- ❌ Not practicing regularly
- ❌ Copy-pasting without understanding
- ❌ Ignoring error messages
- ❌ Not learning to read execution plans
- ❌ Forgetting to back up databases

---

## 🛠️ Tools & Resources

### Recommended Tools

| Tool | Platform | Purpose | Cost |
|------|----------|---------|------|
| SQL Server 2022 | All | Database Engine | Free |
| SSMS | Windows | Primary IDE | Free |
| Azure Data Studio | All | Modern IDE | Free |
| VS Code + mssql | All | Lightweight Editor | Free |
| DBeaver | All | Universal Client | Free |

### Learning Resources

- 📖 **Documentation:** [Microsoft SQL Server Docs](https://docs.microsoft.com/sql/)
- 🎥 **Videos:** [SQL Server YouTube Channel](https://www.youtube.com/c/SQLServer)
- 💬 **Community:** [Stack Overflow SQL Server](https://stackoverflow.com/questions/tagged/sql-server)
- 📝 **Blogs:** [SQL Server Central](https://www.sqlservercentral.com/)
- 🏆 **Practice:** [LeetCode SQL](https://leetcode.com/problemset/database/)

### Cheat Sheets

- [SQL Basics Cheat Sheet](./03-assets/cheatsheets/sql-basics.md)
- [Joins Cheat Sheet](./03-assets/cheatsheets/joins.md)
- [Functions Reference](./03-assets/cheatsheets/functions.md)
- [Performance Tuning Guide](./03-assets/cheatsheets/performance.md)

---

## 📊 Sample Database: Sakila

This course primarily uses the **Sakila** database, a sample database modeling a DVD rental store.

### Database Overview

**Tables:**
- `actor` - Movie actors
- `film` - Film catalog
- `customer` - Store customers
- `rental` - Rental transactions
- `payment` - Payment records
- `inventory` - Store inventory
- And more...

**Features:**
- Realistic business scenario
- Complex relationships
- Multiple data types
- Industry-standard schema

**Schema Diagram:** See [03-assets/er-diagrams/sakila-schema.png](./03-assets/er-diagrams/)

---

## 🎯 Certification & Career

### Skills You'll Gain

- ✅ Write complex SQL queries for data retrieval and analysis
- ✅ Design normalized database schemas
- ✅ Optimize query performance with indexes
- ✅ Implement transactions and maintain data integrity
- ✅ Use advanced features (views, stored procedures, triggers)
- ✅ Analyze and troubleshoot database issues
- ✅ Work with real-world business scenarios

### Career Paths

- **Database Administrator (DBA)** - $90k-$130k
- **Data Analyst** - $70k-$110k
- **Backend Developer** - $80k-$140k
- **Data Engineer** - $100k-$150k
- **Business Intelligence Developer** - $85k-$125k

### Relevant Certifications

- **Microsoft Certified: Azure Database Administrator Associate**
- **Microsoft Certified: Data Analyst Associate**
- **Oracle Database SQL Certified Associate**

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- 🐛 Report bugs and issues
- 💡 Suggest new exercises or projects
- 📝 Improve documentation
- ✨ Add new features or content
- 🌍 Translate content

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Sakila Database** - Originally developed by MySQL AB
- **Microsoft** - For SQL Server and excellent documentation
- **Open Source Community** - For tools and resources
- **Contributors** - Everyone who has contributed to this project

---

## 📞 Support & Community

- **Issues:** [GitHub Issues](https://github.com/Morobang/sql-training/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Morobang/sql-training/discussions)
- **Email:** [Your contact email]

---

## 🗺️ Roadmap

### Current Version: 1.0

- ✅ Core SQL lessons (18 chapters)
- ✅ Exercise sets for all chapters
- ✅ 4 comprehensive projects
- ✅ Sample databases and scripts

### Planned Features

- [ ] Video tutorials for each chapter
- [ ] Interactive SQL sandbox
- [ ] Additional practice databases
- [ ] Advanced performance tuning module
- [ ] Cloud database integration (Azure SQL, AWS RDS)
- [ ] Docker containers for easy setup
- [ ] Quiz/assessment system

---

## ⭐ Star This Repo

If you find this course helpful, please give it a star! It helps others discover this resource.

---

<div align="center">

**[Get Started Now](./00-getting-started/) | [View Lessons](./01-lessons/) | [Try Projects](./04-projects/)**

Made with ❤️ for the SQL learning community

---

*Last Updated: November 2025*

</div>
