# Phase 2: Silver Layer (Cleaned & Validated Data)

## Overview
The Silver layer transforms raw bronze data into **clean, validated, and standardized** data ready for analytics. This is where data quality issues get fixed.

## Objectives
- Convert VARCHAR to proper data types (DATE, INT, DECIMAL)
- Handle NULL values and missing data
- Deduplicate records
- Standardize formats (dates, phone numbers, emails)
- Validate business rules
- Create relationships between tables

## Files in This Phase

### 1. Setup & Concepts
- `README.md` (this file) - Silver layer concepts

### 2. Table Creation
- `01-create-silver-tables.sql` - Create silver tables with proper data types

### 3. Data Cleaning
- `02-clean-customers.sql` - Deduplicate, validate emails, standardize names
- `03-clean-inventory.sql` - Fix prices, handle negative quantities
- `04-clean-orders.sql` - Fix dates, remove invalid orders
- `05-join-silver-tables.sql` - Create unified datasets with proper relationships

### 4. Verification
- `06-verify-silver-data.sql` - Validate all cleaning rules applied correctly

## Data Cleaning Strategies

### Strategy 1: Type Conversion
```sql
-- Bronze: VARCHAR
order_date VARCHAR(50) = '2024-01-15'

-- Silver: Proper DATE
order_date DATE = CAST('2024-01-15' AS DATE)
```

### Strategy 2: NULL Handling
```sql
-- Replace empty strings with NULL
NULLIF(customer_id, '') AS customer_id

-- Provide defaults for missing values
COALESCE(email, 'unknown@techstore.com') AS email
```

### Strategy 3: Deduplication
```sql
-- Keep only the latest record for each customer
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY bronze_loaded_at DESC) = 1
```

### Strategy 4: Format Standardization
```sql
-- Standardize phone numbers to (555) 555-5555
CASE 
    WHEN phone LIKE '___-___-____' 
    THEN '(' + LEFT(phone, 3) + ') ' + SUBSTRING(phone, 5, 3) + '-' + RIGHT(phone, 4)
    ...
END
```

### Strategy 5: Data Validation
```sql
-- Remove invalid records
WHERE TRY_CAST(order_date AS DATE) IS NOT NULL  -- Valid dates only
  AND TRY_CAST(total_amount AS DECIMAL(10,2)) > 0  -- Positive amounts only
  AND quantity > 0  -- Positive quantities only
```

## Data Quality Rules

### Customers
- ✅ Deduplicate by customer_id (keep most recent)
- ✅ Standardize names to "First Last" format
- ✅ Validate email contains '@' and '.'
- ✅ Standardize phone to (555) 555-5555 format
- ✅ Ensure zip code is 5 or 9 digits
- ✅ Default tier to 'Standard' if missing

### Inventory
- ✅ Remove $ and commas from prices
- ✅ Convert prices to DECIMAL(10,2)
- ✅ Set negative quantities to 0
- ✅ Standardize is_active to BIT (1/0)
- ✅ Remove non-numeric quantities

### Orders
- ✅ Convert all dates to YYYY-MM-DD format
- ✅ Remove future dates (> today)
- ✅ Remove invalid dates
- ✅ Remove $ from amounts
- ✅ Remove orders with missing customer_id
- ✅ Convert quantity to INT (remove 'N/A')

## Expected Outcomes

After completing this phase:
- ✅ 3 silver tables with proper data types
- ✅ ~60,000 clean records (some invalid records removed)
- ✅ No duplicates
- ✅ All NULL values handled
- ✅ Consistent formatting across all fields
- ✅ Ready for Gold layer business aggregations

## Data Loss Acceptable?

**Yes!** It's better to remove bad data than to pollute analytics.

**What we'll remove**:
- Duplicate customers (~200 records)
- Orders with invalid dates (~100 records)
- Orders with missing customers (~500 records)
- Products with invalid quantities (~50 records)

**Total data loss**: ~850 records (< 2% of total)

## Next Phase
Once silver is complete, move to **Phase 3: Gold Layer** where you'll:
- Create customer summary analytics
- Calculate product performance metrics
- Build monthly sales trends
- Generate executive dashboards

## Time Estimate
3-4 hours to complete all silver layer files
