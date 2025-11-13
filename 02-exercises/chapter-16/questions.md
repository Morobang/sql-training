# Chapter 16: Analytic Functions (Window Functions) - Practice Questions

## Overview
Master window functions including ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, running totals, moving averages, and advanced partitioning.

---

## Ranking Functions

### Question 1: ROW_NUMBER vs RANK vs DENSE_RANK (Easy)
Explain the differences with examples.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Test data:**
```sql
CREATE TABLE sales (
    sale_id INT,
    salesperson VARCHAR(50),
    amount DECIMAL(10,2)
);

INSERT INTO sales VALUES
(1, 'Alice', 1000),
(2, 'Bob', 1500),
(3, 'Charlie', 1500),  -- Tie
(4, 'Diana', 2000),
(5, 'Eve', 800);
```

**ROW_NUMBER** - Sequential numbering (even with ties)
```sql
SELECT 
    salesperson,
    amount,
    ROW_NUMBER() OVER (ORDER BY amount DESC) AS row_num
FROM sales;

-- Result:
-- Diana    | 2000 | 1
-- Bob      | 1500 | 2
-- Charlie  | 1500 | 3  ← Same amount, different row number
-- Alice    | 1000 | 4
-- Eve      | 800  | 5
```

**RANK** - Gaps after ties
```sql
SELECT 
    salesperson,
    amount,
    RANK() OVER (ORDER BY amount DESC) AS rank_num
FROM sales;

-- Result:
-- Diana    | 2000 | 1
-- Bob      | 1500 | 2
-- Charlie  | 1500 | 2  ← Same rank for tie
-- Alice    | 1000 | 4  ← Gap (skips 3)
-- Eve      | 800  | 5
```

**DENSE_RANK** - No gaps after ties
```sql
SELECT 
    salesperson,
    amount,
    DENSE_RANK() OVER (ORDER BY amount DESC) AS dense_rank_num
FROM sales;

-- Result:
-- Diana    | 2000 | 1
-- Bob      | 1500 | 2
-- Charlie  | 1500 | 2  ← Same rank for tie
-- Alice    | 1000 | 3  ← No gap
-- Eve      | 800  | 4
```

**Comparison:**

| Function | Ties Handled | Gaps After Ties | Use Case |
|----------|--------------|-----------------|----------|
| **ROW_NUMBER()** | Different numbers | N/A | Pagination, unique row IDs |
| **RANK()** | Same rank | Yes (skips) | Olympic-style ranking |
| **DENSE_RANK()** | Same rank | No gaps | Continuous ranking |

**When to use:**
- **ROW_NUMBER**: Pagination (`LIMIT 10 OFFSET 20`), assigning unique IDs
- **RANK**: Competitions, top N with ties
- **DENSE_RANK**: Category rankings, grouping by tiers

</details>

---

### Question 2: Top N Per Group (Medium)
Find top 3 products by sales in each category.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
WITH ranked_products AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(oi.quantity * oi.unit_price) DESC
        ) AS rank_in_category
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
)
SELECT 
    category,
    product_name,
    total_sales,
    rank_in_category
FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;
```

**Alternative with RANK (handles ties):**
```sql
WITH ranked_products AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS total_sales,
        RANK() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(oi.quantity * oi.unit_price) DESC
        ) AS product_rank
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
)
SELECT *
FROM ranked_products
WHERE product_rank <= 3;

-- If two products tie for 3rd, both are included
```

**Multiple ranking criteria:**
```sql
SELECT 
    category,
    product_name,
    units_sold,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY units_sold DESC) AS rank_by_units,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_by_revenue,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY rating DESC) AS rank_by_rating
FROM product_metrics
WHERE rank_by_revenue <= 5;
```

</details>

---

## Aggregate Window Functions

### Question 3: Running Totals and Moving Averages (Hard)
Calculate cumulative sales and 7-day moving average.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Running total (cumulative sum):**
```sql
SELECT 
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    -- Shorthand (same result):
    SUM(daily_sales) OVER (ORDER BY sale_date) AS running_total_short
FROM daily_sales
ORDER BY sale_date;

-- Result:
-- 2024-01-01 | 1000 | 1000
-- 2024-01-02 | 1500 | 2500  (1000 + 1500)
-- 2024-01-03 | 1200 | 3700  (1000 + 1500 + 1200)
```

**Running total by category:**
```sql
SELECT 
    sale_date,
    category,
    daily_sales,
    SUM(daily_sales) OVER (
        PARTITION BY category
        ORDER BY sale_date
    ) AS category_running_total
