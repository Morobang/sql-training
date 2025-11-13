# Chapter 7: Data Generation, Manipulation, and Conversion - Practice Questions

## Overview
Master string functions, numeric functions, date/time manipulation, type conversion, and CASE expressions.

---

## String Functions

### Question 1: String Concatenation (Easy)
Combine first_name and last_name into a full name with proper formatting.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: CONCAT function (works in most databases)
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM customers;

-- Method 2: || operator (PostgreSQL, Oracle)
SELECT first_name || ' ' || last_name AS full_name
FROM customers;

-- Method 3: + operator (SQL Server)
SELECT first_name + ' ' + last_name AS full_name
FROM customers;

-- With NULL handling
SELECT CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, '')) AS full_name
FROM customers;

-- Formatted: Last, First
SELECT CONCAT(last_name, ', ', first_name) AS full_name
FROM customers;
```

**Common issue:**
```sql
-- ❌ NULL anywhere makes entire result NULL
SELECT first_name + ' ' + last_name  -- NULL if either is NULL

-- ✅ Use CONCAT or COALESCE
SELECT CONCAT(first_name, ' ', last_name)  -- Handles NULLs better
```
</details>

---

### Question 2: String Manipulation (Medium)
Extract and format data from an email address 'john.doe@company.com':
1. Extract username ('john.doe')
2. Extract domain ('company.com')
3. Convert to uppercase
4. Get first letter of username

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    email,
    -- 1. Extract username (before @)
    SUBSTRING(email, 1, POSITION('@' IN email) - 1) AS username,
    -- Or using SUBSTRING_INDEX (MySQL)
    SUBSTRING_INDEX(email, '@', 1) AS username_mysql,
    
    -- 2. Extract domain (after @)
    SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain,
    -- Or
    SUBSTRING_INDEX(email, '@', -1) AS domain_mysql,
    
    -- 3. Convert to uppercase
    UPPER(email) AS email_upper,
    
    -- 4. First letter of username
    LEFT(email, 1) AS first_letter,
    -- Or
    SUBSTRING(email, 1, 1) AS first_letter_alt
FROM customers;
```

**Common String Functions:**

```sql
-- Length
SELECT LENGTH(name), CHAR_LENGTH(name) FROM customers;

-- Case conversion
SELECT 
    UPPER(name) AS uppercase,
    LOWER(name) AS lowercase,
    INITCAP(name) AS proper_case  -- PostgreSQL only
FROM customers;

-- Trimming
SELECT 
    TRIM(name) AS trimmed,
    LTRIM(name) AS left_trim,
    RTRIM(name) AS right_trim,
    TRIM(BOTH ' ' FROM name) AS both_trim
FROM customers;

-- Substring
SELECT 
    SUBSTRING(name, 1, 5) AS first_5_chars,
    LEFT(name, 5) AS left_5,
    RIGHT(name, 5) AS right_5
FROM customers;

-- Replace
SELECT REPLACE(phone, '-', '') AS phone_no_dashes
FROM customers;

-- Padding
SELECT 
    LPAD(customer_id::TEXT, 6, '0') AS padded_id,  -- 000123
    RPAD(name, 20, '.') AS padded_name
FROM customers;
```
</details>

---

## Numeric Functions

### Question 3: Price Calculations (Medium)
Calculate discounted prices with proper rounding and formatting:
- Original price: $19.99
- Discount: 15%
- Round to 2 decimals
- Show as currency

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    product_name,
    price AS original_price,
    
    -- Calculate discount amount
    ROUND(price * 0.15, 2) AS discount_amount,
    
    -- Calculate final price
    ROUND(price * 0.85, 2) AS discounted_price,
    
    -- Format as currency
    CONCAT('$', FORMAT(ROUND(price * 0.85, 2), 2)) AS formatted_price,
    
    -- Percentage saved
    ROUND((price * 0.15) / price * 100, 1) AS percent_saved,
    
    -- Floor and ceiling
    FLOOR(price) AS price_floor,
    CEILING(price) AS price_ceiling
