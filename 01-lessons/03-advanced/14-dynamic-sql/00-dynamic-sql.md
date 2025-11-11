# Dynamic SQL

## 📚 Overview

Dynamic SQL allows you to build and execute SQL statements programmatically at runtime. This powerful technique enables you to create flexible queries where table names, column names, or entire query structures can change based on parameters or conditions.

---

## 🎯 What You'll Learn

- EXEC and EXECUTE for simple dynamic SQL
- sp_executesql for parameterized queries
- Building dynamic queries with variables
- SQL injection prevention
- When and when NOT to use dynamic SQL
- Practical applications with TechStore

---

## 💡 Key Concepts

### **Basic EXEC:**
```sql
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT * FROM Products WHERE Price > 100';
EXEC(@sql);
```

### **sp_executesql (Safer & Faster):**
```sql
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'SELECT * FROM Products WHERE Price > @MinPrice';
EXEC sp_executesql @sql, N'@MinPrice DECIMAL(10,2)', @MinPrice = 100;
```

### **Building Dynamic Queries:**
```sql
DECLARE @tableName NVARCHAR(100) = 'Products';
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT COUNT(*) FROM ' + QUOTENAME(@tableName);
EXEC(@sql);
```

---

## ⚠️ Security: SQL Injection

### ❌ DANGEROUS (Vulnerable to SQL Injection):
```sql
-- NEVER DO THIS!
DECLARE @userInput NVARCHAR(100) = 'Products; DROP TABLE Customers--';
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT * FROM ' + @userInput;
EXEC(@sql);  -- DISASTER!
```

### ✅ SAFE (Using QUOTENAME and Parameters):
```sql
DECLARE @tableName NVARCHAR(100) = 'Products';
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT * FROM ' + QUOTENAME(@tableName);
EXEC(@sql);
```

### ✅ SAFEST (sp_executesql with Parameters):
```sql
DECLARE @minPrice DECIMAL(10,2) = 100;
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'SELECT * FROM Products WHERE Price > @Price';
EXEC sp_executesql @sql, N'@Price DECIMAL(10,2)', @Price = @minPrice;
```

---

## 🎯 When to Use Dynamic SQL

### ✅ **Good Use Cases:**
- Search filters with variable conditions
- Pivot tables with dynamic columns
- Administrative scripts for multiple databases
- Reports with user-selected columns
- Generic maintenance procedures

### ❌ **Avoid When:**
- Static queries work fine
- Security is critical (user input)
- Performance is critical (no plan caching with EXEC)
- Logic can be done with IF statements

---

## 📊 sp_executesql Benefits

| Feature | EXEC() | sp_executesql |
|---------|--------|---------------|
| **Parameterization** | ❌ No | ✅ Yes |
| **Plan Caching** | ❌ No | ✅ Yes |
| **SQL Injection** | ⚠️ Risk | ✅ Safer |
| **Output Parameters** | ❌ No | ✅ Yes |
| **Performance** | Slower | Faster |

---

## 💡 Best Practices

1. **Always use sp_executesql over EXEC** for parameterized queries
2. **Use QUOTENAME()** for table/column names
3. **Validate user input** before building queries
4. **Whitelist values** instead of blacklisting
5. **Test thoroughly** - dynamic SQL is hard to debug
6. **Document why** dynamic SQL is needed

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-basic-dynamic-sql.sql` - Simple EXEC examples
2. `02-sp-executesql.sql` - Parameterized dynamic queries
3. `03-dynamic-search.sql` - Flexible search filters
4. `04-dynamic-pivot.sql` - Dynamic pivot tables
5. `05-security-best-practices.sql` - Preventing SQL injection

---

## 💡 Pro Tips

- Print the @sql variable before executing to debug
- Use TRY-CATCH around dynamic SQL
- Limit dynamic SQL to stored procedures (not ad-hoc queries)
- Consider alternatives (table-valued parameters, CASE statements)
- Cache execution plans with sp_executesql

---

**Ready to master dynamic SQL? Start with `01-basic-dynamic-sql.sql`! 🚀**