FROM daily_sales_by_category
ORDER BY category, sale_date;
```

---

**7-day moving average:**
```sql
SELECT 
    sale_date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day,
    -- Include min/max in window
    MIN(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS min_7day,
    MAX(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS max_7day
FROM daily_sales
ORDER BY sale_date;

-- First 6 days have partial windows (< 7 days)
-- From day 7 onwards, full 7-day window
```

---

**Centered moving average (3 days before and after):**
```sql
SELECT 
    sale_date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    ) AS centered_avg_7day
FROM daily_sales;
```

---

**Year-to-date (YTD) running total:**
```sql
SELECT 
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (
        PARTITION BY YEAR(sale_date)
        ORDER BY sale_date
    ) AS ytd_sales,
    -- Month-to-date
    SUM(daily_sales) OVER (
        PARTITION BY YEAR(sale_date), MONTH(sale_date)
        ORDER BY sale_date
    ) AS mtd_sales
FROM daily_sales
ORDER BY sale_date;
```

---

**Percentage of total:**
```sql
SELECT 
    product_name,
    sales,
    SUM(sales) OVER () AS total_sales,
    ROUND(sales * 100.0 / SUM(sales) OVER (), 2) AS pct_of_total,
    -- Running percentage
    ROUND(
        SUM(sales) OVER (ORDER BY sales DESC) * 100.0 / SUM(sales) OVER (),
        2
    ) AS cumulative_pct
FROM product_sales
ORDER BY sales DESC;

-- Identify products that make up 80% of sales (Pareto principle)
```

---

**Window frame types:**

| Frame Type | Syntax | Description |
|------------|--------|-------------|
| **ROWS** | `ROWS BETWEEN ... AND ...` | Physical rows |
| **RANGE** | `RANGE BETWEEN ... AND ...` | Logical range (values) |

```sql
-- ROWS: Count 3 physical rows
SELECT 
    sale_date,
    amount,
    SUM(amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sum_last_3_rows
FROM sales;

-- RANGE: Sum all rows with same date ± 1 day
SELECT 
    sale_date,
    amount,
    SUM(amount) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL 1 DAY PRECEDING 
                  AND INTERVAL 1 DAY FOLLOWING
    ) AS sum_3_days
FROM sales;
```

</details>

---

## Offset Functions

### Question 4: LAG and LEAD for Comparisons (Medium)
Compare current row with previous/next rows.

<details>
<summary>Click to see answer</summary>

**Answer:**

**LAG - Access previous row:**
```sql
SELECT 
    sale_date,
    daily_sales,
    LAG(daily_sales, 1) OVER (ORDER BY sale_date) AS previous_day_sales,
    daily_sales - LAG(daily_sales, 1) OVER (ORDER BY sale_date) AS day_over_day_change,
    ROUND(
        (daily_sales - LAG(daily_sales, 1) OVER (ORDER BY sale_date)) * 100.0 / 
        LAG(daily_sales, 1) OVER (ORDER BY sale_date),
        2
    ) AS pct_change
FROM daily_sales
ORDER BY sale_date;

-- Result:
-- 2024-01-01 | 1000 | NULL | NULL  | NULL    (first row, no previous)
-- 2024-01-02 | 1500 | 1000 | 500   | 50.00
-- 2024-01-03 | 1200 | 1500 | -300  | -20.00
```

**LEAD - Access next row:**
```sql
SELECT 
    sale_date,
    daily_sales,
    LEAD(daily_sales, 1) OVER (ORDER BY sale_date) AS next_day_sales,
    LEAD(sale_date, 1) OVER (ORDER BY sale_date) AS next_sale_date
FROM daily_sales
ORDER BY sale_date;
```

---

**Compare with same day last week:**
```sql
SELECT 
    sale_date,
    daily_sales,
    LAG(daily_sales, 7) OVER (ORDER BY sale_date) AS same_day_last_week,
    daily_sales - LAG(daily_sales, 7) OVER (ORDER BY sale_date) AS week_over_week_change
FROM daily_sales
ORDER BY sale_date;
```

---

**Year-over-year comparison:**
```sql
SELECT 
    sale_date,
    daily_sales,
    LAG(daily_sales, 365) OVER (ORDER BY sale_date) AS same_day_last_year,
    ROUND(
        (daily_sales - LAG(daily_sales, 365) OVER (ORDER BY sale_date)) * 100.0 /
        LAG(daily_sales, 365) OVER (ORDER BY sale_date),
        2
    ) AS yoy_growth_pct
FROM daily_sales
ORDER BY sale_date;
```

---

**First and last values in partition:**
```sql
SELECT 
    product_id,
    sale_date,
    price,
    FIRST_VALUE(price) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS starting_price,
    LAST_VALUE(price) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ending_price,
    -- Price change since start
    price - FIRST_VALUE(price) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS price_change_from_start
FROM product_price_history
ORDER BY product_id, sale_date;
```

---

**Identify gaps in sequences:**
```sql
SELECT 
    order_id,
    order_date,
    LAG(order_date) OVER (ORDER BY order_date) AS prev_order_date,
    DATEDIFF(order_date, LAG(order_date) OVER (ORDER BY order_date)) AS days_since_last_order,
    CASE 
        WHEN DATEDIFF(order_date, LAG(order_date) OVER (ORDER BY order_date)) > 7
        THEN 'Gap detected'
        ELSE 'Normal'
    END AS gap_status
FROM orders
WHERE customer_id = 123
ORDER BY order_date;
```

---

**Forward-fill NULL values:**
```sql
SELECT 
    measurement_date,
    temperature,
    -- Use last non-NULL value if current is NULL
    COALESCE(
        temperature,
        LAG(temperature, 1) OVER (ORDER BY measurement_date),
        LAG(temperature, 2) OVER (ORDER BY measurement_date),
        LAG(temperature, 3) OVER (ORDER BY measurement_date)
    ) AS temperature_filled
FROM weather_data
ORDER BY measurement_date;
```

</details>

---

## Advanced Window Functions

### Question 5: NTILE for Quartiles and Percentiles (Medium)
Divide data into equal buckets.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Quartiles (4 buckets):**
```sql
SELECT 
    customer_id,
    lifetime_value,
    NTILE(4) OVER (ORDER BY lifetime_value DESC) AS quartile,
    CASE NTILE(4) OVER (ORDER BY lifetime_value DESC)
        WHEN 1 THEN 'Top 25% (VIP)'
        WHEN 2 THEN 'High Value'
        WHEN 3 THEN 'Medium Value'
        WHEN 4 THEN 'Low Value'
    END AS customer_segment
FROM customers
ORDER BY lifetime_value DESC;

-- Divides customers into 4 equal groups by value
```

**Deciles (10 buckets):**
```sql
SELECT 
    product_id,
    price,
    NTILE(10) OVER (ORDER BY price) AS price_decile
FROM products;

-- Decile 1 = cheapest 10%
-- Decile 10 = most expensive 10%
```

---

**RFM Analysis (Recency, Frequency, Monetary):**
```sql
WITH customer_metrics AS (
    SELECT 
        customer_id,
        DATEDIFF(CURDATE(), MAX(order_date)) AS recency_days,
        COUNT(*) AS frequency,
        SUM(total_amount) AS monetary
    FROM orders
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- Score 1-5 (quintiles)
        6 - NTILE(5) OVER (ORDER BY recency_days) AS recency_score,        -- Recent = high score
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,             -- More orders = high
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score               -- More spent = high
    FROM customer_metrics
)
SELECT 
    customer_id,
    recency_days,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_code,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
        ELSE 'Regular'
    END AS customer_segment
FROM rfm_scores
ORDER BY recency_score DESC, frequency_score DESC, monetary_score DESC;
```

---

**Percentile calculation:**
```sql
-- Find 90th percentile of order values
WITH percentiles AS (
    SELECT 
        total_amount,
        NTILE(100) OVER (ORDER BY total_amount) AS percentile
    FROM orders
)
SELECT 
    MIN(total_amount) AS p90_threshold
FROM percentiles
WHERE percentile = 90;

-- Or use PERCENT_RANK:
SELECT 
    total_amount,
    PERCENT_RANK() OVER (ORDER BY total_amount) AS pct_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_amount) * 100, 2) AS percentile