FROM products;
```

**Common Numeric Functions:**

```sql
-- Rounding
SELECT 
    ROUND(123.456, 2) AS rounded,      -- 123.46
    ROUND(123.456, 0) AS rounded_int,  -- 123
    ROUND(123.456, -1) AS rounded_10,  -- 120
    FLOOR(123.456) AS floor_val,       -- 123
    CEILING(123.456) AS ceiling_val,   -- 124
    TRUNCATE(123.456, 2) AS truncated  -- 123.45 (MySQL)
FROM dual;

-- Absolute value and sign
SELECT 
    ABS(-50) AS absolute,  -- 50
    SIGN(-50) AS sign_val, -- -1
    SIGN(50) AS sign_pos,  -- 1
    SIGN(0) AS sign_zero   -- 0
FROM dual;

-- Power and square root
SELECT 
    POWER(2, 10) AS power,      -- 1024
    SQRT(144) AS square_root,   -- 12
    EXP(1) AS e_value,          -- 2.718...
    LN(2.718) AS natural_log    -- 1
FROM dual;

-- Modulo
SELECT 
    MOD(10, 3) AS modulo,       -- 1
    10 % 3 AS modulo_operator   -- 1
FROM dual;
```
</details>

---

## Date and Time Functions

### Question 4: Date Calculations (Medium)
Calculate:
1. Customer's age from birthdate
2. Days since last order
3. Membership duration in years
4. Next anniversary date

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id,
    name,
    birthdate,
    registration_date,
    last_order_date,
    
    -- 1. Age from birthdate
    TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE) AS age,
    -- Or (PostgreSQL)
    DATE_PART('year', AGE(birthdate)) AS age_pg,
    -- Or (SQL Server)
    DATEDIFF(YEAR, birthdate, GETDATE()) AS age_mssql,
    
    -- 2. Days since last order
    DATEDIFF(CURRENT_DATE, last_order_date) AS days_since_order,
    -- Or (PostgreSQL)
    CURRENT_DATE - last_order_date AS days_since_order_pg,
    
    -- 3. Membership duration in years
    TIMESTAMPDIFF(YEAR, registration_date, CURRENT_DATE) AS member_years,
    ROUND(DATEDIFF(CURRENT_DATE, registration_date) / 365.25, 1) AS member_years_decimal,
    
    -- 4. Next anniversary (this year or next year)
    CASE 
        WHEN DATE_FORMAT(registration_date, '%m-%d') >= DATE_FORMAT(CURRENT_DATE, '%m-%d')
        THEN DATE_ADD(registration_date, INTERVAL YEAR(CURRENT_DATE) - YEAR(registration_date) YEAR)
        ELSE DATE_ADD(registration_date, INTERVAL YEAR(CURRENT_DATE) - YEAR(registration_date) + 1 YEAR)
    END AS next_anniversary
FROM customers;
```

**Common Date Functions:**

```sql
-- Current date/time
SELECT 
    CURRENT_DATE AS today,
    CURRENT_TIME AS now_time,
    CURRENT_TIMESTAMP AS now_datetime,
    NOW() AS now_mysql;

-- Extract parts
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    DAY(order_date) AS day,
    DAYOFWEEK(order_date) AS day_of_week,  -- 1=Sunday
    DAYNAME(order_date) AS day_name,
    MONTHNAME(order_date) AS month_name,
    QUARTER(order_date) AS quarter,
    WEEK(order_date) AS week_number
FROM orders;

-- Date arithmetic
SELECT 
    DATE_ADD(order_date, INTERVAL 30 DAY) AS due_date,
    DATE_SUB(order_date, INTERVAL 1 MONTH) AS prev_month,
    order_date + INTERVAL 1 YEAR AS next_year
FROM orders;

-- Date formatting
SELECT 
    DATE_FORMAT(order_date, '%Y-%m-%d') AS iso_format,
    DATE_FORMAT(order_date, '%M %d, %Y') AS friendly,
    DATE_FORMAT(order_date, '%W, %M %e, %Y') AS full
FROM orders;
```
</details>

