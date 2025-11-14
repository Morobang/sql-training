# Execution Guide - Data Quality Monitoring Project

## 📋 Quick Start

This guide walks you through executing the Data Quality Monitoring project step-by-step.

---

## 🎯 Prerequisites

- SQL Server 2016 or higher
- SSMS (SQL Server Management Studio) or Azure Data Studio
- Database permissions: CREATE DATABASE, CREATE TABLE, INSERT, SELECT

---

## 📂 Project Structure

```
05-data-quality-monitoring/
├── README.md                          # Project overview
├── PROJECT-SUMMARY.md                  # Complete documentation ⭐
├── EXECUTION-GUIDE.md                  # This file
├── 02-create-quality-tables.sql       # ✅ Infrastructure setup
├── 03-data-profiling.sql              # ✅ Statistical analysis
├── 04-quality-rules.sql               # ✅ Validation rules
├── 05-completeness-checks.sql         # ⏳ Pending
├── 06-accuracy-checks.sql             # ⏳ Pending
├── ... (additional files)
```

---

## 🚀 Execution Steps

### Phase 1: Quality Framework (COMPLETE ✅)

#### Step 1: Create Infrastructure (File 02)

```sql
-- Open: 02-create-quality-tables.sql
-- Execution time: ~30 seconds
-- This script creates:
```

**What it does**:
- Creates `TechStore_DQ` database
- Creates source tables (Customers, Products, Orders)
- Creates 6 metadata tables (quality_checks, quality_results, etc.)
- Inserts sample data with 10 intentional quality issues
- Creates monitoring views

**Run the script**:
1. Open SSMS and connect to your SQL Server instance
2. Open file: `02-create-quality-tables.sql`
3. Press F5 or click Execute
4. Verify output shows "Infrastructure setup complete"

**Verification**:
```sql
-- Check database created
USE TechStore_DQ;

-- Verify row counts
SELECT 'Customers' AS tbl, COUNT(*) AS rows FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders;

-- Expected: Customers=8, Products=8, Orders=102

-- Check metadata tables
SELECT COUNT(*) FROM metadata.quality_checks;       -- Should be 0 (populated in file 04)
SELECT COUNT(*) FROM metadata.quality_results;      -- Should be 0
SELECT COUNT(*) FROM metadata.quality_alerts;       -- Should be 0
SELECT COUNT(*) FROM metadata.quality_expectations; -- Should be 4 baseline metrics
```

---

#### Step 2: Profile Data (File 03)

```sql
-- Open: 03-data-profiling.sql
-- Execution time: ~45 seconds
-- This script performs statistical analysis
```

**What it does**:
- Calculates row counts and date ranges
- Analyzes NULL value percentages
- Computes statistical measures (min/max/avg/stdev)
- Detects duplicate records
- Checks data freshness
- Validates referential integrity
- Saves profiling results to `metadata.data_profile`
- Identifies statistical anomalies using 2-sigma threshold

**Run the script**:
1. Open file: `03-data-profiling.sql`
2. Press F5 or click Execute
3. Review profiling output in Messages tab

**Expected Output**:
```
=== BASIC DATA PROFILING ===
Table Row Counts:
- Customers: 8 rows
- Products: 8 rows
- Orders: 102 rows

=== CUSTOMERS TABLE PROFILE ===
NULL Value Analysis:
- FirstName: 12.5% NULL (1 out of 8)
- LastName: 12.5% NULL
- Email: 0% NULL

Duplicate Email Analysis:
- john.doe@example.com: 2 occurrences (DUPLICATE)

=== PRODUCTS TABLE PROFILE ===
Price Statistics:
- Min: -49.99 ⚠️ (INVALID)
- Max: 299.99
- Avg: ~83.12
- StdDev: ~97.45

Stock Statistics:
- Min: -10 ⚠️ (INVALID)
- Max: 75
- Negative stock count: 1

=== ORDERS TABLE PROFILE ===
Order Amount Statistics:
- Min: -100.00 ⚠️ (INVALID)
- Max: 999999.99 ⚠️ (SUSPICIOUS)
- Avg: ~10000 (skewed by outlier)

Referential Integrity:
- Valid CustomerID: 100 orders
- INVALID CustomerID: 2 orders ⚠️ (orphans)
- Valid ProductID: 100 orders
- INVALID ProductID: 2 orders ⚠️ (orphans)
```

