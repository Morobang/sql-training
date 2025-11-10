# 🎓 SQL Learning Guide

Welcome! This repository is designed to teach SQL from **absolute beginner to advanced professional** with a clean, progressive learning path.

## 📚 How This Repository is Organized

### Core Learning Path (Start Here!)

Follow these lessons in order:

```
🟢 BEGINNER (1-2 weeks)
   ↓
🟡 INTERMEDIATE (3-4 weeks)
   ↓
🔴 ADVANCED (4-6 weeks)
```

### Additional Deep-Dive Content

Each level has an "additional-topics" folder with extra lessons for deeper mastery:
- `01-beginner/06-additional-topics/`
- `02-intermediate/15-additional-topics/`
- `03-advanced/13-additional-topics/`

**Use these AFTER completing the main lessons** for comprehensive coverage.

---

## 🟢 Beginner Level (Required First)

**Goal:** Learn SQL fundamentals - enough to retrieve and modify data confidently.

**Time:** ~2 hours of core content + practice

### Core Lessons (Do These In Order):

1. **Introduction to SQL** (15 min)
   - What is SQL and why learn it?
   - Types of databases
   - SQL vs other languages
   
2. **Setup Your Environment** (12 min)
   - Install SQL Server
   - Install a SQL tool (SSMS or Azure Data Studio)
   - Connect to your first database

3. **Query Data** (58 min) ⭐ MOST IMPORTANT
   - SELECT statements
   - Filtering with WHERE
   - Sorting with ORDER BY
   - Limiting results
   - Pattern matching with LIKE
   
4. **DDL Commands** (11 min)
   - CREATE tables
   - ALTER table structure
   - DROP tables
   - Data types

5. **DML Commands** (24 min)
   - INSERT data
   - UPDATE data
   - DELETE data
   - Transactions basics

### ✅ Beginner Checklist

After completing beginner lessons, you should be able to:
- [ ] Write SELECT queries to retrieve data
- [ ] Filter data with WHERE clause
- [ ] Sort results with ORDER BY
- [ ] Create simple tables
- [ ] Insert, update, and delete data
- [ ] Understand when to use transactions

**⚠️ Important:** Don't move to Intermediate until you're comfortable with these basics!

---

## 🟡 Intermediate Level

**Goal:** Master advanced querying, combining data, and using functions.

**Time:** ~10 hours of core content + practice

**Prerequisites:** Complete ALL Beginner lessons first!

### Core Lessons (Do These In Order):

1. **Filtering Data** (40 min)
   - Complex WHERE conditions
   - AND, OR, NOT operators
   - IN, BETWEEN operators
   - NULL handling

2. **SQL Joins - Basics** (40 min)
   - INNER JOIN
   - Joining multiple tables
   - Table aliases

3. **SQL Joins - Advanced** (35 min)
   - LEFT/RIGHT/FULL OUTER JOIN
   - CROSS JOIN
   - SELF JOIN

4. **Set Operators** (45 min)
   - UNION and UNION ALL
   - INTERSECT
   - EXCEPT

5. **String Functions** (26 min)
   - UPPER, LOWER, TRIM
   - CONCAT, SUBSTRING
   - Pattern functions

6. **Numeric Functions** (4 min)
   - ROUND, CEILING, FLOOR
   - ABS, POWER

7. **Date & Time Functions** (96 min)
   - GETDATE, DATEADD, DATEDIFF
   - Date formatting
   - Date calculations

8. **NULL Functions** (32 min)
   - ISNULL, COALESCE
   - NULLIF
   - NULL handling strategies

9. **CASE Expressions** (38 min)
   - Simple CASE
   - Searched CASE
   - IIF function

10. **Aggregate Functions** (75 min)
    - COUNT, SUM, AVG
    - MIN, MAX
    - GROUP BY
    - HAVING clause

11-14. **Window Functions** (251 min total)
    - Basics (OVER clause, PARTITION BY)
    - Aggregates (Running totals, moving averages)
    - Ranking (ROW_NUMBER, RANK, DENSE_RANK)
    - Value (LAG, LEAD, FIRST_VALUE, LAST_VALUE)

### ✅ Intermediate Checklist

After completing intermediate lessons, you should be able to:
- [ ] Join multiple tables together
- [ ] Use aggregate functions with GROUP BY
- [ ] Write complex filtering conditions
- [ ] Use window functions for analytics
- [ ] Work with strings, dates, and numbers
- [ ] Handle NULL values properly

---

## 🔴 Advanced Level

**Goal:** Professional database development, optimization, and administration.

**Time:** ~10 hours of core content + practice

**Prerequisites:** Complete ALL Beginner AND Intermediate lessons first!

### Core Lessons (Do These In Order):

1. **Subqueries** (45 min)
   - Scalar subqueries
   - Correlated subqueries
   - EXISTS vs IN

