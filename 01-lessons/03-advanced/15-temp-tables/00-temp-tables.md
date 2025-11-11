# Temporary Tables & Table Variables

## 📚 Overview

Temporary tables and table variables are temporary storage structures used to hold intermediate results during complex query processing. They're essential for breaking down complex problems and improving query performance.

---

## 🎯 What You'll Learn

- Local temporary tables (#temp)
- Global temporary tables (##temp)
- Table variables (@table)
- When to use each type
- Performance characteristics
- Cleanup and scope
- Practical applications with TechStore

---

## 💡 Key Types

### **1. Local Temporary Table (#)**
```sql
CREATE TABLE #TempProducts (
    ProductID INT,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2)
);

INSERT INTO #TempProducts
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 100;

SELECT * FROM #TempProducts;

DROP TABLE #TempProducts;  -- Optional, auto-dropped when session ends
```

### **2. Global Temporary Table (##)**
```sql
CREATE TABLE ##GlobalTemp (
    ID INT,
    Value NVARCHAR(100)
);
-- Visible to ALL sessions
-- Dropped when last session using it disconnects
```

### **3. Table Variable (@)**
```sql
DECLARE @TempProducts TABLE (
    ProductID INT,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2)
);

INSERT INTO @TempProducts
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 100;

SELECT * FROM @TempProducts;
-- Auto-dropped at end of batch/procedure
```

---

## 🔄 Comparison

| Feature | #Temp Table | ##Global Temp | @Table Variable |
|---------|-------------|---------------|-----------------|
| **Scope** | Current session | All sessions | Current batch |
| **Statistics** | ✅ Yes | ✅ Yes | ❌ Limited |
| **Indexes** | ✅ Yes | ✅ Yes | ⚠️ Only constraints |
| **Truncate** | ✅ Yes | ✅ Yes | ❌ No |
| **Transactions** | ✅ Full | ✅ Full | ⚠️ Limited |
| **Performance** | Better for large data | Better for large data | Better for small data |
| **Recompiles** | Less | Less | ❌ No recompiles |

---

## 🎯 When to Use Each

### Use **#Temp Tables** when:
- Working with large datasets (>100 rows)
- Need indexes for performance
- Need statistics for query optimization
- Multiple operations on the data
- Need transaction support

### Use **@Table Variables** when:
- Very small datasets (<100 rows)
- Simple operations
- Want to avoid recompiles
- Short-lived operations in stored procedures

### Use **##Global Temp** when:
- Need to share data between sessions
- Cross-session temporary staging
- (Rarely needed in modern applications)

---

## 📊 Performance Tips

### ✅ **DO:**
- Create indexes on #temp tables for large datasets
- Use appropriate data types
- Drop temp tables when done (memory cleanup)
- Use table variables for small lookups

### ❌ **DON'T:**
- Use table variables for large datasets
- Forget to create indexes on temp tables
- Use global temp tables without good reason
- Create temp tables in loops

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-local-temp-tables.sql` - # temporary tables
2. `02-table-variables.sql` - @ table variables
3. `03-temp-vs-variable.sql` - Performance comparison
4. `04-practical-temp-tables.sql` - Real-world examples
5. `05-temp-table-indexing.sql` - Optimizing with indexes

---

## 💡 Pro Tips

- Temp tables go to `tempdb` database
- Name conflicts resolved with unique suffixes
- Table variables don't cause recompiles (good for procedures)
- Use `SELECT INTO #temp` for quick temp table creation
- Monitor `tempdb` usage in production
- Consider CTEs before temp tables

---

**Ready to master temporary storage? Start with `01-local-temp-tables.sql`! 🚀**