**Verification**:
```sql
-- Check profiling data saved
SELECT 
    table_name,
    column_name,
    row_count,
    null_percentage,
    min_value,
    max_value,
    avg_value
FROM metadata.data_profile
WHERE CAST(profile_date AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY table_name, column_name;

-- Should return 4 rows (Email, Price, StockQuantity, TotalAmount)
```

---

#### Step 3: Define Quality Rules (File 04)

```sql
-- Open: 04-quality-rules.sql
-- Execution time: ~10 seconds
-- This script defines 18 validation rules
```

**What it does**:
- Populates `metadata.quality_checks` with 18 validation rules
- Covers all 6 data quality dimensions:
  - **Completeness** (5 checks): NULL values, record counts
  - **Accuracy** (5 checks): Range validation, format checks
  - **Consistency** (2 checks): Referential integrity
  - **Timeliness** (2 checks): Data freshness SLA
  - **Uniqueness** (2 checks): Duplicate detection
  - **Distribution** (2 checks): Statistical anomaly detection

**Run the script**:
1. Open file: `04-quality-rules.sql`
2. Press F5 or click Execute
3. Review summary output

**Expected Output**:
```
Quality Checks Summary:
check_type         check_count  critical  warning
-------------------------------------------------
accuracy           5            4         1
completeness       5            5         0
consistency        2            2         0
distribution       2            0         2
timeliness         2            1         1
uniqueness         2            2         0
-------------------------------------------------
TOTAL              18           14        4
```

**Verification**:
```sql
-- View all quality rules
SELECT 
    check_id,
    check_name,
    table_name,
    check_type,
    severity,
    threshold_value,
    threshold_operator
FROM metadata.quality_checks
ORDER BY check_type, check_id;

-- Should return 18 rows

-- View critical checks only
SELECT check_name, table_name, description
FROM metadata.quality_checks
WHERE severity = 'critical'
ORDER BY check_type;

-- Should return 14 critical checks
```

---

### Phase 2: Automated Checks (IN PROGRESS ⏳)

Files 05-10 will implement execution procedures for each quality dimension.

**Coming Soon**:
- `05-completeness-checks.sql` - Execute completeness validations
- `06-accuracy-checks.sql` - Execute accuracy validations
- `07-consistency-checks.sql` - Execute consistency validations
- `08-freshness-checks.sql` - Execute timeliness validations
- `09-uniqueness-checks.sql` - Execute uniqueness validations
- `10-distribution-checks.sql` - Execute anomaly detection

---

## 🔍 Testing Quality Issues

The sample data includes **10 intentional quality issues**:

### Test 1: Completeness Failures

```sql
-- Find customers with NULL names (SHOULD FAIL)
SELECT CustomerID, FirstName, LastName, Email
FROM Customers
WHERE FirstName IS NULL OR LastName IS NULL;

-- Expected: 1 row (CustomerID=4)
```

### Test 2: Accuracy Failures

```sql
-- Find negative prices (SHOULD FAIL)
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price < 0;

-- Expected: 1 row (ProductID=6, Price=-49.99)

-- Find negative stock (SHOULD FAIL)
SELECT ProductID, ProductName, StockQuantity
FROM Products
WHERE StockQuantity < 0;

-- Expected: 1 row (ProductID=5, Stock=-10)

-- Find negative order amounts (SHOULD FAIL)
SELECT OrderID, TotalAmount
FROM Orders
WHERE TotalAmount < 0;

-- Expected: 1 row (OrderID=50, Amount=-100.00)
```