2. **CTEs (Common Table Expressions)** (52 min)
   - WITH clause
   - Recursive CTEs
   - CTEs vs subqueries

3. **Views** (38 min)
   - Creating views
   - Indexed views
   - Security with views

4. **Stored Procedures** (65 min)
   - Parameters
   - Error handling (TRY/CATCH)
   - Business logic

5. **Functions (UDFs)** (42 min)
   - Scalar functions
   - Table-valued functions
   - When to use functions

6. **Triggers** (48 min)
   - AFTER triggers
   - INSTEAD OF triggers
   - Audit logging

7. **Indexes & Performance** (117 min)
   - Clustered vs non-clustered
   - Index design strategies
   - Fragmentation

8. **Execution Plans** (51 min)
   - Reading plans
   - Identifying bottlenecks
   - Query tuning

9. **Transactions Deep Dive** (33 min)
   - ACID properties
   - Isolation levels
   - Deadlock prevention

10. **Query Optimization** (41 min)
    - 30 performance tips
    - Sargability
    - Common anti-patterns

11. **Partitioning** (21 min)
    - Table partitioning
    - Partition strategies
    - Maintenance

12. **Advanced Analytics & AI** (47 min)
    - SQL + Python/R
    - JSON/XML in SQL
    - Temporal tables
    - Big data SQL

### ✅ Advanced Checklist

After completing advanced lessons, you should be able to:
- [ ] Design and optimize databases professionally
- [ ] Write stored procedures and functions
- [ ] Read and optimize execution plans
- [ ] Implement proper indexing strategies
- [ ] Handle transactions and concurrency
- [ ] Work with modern SQL features (JSON, temporal tables)

---

## 🎯 Learning Tips

### 1. **Don't Skip Lessons**
Each lesson builds on previous ones. Skipping ahead creates gaps in knowledge.

### 2. **Practice Everything**
Every lesson has practice exercises. Do them all! Type the code yourself.

### 3. **Use Your Own Database**
Create a practice database and experiment. Breaking things helps you learn.

### 4. **One Concept at a Time**
Don't try to learn everything at once. Master each lesson before moving forward.

### 5. **Review Regularly**
Go back and review previous lessons. Repetition builds muscle memory.

### 6. **Ask "Why?"**
Understand WHY something works, not just HOW to do it.

---

## 📈 Suggested Learning Schedule

### Full-Time Learning (4 weeks)
- **Week 1:** Beginner + practice
- **Week 2:** Intermediate (lessons 1-7)
- **Week 3:** Intermediate (lessons 8-14)
- **Week 4:** Advanced (lessons 1-12)

### Part-Time Learning (12 weeks)
- **Weeks 1-2:** Beginner + practice
- **Weeks 3-7:** Intermediate (2-3 lessons per week)
- **Weeks 8-12:** Advanced (2-3 lessons per week)

### Self-Paced Learning
- Spend **at least 30 minutes daily**
- Complete **one lesson per day** minimum
- Do ALL practice exercises
- Review previous week's lessons on weekends

---

## 🚀 After Completing This Course

### Next Steps:
1. **Build Projects** - See `04-projects/` folder
2. **Practice More** - See `02-exercises/` folder
3. **Deep Dive** - Explore `additional-topics` folders
4. **Real-World Practice:**
   - Contribute to open-source projects
   - Build a personal project with a database
   - Take on SQL challenges (LeetCode, HackerRank)
   - Get a SQL certification (Microsoft, Oracle)

### Career Paths:
- Data Analyst
- Data Scientist
- Data Engineer
- Database Administrator
- Backend Developer
- Business Intelligence Developer

---

## ❓ FAQ

**Q: Can I skip beginner if I know basic SQL?**
A: Review it quickly, but don't skip. You might find gaps in your knowledge.

**Q: How long does it take to learn SQL?**
A: Basics: 1-2 weeks. Professional level: 2-3 months with daily practice.

**Q: Do I need to memorize everything?**
A: No! Understand concepts and know where to look things up. Practice builds memory.

**Q: Which database should I use?**
A: This course uses SQL Server, but 90% applies to any SQL database.

**Q: What if I get stuck?**
A: Review previous lessons, check additional-topics folders, or search online documentation.

**Q: Can I learn SQL without programming experience?**
A: Yes! SQL is beginner-friendly. Start with the Beginner level and take it slow.

---

## 📞 Getting Help

- **Documentation:** Each lesson has examples and explanations
- **Practice:** Do the exercises - they reinforce learning
- **Community:** Search Stack Overflow for specific questions
- **Official Docs:** Microsoft SQL Server documentation

---

**Good luck on your SQL journey! 🚀**

Remember: Everyone starts as a beginner. Consistency beats intensity. Practice daily, and you'll be a SQL pro in no time!