---

### Question 5: Business Date Logic (Hard)
Find orders that:
- Were placed on a weekday (Monday-Friday)
- Are older than 90 days
- Shipped within 48 hours of order date
- Quarter-end orders (last day of quarter)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    order_id,
    order_date,
    ship_date,
    DAYNAME(order_date) AS day_name,
    DATEDIFF(CURRENT_DATE, order_date) AS days_old,
    DATEDIFF(ship_date, order_date) AS days_to_ship
FROM orders
WHERE 
    -- Weekday (Monday=2, Friday=6 in DAYOFWEEK)
    DAYOFWEEK(order_date) BETWEEN 2 AND 6
    
    -- Older than 90 days
    AND DATEDIFF(CURRENT_DATE, order_date) > 90
    
    -- Shipped within 48 hours
    AND DATEDIFF(ship_date, order_date) <= 2
    
    -- Quarter-end (Mar 31, Jun 30, Sep 30, Dec 31)
    AND (
        (MONTH(order_date) = 3 AND DAY(order_date) = 31) OR
        (MONTH(order_date) = 6 AND DAY(order_date) = 30) OR
        (MONTH(order_date) = 9 AND DAY(order_date) = 30) OR
        (MONTH(order_date) = 12 AND DAY(order_date) = 31)
    );
```

**Alternative quarter-end check:**
```sql
-- Quarter-end: last day of quarter
WHERE order_date = LAST_DAY(order_date)
  AND MONTH(order_date) IN (3, 6, 9, 12)

-- Or using DATE_ADD
WHERE order_date = DATE_SUB(
    DATE_ADD(
        MAKEDATE(YEAR(order_date), 1),
        INTERVAL QUARTER(order_date) QUARTER
    ),
    INTERVAL 1 DAY
)
```
</details>

---

## Type Conversion

### Question 6: CAST and CONVERT (Medium)
Convert data types for calculations and formatting:
- String to number
- Number to string
- Date to string
- String to date

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- String to number
SELECT 
    '123' AS string_val,
    CAST('123' AS UNSIGNED) AS as_integer,
    CAST('123.45' AS DECIMAL(10,2)) AS as_decimal,
    CONVERT('123', UNSIGNED) AS converted_int  -- MySQL
FROM dual;

-- Number to string
SELECT 
    123 AS number_val,
    CAST(123 AS CHAR) AS as_string,
    CONVERT(123, CHAR) AS converted_string,
    LPAD(CAST(123 AS CHAR), 6, '0') AS padded  -- '000123'
FROM dual;

-- Date to string
SELECT 
    order_date,
    CAST(order_date AS CHAR) AS date_string,
    DATE_FORMAT(order_date, '%Y-%m-%d') AS iso_format,
    DATE_FORMAT(order_date, '%M %d, %Y') AS friendly_format
FROM orders;

-- String to date
SELECT 
    '2024-01-15' AS date_string,
    CAST('2024-01-15' AS DATE) AS as_date,
    STR_TO_DATE('01/15/2024', '%m/%d/%Y') AS parsed_date,
    STR_TO_DATE('Jan 15, 2024', '%M %d, %Y') AS parsed_friendly
FROM dual;
```

**Common conversions:**
```sql
-- Implicit conversion (automatic)
SELECT '5' + 10 AS result;  -- 15 (string converted to number)

-- Explicit conversion (recommended)
SELECT CAST('5' AS UNSIGNED) + 10 AS result;  -- 15

-- Handling conversion errors
SELECT 
    CASE 
        WHEN price REGEXP '^[0-9]+(\.[0-9]+)?$' 
        THEN CAST(price AS DECIMAL(10,2))
        ELSE 0
    END AS safe_price
FROM products;
```
</details>