FROM orders
ORDER BY total_amount DESC;
```

</details>

---

## Real-World Scenario

### Question 6: Sales Dashboard with Multiple Metrics (Expert)
Create a comprehensive sales analytics query.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
WITH daily_sales AS (
    SELECT 
        DATE(order_date) AS sale_date,
        COUNT(*) AS order_count,
        SUM(total_amount) AS daily_revenue,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(total_amount) AS avg_order_value
    FROM orders
    WHERE order_date >= CURDATE() - INTERVAL 365 DAY
    GROUP BY DATE(order_date)
),
sales_analytics AS (
    SELECT 
        sale_date,
        daily_revenue,
        order_count,
        unique_customers,
        avg_order_value,
        
        -- Running totals
        SUM(daily_revenue) OVER (
            PARTITION BY YEAR(sale_date)
            ORDER BY sale_date
        ) AS ytd_revenue,
        
        SUM(daily_revenue) OVER (
            PARTITION BY YEAR(sale_date), MONTH(sale_date)
            ORDER BY sale_date
        ) AS mtd_revenue,
        
        -- Moving averages
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ma_7day,
        
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS ma_30day,
        
        -- Comparisons
        LAG(daily_revenue, 1) OVER (ORDER BY sale_date) AS prev_day_revenue,
        LAG(daily_revenue, 7) OVER (ORDER BY sale_date) AS same_day_last_week,
        LAG(daily_revenue, 365) OVER (ORDER BY sale_date) AS same_day_last_year,
        
        -- Rankings
        RANK() OVER (
            PARTITION BY YEAR(sale_date), MONTH(sale_date)
            ORDER BY daily_revenue DESC
        ) AS rank_in_month,
        
        -- Percentiles
        NTILE(4) OVER (ORDER BY daily_revenue) AS revenue_quartile,
        
        -- Min/Max in window
        MAX(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS max_30day,
        
        MIN(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS min_30day
    FROM daily_sales
)
SELECT 
    sale_date,
    daily_revenue,
    order_count,
    unique_customers,
    avg_order_value,
    ytd_revenue,
    mtd_revenue,
    ma_7day,
    ma_30day,
    
    -- Growth calculations
    ROUND((daily_revenue - prev_day_revenue) * 100.0 / NULLIF(prev_day_revenue, 0), 2) AS day_over_day_pct,
    ROUND((daily_revenue - same_day_last_week) * 100.0 / NULLIF(same_day_last_week, 0), 2) AS week_over_week_pct,
    ROUND((daily_revenue - same_day_last_year) * 100.0 / NULLIF(same_day_last_year, 0), 2) AS year_over_year_pct,
    
    -- Performance indicators
    rank_in_month,
    CASE 
        WHEN rank_in_month = 1 THEN '🏆 Best Day'
        WHEN rank_in_month <= 3 THEN '⭐ Top 3'
        WHEN daily_revenue > ma_30day THEN '📈 Above Average'
        ELSE '📉 Below Average'
    END AS performance_flag,
    
    -- Trend indicators
    CASE 
        WHEN daily_revenue > ma_7day AND ma_7day > ma_30day THEN 'Strong Uptrend'
        WHEN daily_revenue > ma_7day THEN 'Uptrend'
        WHEN daily_revenue < ma_7day AND ma_7day < ma_30day THEN 'Strong Downtrend'
        WHEN daily_revenue < ma_7day THEN 'Downtrend'
        ELSE 'Flat'
    END AS trend,
    
    revenue_quartile,
    max_30day,
    min_30day
FROM sales_analytics
ORDER BY sale_date DESC
LIMIT 90;
```

**Export for visualization:**
```sql
-- Simplified for charting
SELECT 
    sale_date,
    daily_revenue,
    AVG(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7,
    AVG(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30,
    SUM(daily_revenue) OVER (PARTITION BY YEAR(sale_date) ORDER BY sale_date) AS ytd
FROM daily_sales
WHERE sale_date >= CURDATE() - INTERVAL 90 DAY
ORDER BY sale_date;
```

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 3 questions
- Hard: 1 question
- Expert: 1 question

**Topics Covered:**
- ✅ ROW_NUMBER, RANK, DENSE_RANK
- ✅ Top N per group with PARTITION BY
- ✅ Running totals and moving averages
- ✅ LAG, LEAD for time comparisons
- ✅ NTILE for segmentation
- ✅ Complex analytics dashboard

**Key Takeaways:**
- Window functions don't reduce rows (unlike GROUP BY)
- PARTITION BY creates separate windows
- Frame clauses control window scope
- Use LAG/LEAD for time-series analysis
- NTILE for equal-sized buckets

**Next Steps:**
- Chapter 17: Working with Large Databases
- Practice combining multiple window functions
