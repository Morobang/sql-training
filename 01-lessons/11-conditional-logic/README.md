# Chapter 11: Conditional Logic

## Overview

Master SQL's conditional logic capabilities using CASE expressions and related techniques. Learn to transform data, handle complex business rules, perform conditional aggregations, and write sophisticated queries that adapt to different conditions.

**Difficulty Level:** Intermediate  
**Estimated Time:** 6-8 hours  
**Prerequisites:** Chapters 1-10 (especially subqueries and joins)

---

## 🎯 Learning Objectives

By the end of this chapter, you will be able to:

- ✅ Understand CASE expression syntax and usage
- ✅ Write both simple and searched CASE expressions
- ✅ Perform result set transformations (pivoting)
- ✅ Use conditional logic in WHERE, SELECT, and ORDER BY clauses
- ✅ Handle division by zero and NULL values
- ✅ Perform conditional updates and aggregations
- ✅ Check for existence with conditional logic
- ✅ Apply CASE expressions to real-world scenarios

---

## 📚 Lessons

### 🔰 Fundamentals (Lessons 1-2)

#### [Lesson 11.01 - What is Conditional Logic](01-what-is-conditional-logic/01-what-is-conditional-logic.sql)
**Time:** 25 minutes | **Difficulty:** ⭐☆☆☆☆

Introduction to conditional logic in SQL.
- Why use conditional logic
- CASE expression overview
- Alternative approaches (COALESCE, NULLIF)
- When to use conditional logic
- Real-world applications

**Key Concepts:** IF-THEN-ELSE logic, CASE syntax, conditional evaluation

---

#### [Lesson 11.02 - CASE Expression](02-case-expression/02-case-expression.sql)
**Time:** 30 minutes | **Difficulty:** ⭐⭐☆☆☆

Deep dive into CASE expression fundamentals.
- CASE expression syntax
- Simple vs Searched CASE
- Return types and data type consistency
- CASE in different clauses
- Nesting CASE expressions

**Key Concepts:** CASE structure, WHEN-THEN-ELSE, expression evaluation

---

### 📊 CASE Expression Types (Lessons 3-5)

#### [Lesson 11.03 - Searched CASE Expressions](03-searched-case-expressions/03-searched-case-expressions.sql)
**Time:** 35 minutes | **Difficulty:** ⭐⭐☆☆☆

Master the most flexible CASE format.
- Searched CASE syntax
- Complex boolean conditions
- Multiple conditions per WHEN
- Range checking and comparisons
- Performance considerations

**Key Concepts:** Boolean expressions, condition precedence, flexible matching

---

#### [Lesson 11.04 - Simple CASE Expressions](04-simple-case-expressions/04-simple-case-expressions.sql)
**Time:** 30 minutes | **Difficulty:** ⭐⭐☆☆☆

Learn the concise equality-based CASE format.
- Simple CASE syntax
- Equality comparisons
- When to use simple vs searched
- Converting between formats
- Limitations and workarounds

**Key Concepts:** Equality matching, concise syntax, value mapping

---

#### [Lesson 11.05 - CASE Examples](05-case-examples/05-case-examples.sql)
**Time:** 40 minutes | **Difficulty:** ⭐⭐⭐☆☆

Comprehensive real-world CASE expression examples.
- Customer segmentation
- Grade calculation
- Status classification
- Dynamic sorting
- Conditional formatting

**Key Concepts:** Practical applications, business rules, data categorization

---

### 🔄 Data Transformation (Lessons 6-7)

#### [Lesson 11.06 - Result Set Transformations](06-result-set-transformations/06-result-set-transformations.sql)
**Time:** 45 minutes | **Difficulty:** ⭐⭐⭐⭐☆

Transform rows to columns using CASE (pivoting).
- Pivoting data with CASE
- Cross-tab reports
- Dynamic columns
- Aggregation with CASE
- PIVOT operator comparison

**Key Concepts:** Pivoting, cross-tabulation, conditional aggregation

---

#### [Lesson 11.07 - Checking Existence](07-checking-existence/07-checking-existence.sql)
**Time:** 30 minutes | **Difficulty:** ⭐⭐⭐☆☆

Use CASE with EXISTS and subqueries.
- CASE with EXISTS
- Conditional flags
- Multiple existence checks
- Performance optimization
- Alternative approaches

**Key Concepts:** Existence checking, boolean flags, correlated subqueries

---

### ⚠️ Error Handling (Lessons 8-10)

#### [Lesson 11.08 - Division by Zero Errors](08-division-by-zero-errors/08-division-by-zero-errors.sql)
**Time:** 25 minutes | **Difficulty:** ⭐⭐☆☆☆

Prevent and handle division by zero errors.
- Division by zero problem
- CASE for zero checking
- NULLIF function
- IIF function (SQL Server)
- Safe calculations

**Key Concepts:** Error prevention, safe division, NULLIF, IIF

---