---

## CASE Expressions

### Question 7: Conditional Logic (Medium)
Create customer risk categories based on:
- Credit score
- Number of late payments
- Account age

Categories: Low, Medium, High, Critical

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id,
    name,
    credit_score,
    late_payments,
    DATEDIFF(CURRENT_DATE, registration_date) / 365 AS account_age_years,
    
    -- Simple CASE (testing one column)
    CASE credit_score
        WHEN 800 THEN 'Excellent'
        WHEN 700 THEN 'Good'
        ELSE 'Fair'
    END AS credit_rating,
    
    -- Searched CASE (complex conditions)
    CASE 
        WHEN credit_score >= 750 AND late_payments = 0 
            THEN 'Low Risk'
        WHEN credit_score >= 650 AND late_payments <= 2 
            THEN 'Medium Risk'
        WHEN credit_score >= 550 AND late_payments <= 5 
            THEN 'High Risk'
        ELSE 'Critical Risk'
    END AS risk_category,
    
    -- Multiple conditions
    CASE 
        WHEN credit_score >= 750 
            AND late_payments = 0 
            AND DATEDIFF(CURRENT_DATE, registration_date) > 365
            THEN 'Premium'
        WHEN credit_score >= 650 
            AND late_payments <= 2
            THEN 'Standard'
        WHEN late_payments > 5 
            OR credit_score < 550
            THEN 'Review Required'
        ELSE 'New Customer'
    END AS account_status
FROM customers;
```

**CASE in ORDER BY:**
```sql
SELECT *
FROM customers
ORDER BY 
    CASE risk_category
        WHEN 'Critical Risk' THEN 1
        WHEN 'High Risk' THEN 2
        WHEN 'Medium Risk' THEN 3
        WHEN 'Low Risk' THEN 4
    END;
```

**CASE in aggregate:**
```sql
SELECT 
    COUNT(CASE WHEN credit_score >= 750 THEN 1 END) AS excellent_count,
    COUNT(CASE WHEN credit_score BETWEEN 650 AND 749 THEN 1 END) AS good_count,
    COUNT(CASE WHEN credit_score < 650 THEN 1 END) AS fair_count
FROM customers;
```
</details>

---

### Question 8: Pivot Data with CASE (Hard)
Transform order data from rows to columns:
Show monthly sales for each product category in separate columns.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    
    -- Pivot categories into columns
    SUM(CASE WHEN category = 'Electronics' THEN total_amount ELSE 0 END) AS electronics_sales,
    SUM(CASE WHEN category = 'Clothing' THEN total_amount ELSE 0 END) AS clothing_sales,
    SUM(CASE WHEN category = 'Books' THEN total_amount ELSE 0 END) AS books_sales,
    SUM(CASE WHEN category = 'Home' THEN total_amount ELSE 0 END) AS home_sales,
    
    -- Total
    SUM(total_amount) AS total_sales,
    
    -- Count orders by category
    COUNT(CASE WHEN category = 'Electronics' THEN 1 END) AS electronics_orders,
    COUNT(CASE WHEN category = 'Clothing' THEN 1 END) AS clothing_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE order_date >= '2024-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

**Result:**
```
month   | electronics_sales | clothing_sales | books_sales | home_sales | total_sales
2024-01 | 45000.00         | 12000.00       | 8000.00     | 15000.00   | 80000.00
2024-02 | 52000.00         | 15000.00       | 7500.00     | 18000.00   | 92500.00
```

**Dynamic pivot (generate SQL):**
```sql
-- Get distinct categories first
SELECT DISTINCT category FROM products;