### Test 3: Consistency Failures

```sql
-- Find orphan orders (invalid CustomerID)
SELECT o.OrderID, o.CustomerID
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID
);

-- Expected: 2 rows (OrderID=101 and 102, CustomerID=999)

-- Find orphan orders (invalid ProductID)
SELECT o.OrderID, o.ProductID
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID
);

-- Expected: 2 rows (OrderID=101 and 102, ProductID=999)
```

### Test 4: Timeliness Failures

```sql
-- Find stale orders (> 24 hours old)
SELECT 
    OrderID,
    LoadedAt,
    DATEDIFF(HOUR, LoadedAt, GETDATE()) AS hours_old
FROM Orders
WHERE DATEDIFF(HOUR, LoadedAt, GETDATE()) > 24;

-- Expected: 1 row (OrderID=1, ~25 hours old)
```

### Test 5: Uniqueness Failures

```sql
-- Find duplicate emails
SELECT Email, COUNT(*) AS occurrence_count
FROM Customers
WHERE Email IS NOT NULL
GROUP BY Email
HAVING COUNT(*) > 1;

-- Expected: 1 row (john.doe@example.com, count=2)
```

---

## 📊 Monitoring Views

Use these views to monitor quality status:

```sql
-- Latest quality check results
SELECT * FROM vw_latest_quality_results;

-- Open quality alerts
SELECT * FROM vw_open_alerts;

-- Quality summary by table
SELECT * FROM vw_quality_summary;
```

---

## 🛠️ Troubleshooting

### Issue: "Database already exists"

```sql
-- Solution: Drop and recreate
USE master;
DROP DATABASE IF EXISTS TechStore_DQ;
-- Then re-run 02-create-quality-tables.sql
```

### Issue: "Profiling shows 0 rows"

```sql
-- Verify data was inserted
SELECT COUNT(*) FROM TechStore_DQ.dbo.Orders;

-- If 0, re-run 02-create-quality-tables.sql
```

### Issue: "Quality checks table is empty"

```sql
-- Verify checks were inserted
SELECT COUNT(*) FROM TechStore_DQ.metadata.quality_checks;

-- If 0, re-run 04-quality-rules.sql
```

---

## 📈 Performance Tips

For large production datasets:

1. **Sampling**: Check 10K rows instead of 10M
   ```sql
   SELECT TOP 10000 * FROM Orders TABLESAMPLE (10000 ROWS)
   ```

2. **Incremental Checks**: Only validate today's data
   ```sql
   WHERE LoadedAt >= CAST(GETDATE() AS DATE)
   ```

3. **Indexing**: Add indexes on frequently checked columns
   ```sql
   CREATE INDEX IX_Orders_LoadedAt ON Orders(LoadedAt);
   ```

4. **Parallel Execution**: Use SQL Agent to run checks concurrently

---

## ✅ Success Criteria

After executing Phase 1 scripts:

- [x] TechStore_DQ database created
- [x] 3 source tables populated (8 + 8 + 102 rows)
- [x] 6 metadata tables created
- [x] 4 baseline expectations defined
- [x] Data profiling completed and saved
- [x] 18 quality rules defined (14 critical + 4 warning)
- [x] 10 quality issues present for testing

---

## 🎯 Next Steps

1. Review profiling results to understand data characteristics
2. Examine quality rules in `metadata.quality_checks`
3. Prepare for Phase 2: Automated Check Execution
4. Plan alerting configuration (email/Slack)

---

## 📞 Support

For issues or questions:
- Review PROJECT-SUMMARY.md for detailed explanations
- Check inline comments in SQL scripts
- Verify you're using SQL Server 2016+
- Ensure sufficient database permissions

---

**Project Status**: Phase 1 Complete (Files 02-04) ✅  
**Next Phase**: Automated Quality Checks (Files 05-10) ⏳  
**Completion**: ~20% of total project