#### [Lesson 11.09 - Conditional Updates](09-conditional-updates/09-conditional-updates.sql)
**Time:** 35 minutes | **Difficulty:** ⭐⭐⭐☆☆

Use CASE in UPDATE and INSERT statements.
- UPDATE with CASE
- Conditional column updates
- Multiple condition updates
- INSERT with CASE
- Merge operations

**Key Concepts:** Conditional DML, bulk updates, data modification

---

#### [Lesson 11.10 - Handling NULL Values](10-handling-null-values/10-handling-null-values.sql)
**Time:** 35 minutes | **Difficulty:** ⭐⭐⭐☆☆

Master NULL handling with conditional logic.
- CASE for NULL detection
- COALESCE function
- ISNULL vs COALESCE
- NULL replacement strategies
- Complex NULL logic

**Key Concepts:** NULL handling, COALESCE, default values, NULL propagation

---

### 📝 Assessment (Lesson 11)

#### [Lesson 11.11 - Test Your Knowledge](11-test-your-knowledge/11-test-your-knowledge.sql)
**Time:** 90 minutes | **Difficulty:** ⭐⭐⭐⭐☆

Comprehensive assessment of conditional logic concepts.
- 40+ questions covering all topics
- 400 total points
- Practical scenarios
- Performance challenges
- Real-world applications

---

## 🗺️ Learning Path

```
Conditional Logic Journey
│
├─── 📖 Fundamentals (Lessons 1-2)
│    ├─ What is conditional logic?
│    └─ CASE expression basics
│
├─── 🎯 CASE Types (Lessons 3-5)
│    ├─ Searched CASE (flexible)
│    ├─ Simple CASE (concise)
│    └─ Real-world examples
│
├─── 🔄 Transformations (Lessons 6-7)
│    ├─ Pivoting with CASE
│    └─ Existence checking
│
├─── ⚠️ Error Handling (Lessons 8-10)
│    ├─ Division by zero
│    ├─ Conditional updates
│    └─ NULL handling
│
└─── ✅ Assessment (Lesson 11)
     └─ Comprehensive test
```

**Recommended Path:**
1. Start with fundamentals (Lessons 1-2)
2. Master CASE types (Lessons 3-5)
3. Learn transformations (Lessons 6-7)
4. Practice error handling (Lessons 8-10)
5. Complete assessment (Lesson 11)

---

## 💡 Key Concepts

### CASE Expression Syntax

**Searched CASE (Most Flexible):**
```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    WHEN condition3 THEN result3
    ELSE default_result
END
```

**Simple CASE (Equality Only):**
```sql
CASE expression
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    WHEN value3 THEN result3
    ELSE default_result
END
```

### Common Patterns

1. **Categorization:**
```sql
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceCategory
FROM Products;
```

2. **Pivoting:**
```sql
SELECT 
    ProductID,
    SUM(CASE WHEN YEAR(OrderDate) = 2023 THEN Quantity ELSE 0 END) AS Qty2023,
    SUM(CASE WHEN YEAR(OrderDate) = 2024 THEN Quantity ELSE 0 END) AS Qty2024
FROM OrderDetails
GROUP BY ProductID;
```

3. **Conditional Aggregation:**
```sql
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(CASE WHEN TotalAmount > 500 THEN 1 END) AS LargeOrders,
    COUNT(CASE WHEN TotalAmount <= 500 THEN 1 END) AS SmallOrders
FROM Orders;
```

4. **Safe Division:**
```sql
SELECT 
    CASE 
        WHEN Denominator = 0 THEN NULL
        ELSE Numerator / Denominator
    END AS SafeResult
FROM MyTable;
```

---

## 🎓 Best Practices

### ✅ DO:
- Use ELSE clause for completeness
- Keep CASE expressions readable (one per line)
- Use searched CASE for complex conditions
- Consider data type consistency
- Comment complex CASE logic
- Test all branches
- Use COALESCE for simple NULL handling

### ❌ DON'T:
- Nest CASE more than 2-3 levels deep
- Use CASE when simpler functions exist (COALESCE, NULLIF)
- Forget ELSE clause (NULL by default)
- Mix data types in results
- Over-complicate with unnecessary CASE
- Ignore NULL handling
- Use CASE in WHERE when AND/OR suffice

---

## 🔧 Common Use Cases

| Use Case | CASE Type | Complexity |
|----------|-----------|------------|
| Status mapping | Simple | ⭐☆☆☆☆ |
| Price categorization | Searched | ⭐⭐☆☆☆ |
| Pivoting data | Searched | ⭐⭐⭐☆☆ |
| Division by zero | Searched | ⭐⭐☆☆☆ |
| Multi-level categorization | Searched | ⭐⭐⭐☆☆ |
| Conditional updates | Both | ⭐⭐⭐☆☆ |
| Dynamic sorting | Searched | ⭐⭐⭐⭐☆ |
| Complex business rules | Searched | ⭐⭐⭐⭐☆ |