-- Then build query dynamically or use PIVOT (SQL Server)
SELECT *
FROM (
    SELECT month, category, total_amount
    FROM sales_data
) AS source_data
PIVOT (
    SUM(total_amount)
    FOR category IN ([Electronics], [Clothing], [Books], [Home])
) AS pivoted_data;
```
</details>

---

## Complex Transformations

### Question 9: Data Cleansing (Expert)
Clean and standardize customer data:
- Trim whitespace
- Proper case names
- Format phone numbers (###) ###-####
- Validate and fix emails
- Standardize addresses

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id,
    
    -- Clean names (trim, proper case)
    CONCAT(
        UPPER(LEFT(TRIM(first_name), 1)),
        LOWER(SUBSTRING(TRIM(first_name), 2))
    ) AS cleaned_first_name,
    
    CONCAT(
        UPPER(LEFT(TRIM(last_name), 1)),
        LOWER(SUBSTRING(TRIM(last_name), 2))
    ) AS cleaned_last_name,
    
    -- Format phone: (555) 123-4567
    CASE 
        WHEN phone REGEXP '^[0-9]{10}$' THEN
            CONCAT(
                '(',
                SUBSTRING(phone, 1, 3),
                ') ',
                SUBSTRING(phone, 4, 3),
                '-',
                SUBSTRING(phone, 7, 4)
            )
        WHEN phone REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$' THEN
            CONCAT(
                '(',
                SUBSTRING(phone, 1, 3),
                ') ',
                SUBSTRING(phone, 5, 3),
                '-',
                SUBSTRING(phone, 9, 4)
            )
        ELSE phone  -- Keep as is if unrecognized format
    END AS formatted_phone,
    
    -- Validate email
    CASE 
        WHEN LOWER(TRIM(email)) REGEXP '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
        THEN LOWER(TRIM(email))
        ELSE NULL  -- Invalid email
    END AS validated_email,
    
    -- Standardize state (uppercase)
    UPPER(TRIM(state)) AS standardized_state,
    
    -- Remove extra spaces in address
    REGEXP_REPLACE(TRIM(address), '\\s+', ' ') AS cleaned_address,
    
    -- Format ZIP code (5 digits or 5+4)
    CASE 
        WHEN zip REGEXP '^[0-9]{5}$' THEN zip
        WHEN zip REGEXP '^[0-9]{9}$' THEN 
            CONCAT(SUBSTRING(zip, 1, 5), '-', SUBSTRING(zip, 6, 4))
        WHEN zip REGEXP '^[0-9]{5}-[0-9]{4}$' THEN zip
        ELSE LPAD(REGEXP_REPLACE(zip, '[^0-9]', ''), 5, '0')
    END AS formatted_zip
FROM customers;
```

**Create cleaned table:**
```sql
CREATE TABLE customers_cleaned AS
SELECT 
    customer_id,
    -- ... all cleaning transformations ...
FROM customers;

-- Update original table
UPDATE customers c
JOIN customers_cleaned cc ON c.customer_id = cc.customer_id
SET 
    c.first_name = cc.cleaned_first_name,
    c.last_name = cc.cleaned_last_name,
    c.phone = cc.formatted_phone,
    c.email = cc.validated_email;
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 5 questions
- Hard: 2 questions
- Expert: 1 question

**Topics Covered:**
- ✅ String functions (CONCAT, SUBSTRING, UPPER, LOWER, TRIM)
- ✅ Numeric functions (ROUND, FLOOR, CEILING, ABS)
- ✅ Date/time functions (DATE_ADD, DATEDIFF, DATE_FORMAT)
- ✅ Type conversion (CAST, CONVERT)
- ✅ CASE expressions (simple and searched)
- ✅ Data cleansing and standardization
- ✅ Pivoting data with CASE

**Key Takeaways:**
- Use CONCAT for cross-database compatibility
- ROUND for money, FLOOR/CEILING for integers
- Date arithmetic varies by database
- Always CAST explicitly for clarity
- CASE is powerful for conditional logic
- Regular expressions help with validation
- Clean data before analysis

**Next Steps:**
- Chapter 8: Grouping and Aggregates
- Practice data transformation on real datasets
- Build data quality monitoring queries