---

## 📊 Quick Reference

### CASE vs Other Functions

| Function | Purpose | When to Use |
|----------|---------|-------------|
| `CASE` | Complex conditional logic | Multiple conditions, different results |
| `COALESCE` | Return first non-NULL | Simple NULL replacement |
| `NULLIF` | Return NULL if equal | Prevent division by zero |
| `IIF` | Simple IF-THEN-ELSE | SQL Server, simple conditions |
| `ISNULL` | Replace NULL | SQL Server, single replacement |

### Performance Tips

1. **Order WHEN clauses by frequency** (most common first)
2. **Use simple CASE when possible** (faster equality checks)
3. **Avoid functions in WHEN conditions** (prevents index usage)
4. **Consider computed columns** for frequently used CASE
5. **Test with execution plans** for complex CASE logic

---

## 🚀 Real-World Applications

### 1. Customer Segmentation
```sql
CASE 
    WHEN TotalPurchases > 10000 THEN 'VIP'
    WHEN TotalPurchases > 5000 THEN 'Gold'
    WHEN TotalPurchases > 1000 THEN 'Silver'
    ELSE 'Bronze'
END
```

### 2. Dynamic Reporting
```sql
SELECT 
    Category,
    SUM(CASE WHEN Month = 'Jan' THEN Sales ELSE 0 END) AS Jan,
    SUM(CASE WHEN Month = 'Feb' THEN Sales ELSE 0 END) AS Feb,
    SUM(CASE WHEN Month = 'Mar' THEN Sales ELSE 0 END) AS Mar
FROM Sales
GROUP BY Category;
```

### 3. Business Rules
```sql
CASE 
    WHEN OrderDate IS NULL THEN 'Pending'
    WHEN ShipDate IS NULL THEN 'Processing'
    WHEN DeliveryDate IS NULL THEN 'Shipped'
    ELSE 'Delivered'
END
```

---

## 📝 Chapter Summary

### What You'll Learn:

1. **CASE Expression Mastery**
   - Both simple and searched formats
   - Syntax and structure
   - Best practices

2. **Data Transformation**
   - Pivoting rows to columns
   - Cross-tabulation
   - Conditional aggregation

3. **Error Handling**
   - Division by zero prevention
   - NULL value handling
   - Safe calculations

4. **Practical Applications**
   - Customer segmentation
   - Status tracking
   - Dynamic reporting
   - Conditional updates

### Skills Gained:

- Write conditional logic in SQL
- Transform data structures
- Handle edge cases safely
- Apply business rules in queries
- Optimize conditional expressions
- Debug complex CASE statements

---

## 🎯 Success Criteria

You've mastered this chapter when you can:

- [ ] Write both simple and searched CASE expressions
- [ ] Pivot data using CASE (rows to columns)
- [ ] Handle division by zero errors
- [ ] Use CASE in SELECT, WHERE, ORDER BY, and UPDATE
- [ ] Choose between CASE, COALESCE, and NULLIF
- [ ] Nest CASE expressions appropriately
- [ ] Apply conditional logic to business rules
- [ ] Optimize CASE expression performance
- [ ] Score 70%+ on the chapter test

---

## 📚 Additional Resources

### Documentation:
- [SQL CASE Expression (Microsoft)](https://docs.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql)
- [COALESCE Function](https://docs.microsoft.com/en-us/sql/t-sql/language-elements/coalesce-transact-sql)
- [NULLIF Function](https://docs.microsoft.com/en-us/sql/t-sql/language-elements/nullif-transact-sql)

### Related Chapters:
- **Chapter 07:** Data Generation & Manipulation
- **Chapter 08:** Grouping & Aggregates
- **Chapter 09:** Subqueries
- **Chapter 10:** Joins Revisited

---

## 🔗 Navigation

- **Previous:** [Chapter 10 - Joins Revisited](../10-joins-revisited/README.md)
- **Next:** [Chapter 12 - Transactions](../12-transactions/README.md)
- **Home:** [Course Home](../../README.md)

---

## 📅 Recommended Schedule

| Day | Lessons | Time | Focus |
|-----|---------|------|-------|
| 1 | 11.01-11.02 | 1 hour | CASE fundamentals |
| 2 | 11.03-11.04 | 1.5 hours | CASE types |
| 3 | 11.05 | 1 hour | Real-world examples |
| 4 | 11.06-11.07 | 1.5 hours | Data transformation |
| 5 | 11.08-11.10 | 2 hours | Error handling |
| 6 | 11.11 | 1.5 hours | Assessment |

**Total:** 6 days, 8.5 hours

---

**Ready to master conditional logic in SQL? Start with [Lesson 11.01](01-what-is-conditional-logic/01-what-is-conditional-logic.sql)!** 🚀

---

*Last Updated: November 2024*  
*Version: 1.0*  
*Difficulty: Intermediate*
