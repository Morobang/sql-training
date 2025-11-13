# Chapter 11: Conditional Logic - Practice Questions

## Overview
Master CASE expressions, searched CASE, NULL handling functions, conditional aggregates, and IIF/DECODE functions.

---

## CASE Expression Fundamentals

### Question 1: Simple vs Searched CASE (Easy)
What's the difference between simple CASE and searched CASE?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Simple CASE**: Tests one expression against multiple values
```sql
SELECT 
    product_name,
    price,
    CASE category
        WHEN 'Electronics' THEN 'Tech'
        WHEN 'Clothing' THEN 'Apparel'
        WHEN 'Books' THEN 'Media'
        ELSE 'Other'
    END AS category_group
FROM products;
```

**Searched CASE**: Evaluates multiple independent conditions
```sql
SELECT 
    product_name,
    price,
    CASE 
        WHEN price < 10 THEN 'Budget'
        WHEN price BETWEEN 10 AND 100 THEN 'Standard'
        WHEN price BETWEEN 100 AND 500 THEN 'Premium'
        WHEN price > 500 THEN 'Luxury'
        ELSE 'Unknown'
    END AS price_tier
FROM products;
```

**Key differences:**
| Feature | Simple CASE | Searched CASE |
|---------|-------------|---------------|
| Syntax | Tests one column | Tests multiple conditions |
| Flexibility | Limited | Very flexible |
| Use case | Mapping values | Complex logic |
| Example | Status codes | Range checks |

**When to use:**
- **Simple CASE**: Status mapping, category grouping
- **Searched CASE**: Complex conditions, ranges, multiple columns
</details>

---

### Question 2: CASE in Different Clauses (Medium)
Show examples of CASE in SELECT, WHERE, ORDER BY, and GROUP BY.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- In SELECT clause
SELECT 
    customer_id,
    name,
    CASE 
        WHEN total_orders > 100 THEN 'VIP'
        WHEN total_orders > 50 THEN 'Premium'
        WHEN total_orders > 10 THEN 'Regular'
        ELSE 'New'
    END AS customer_tier
FROM customers;

-- In WHERE clause
SELECT *
FROM orders
WHERE CASE 
    WHEN customer_type = 'VIP' THEN total_amount > 100
    WHEN customer_type = 'Regular' THEN total_amount > 500
    ELSE total_amount > 1000
END;

-- In ORDER BY clause
SELECT 
    customer_id,
    name,
    status
FROM customers
ORDER BY 
    CASE status
        WHEN 'VIP' THEN 1
        WHEN 'Premium' THEN 2
        WHEN 'Regular' THEN 3
        ELSE 4
    END,
    name;

-- In GROUP BY clause
SELECT 
    CASE 
        WHEN age < 18 THEN 'Minor'
        WHEN age BETWEEN 18 AND 30 THEN 'Young Adult'
        WHEN age BETWEEN 31 AND 50 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spending
FROM customers
GROUP BY 
    CASE 
        WHEN age < 18 THEN 'Minor'
        WHEN age BETWEEN 18 AND 30 THEN 'Young Adult'
        WHEN age BETWEEN 31 AND 50 THEN 'Adult'
        ELSE 'Senior'
    END;

-- In HAVING clause
SELECT 
    category,
    AVG(price) AS avg_price
FROM products
GROUP BY category
HAVING CASE 
    WHEN category = 'Electronics' THEN AVG(price) > 500
    WHEN category = 'Clothing' THEN AVG(price) > 50
    ELSE AVG(price) > 20
END;
```
</details>

---

## Conditional Aggregates

### Question 3: Filtered Aggregates with CASE (Medium)
Calculate different metrics for different segments in a single query.

Create a sales report showing:
- Total revenue
- New customer revenue (first order)
- Repeat customer revenue
- High-value orders (>$1000)
- Count by order status

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    
    -- Total metrics
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    
    -- New vs Repeat customers
    COUNT(CASE WHEN is_first_order = 1 THEN 1 END) AS new_customer_orders,
    SUM(CASE WHEN is_first_order = 1 THEN total_amount END) AS new_customer_revenue,
    COUNT(CASE WHEN is_first_order = 0 THEN 1 END) AS repeat_orders,
    SUM(CASE WHEN is_first_order = 0 THEN total_amount END) AS repeat_revenue,
    
    -- High value orders
    COUNT(CASE WHEN total_amount > 1000 THEN 1 END) AS high_value_count,
    SUM(CASE WHEN total_amount > 1000 THEN total_amount END) AS high_value_revenue,
    
    -- By status
    COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_count,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending_count,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_count,
    
    -- Revenue by status
    SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END) AS completed_revenue,
    SUM(CASE WHEN status = 'cancelled' THEN total_amount ELSE 0 END) AS lost_revenue,
    
    -- Percentages
    ROUND(
        SUM(CASE WHEN is_first_order = 1 THEN total_amount END) * 100.0 / SUM(total_amount),
        2
    ) AS new_customer_pct,
    
    ROUND(
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM orders
WHERE order_date >= '2024-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month DESC;
```

**PostgreSQL alternative with FILTER:**
```sql
SELECT 
    month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_first_order = 1) AS new_customer_orders,
    SUM(total_amount) FILTER (WHERE is_first_order = 1) AS new_customer_revenue,
    SUM(total_amount) FILTER (WHERE total_amount > 1000) AS high_value_revenue
FROM orders
GROUP BY month;
```
</details>

---

### Question 4: Pivot with CASE (Hard)
Transform rows into columns using CASE expressions.

Convert this:
```
product | month    | sales
Laptop  | Jan 2024 | 50000
Laptop  | Feb 2024 | 60000
Mouse   | Jan 2024 | 5000
```

Into:
```
product | jan_sales | feb_sales | mar_sales
Laptop  | 50000     | 60000     | 70000
Mouse   | 5000      | 6000      | 7000
```

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    product_name,
    
    -- Pivot months into columns
    SUM(CASE WHEN MONTH(sale_date) = 1 THEN sales_amount ELSE 0 END) AS jan_sales,
    SUM(CASE WHEN MONTH(sale_date) = 2 THEN sales_amount ELSE 0 END) AS feb_sales,
    SUM(CASE WHEN MONTH(sale_date) = 3 THEN sales_amount ELSE 0 END) AS mar_sales,
    SUM(CASE WHEN MONTH(sale_date) = 4 THEN sales_amount ELSE 0 END) AS apr_sales,
    SUM(CASE WHEN MONTH(sale_date) = 5 THEN sales_amount ELSE 0 END) AS may_sales,
    SUM(CASE WHEN MONTH(sale_date) = 6 THEN sales_amount ELSE 0 END) AS jun_sales,
    
    -- Quarters
    SUM(CASE WHEN QUARTER(sale_date) = 1 THEN sales_amount ELSE 0 END) AS q1_sales,
    SUM(CASE WHEN QUARTER(sale_date) = 2 THEN sales_amount ELSE 0 END) AS q2_sales,
    
    -- Total
    SUM(sales_amount) AS total_sales
FROM sales
WHERE YEAR(sale_date) = 2024
GROUP BY product_name
ORDER BY total_sales DESC;
```

**Multi-dimensional pivot (category by month):**
```sql
SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    SUM(CASE WHEN category = 'Electronics' THEN sales_amount ELSE 0 END) AS electronics,
    SUM(CASE WHEN category = 'Clothing' THEN sales_amount ELSE 0 END) AS clothing,
    SUM(CASE WHEN category = 'Books' THEN sales_amount ELSE 0 END) AS books,
    SUM(CASE WHEN category = 'Home' THEN sales_amount ELSE 0 END) AS home,
    SUM(sales_amount) AS total
FROM sales
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
ORDER BY month;
```

**SQL Server PIVOT operator:**
```sql
SELECT *
FROM (
    SELECT product_name, MONTH(sale_date) AS month, sales_amount
    FROM sales
    WHERE YEAR(sale_date) = 2024
) AS source_data
PIVOT (
    SUM(sales_amount)
    FOR month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS pivoted_data;
```
</details>

---

## NULL Handling

### Question 5: COALESCE vs IFNULL vs ISNULL (Medium)
Explain the differences and when to use each function.

<details>
<summary>Click to see answer</summary>

**Answer:**

**COALESCE**: ANSI standard, accepts multiple arguments
```sql
-- Returns first non-NULL value
SELECT 
    customer_id,
    COALESCE(mobile_phone, home_phone, work_phone, 'No phone') AS contact_phone,
    COALESCE(email, 'no-email@example.com') AS contact_email
FROM customers;
```

**IFNULL**: MySQL, 2 arguments only
```sql
-- MySQL specific
SELECT 
    product_name,
    IFNULL(discount_price, regular_price) AS selling_price,
    IFNULL(stock_quantity, 0) AS available_stock
FROM products;
```

**ISNULL**: SQL Server, 2 arguments only
```sql
-- SQL Server specific
SELECT 
    customer_name,
    ISNULL(phone, 'Not provided') AS phone_number,
    ISNULL(total_orders, 0) AS order_count
FROM customers;
```

**Comparison:**

| Function | Database | Arguments | Standard |
|----------|----------|-----------|----------|
| COALESCE | All | Unlimited | ANSI SQL |
| IFNULL | MySQL | 2 | MySQL only |
| ISNULL | SQL Server | 2 | T-SQL only |
| NVL | Oracle | 2 | Oracle only |

**Best practice: Use COALESCE for portability**

**Advanced COALESCE usage:**
```sql
-- Multiple fallbacks
SELECT 
    COALESCE(
        preferred_shipping_address,
        billing_address,
        registration_address,
        'Address not provided'
    ) AS shipping_address
FROM customers;

-- With calculations
SELECT 
    product_name,
    price,
    discount,
    price - COALESCE(discount, 0) AS final_price,
    ROUND((COALESCE(discount, 0) / price) * 100, 2) AS discount_pct
FROM products;
```

**NULLIF (opposite of COALESCE):**
```sql
-- Returns NULL if values are equal
SELECT 
    NULLIF(current_price, original_price) AS price_change
FROM products;
-- Returns NULL if prices are the same, otherwise current_price
```
</details>

---

## Complex Conditional Logic

### Question 6: Nested CASE Statements (Hard)
Create a customer risk score based on multiple factors:
- Credit score
- Payment history
- Account age
- Order frequency

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id,
    name,
    credit_score,
    late_payments,
    account_age_days,
    orders_last_90_days,
    
    -- Risk scoring with nested CASE
    CASE 
        -- Excellent credit
        WHEN credit_score >= 750 THEN
            CASE 
                WHEN late_payments = 0 AND orders_last_90_days >= 3 THEN 'A+ (Best)'
                WHEN late_payments = 0 THEN 'A (Excellent)'
                WHEN late_payments <= 1 THEN 'A- (Very Good)'
                ELSE 'B+ (Good)'
            END
        
        -- Good credit
        WHEN credit_score >= 650 THEN
            CASE 
                WHEN late_payments = 0 AND account_age_days > 365 THEN 'B (Good)'
                WHEN late_payments <= 2 THEN 'B- (Fair)'
                ELSE 'C+ (Below Average)'
            END
        
        -- Fair credit
        WHEN credit_score >= 550 THEN
            CASE 
                WHEN late_payments <= 3 AND account_age_days > 180 THEN 'C (Acceptable)'
                ELSE 'C- (Marginal)'
            END
        
        -- Poor credit
        ELSE
            CASE 
                WHEN late_payments > 5 THEN 'D (High Risk)'
                WHEN account_age_days < 90 THEN 'D (New - High Risk)'
                ELSE 'D- (Very High Risk)'
            END
    END AS risk_rating,
    
    -- Numeric risk score (0-100)
    CASE 
        WHEN credit_score >= 750 THEN 90
        WHEN credit_score >= 650 THEN 75
        WHEN credit_score >= 550 THEN 50
        ELSE 25
    END
    + CASE 
        WHEN late_payments = 0 THEN 10
        WHEN late_payments <= 2 THEN 5
        ELSE 0
    END
    + CASE 
        WHEN account_age_days > 365 THEN 10
        WHEN account_age_days > 180 THEN 5
        ELSE 0
    END
    - (late_payments * 5) AS risk_score,
    
    -- Credit limit recommendation
    CASE 
        WHEN credit_score >= 750 AND late_payments = 0 THEN 10000
        WHEN credit_score >= 700 AND late_payments <= 1 THEN 5000
        WHEN credit_score >= 650 AND late_payments <= 2 THEN 2500
        WHEN credit_score >= 600 AND late_payments <= 3 THEN 1000
        ELSE 500
    END AS recommended_credit_limit
FROM customer_metrics;
```

**Refactored with CTEs for clarity:**
```sql
WITH risk_factors AS (
    SELECT 
        customer_id,
        name,
        credit_score,
        late_payments,
        account_age_days,
        -- Base score components
        CASE 
            WHEN credit_score >= 750 THEN 90
            WHEN credit_score >= 650 THEN 75
            WHEN credit_score >= 550 THEN 50
            ELSE 25
        END AS credit_score_points,
        
        CASE 
            WHEN late_payments = 0 THEN 10
            WHEN late_payments <= 2 THEN 5
            ELSE -late_payments * 2
        END AS payment_points,
        
        CASE 
            WHEN account_age_days > 365 THEN 10
            WHEN account_age_days > 180 THEN 5
            ELSE 0
        END AS tenure_points
    FROM customers
)
SELECT 
    *,
    credit_score_points + payment_points + tenure_points AS total_risk_score,
    CASE 
        WHEN credit_score_points + payment_points + tenure_points >= 90 THEN 'A'
        WHEN credit_score_points + payment_points + tenure_points >= 75 THEN 'B'
        WHEN credit_score_points + payment_points + tenure_points >= 50 THEN 'C'
        ELSE 'D'
    END AS risk_grade
FROM risk_factors;
```
</details>

---

## IIF and DECODE

### Question 7: IIF Function (Easy)
What is IIF and how does it differ from CASE?

<details>
<summary>Click to see answer</summary>

**Answer: IIF is a shorthand for simple IF-THEN-ELSE logic (SQL Server, Access)**

**IIF syntax:**
```sql
-- SQL Server 2012+
SELECT 
    product_name,
    price,
    IIF(price > 100, 'Expensive', 'Affordable') AS price_category,
    IIF(stock_quantity > 0, 'In Stock', 'Out of Stock') AS availability
FROM products;
```

**Equivalent CASE:**
```sql
SELECT 
    product_name,
    price,
    CASE WHEN price > 100 THEN 'Expensive' ELSE 'Affordable' END AS price_category,
    CASE WHEN stock_quantity > 0 THEN 'In Stock' ELSE 'Out of Stock' END AS availability
FROM products;
```

**Nested IIF:**
```sql
-- Nested (gets messy quickly)
SELECT 
    customer_name,
    IIF(
        orders_count > 100, 
        'VIP',
        IIF(orders_count > 50, 'Premium', 'Regular')
    ) AS tier
FROM customers;

-- Better: Use CASE for multiple conditions
SELECT 
    customer_name,
    CASE 
        WHEN orders_count > 100 THEN 'VIP'
        WHEN orders_count > 50 THEN 'Premium'
        ELSE 'Regular'
    END AS tier
FROM customers;
```

**When to use:**
- **IIF**: Simple binary conditions (yes/no, true/false)
- **CASE**: Multiple conditions, complex logic

**DECODE (Oracle):**
```sql
-- Oracle equivalent
SELECT 
    customer_name,
    DECODE(status,
        'A', 'Active',
        'I', 'Inactive',
        'P', 'Pending',
        'Unknown') AS status_desc
FROM customers;
```
</details>

---

## Real-World Scenarios

### Question 8: Dynamic Pricing Logic (Expert)
Implement complex pricing rules based on:
- Customer tier
- Order quantity
- Product category
- Seasonal promotions
- Loyalty program

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
WITH customer_tiers AS (
    SELECT 
        customer_id,
        CASE 
            WHEN lifetime_value > 10000 THEN 'Diamond'
            WHEN lifetime_value > 5000 THEN 'Platinum'
            WHEN lifetime_value > 1000 THEN 'Gold'
            ELSE 'Silver'
        END AS tier
    FROM customer_metrics
),
pricing_rules AS (
    SELECT 
        oi.order_item_id,
        oi.product_id,
        p.product_name,
        p.category,
        p.base_price,
        oi.quantity,
        o.customer_id,
        ct.tier AS customer_tier,
        o.order_date,
        
        -- Base discount by customer tier
        CASE ct.tier
            WHEN 'Diamond' THEN 0.20
            WHEN 'Platinum' THEN 0.15
            WHEN 'Gold' THEN 0.10
            WHEN 'Silver' THEN 0.05
        END AS tier_discount,
        
        -- Quantity discount
        CASE 
            WHEN oi.quantity >= 100 THEN 0.15
            WHEN oi.quantity >= 50 THEN 0.10
            WHEN oi.quantity >= 20 THEN 0.07
            WHEN oi.quantity >= 10 THEN 0.05
            ELSE 0.00
        END AS quantity_discount,
        
        -- Category discount
        CASE p.category
            WHEN 'Clearance' THEN 0.30
            WHEN 'Seasonal' THEN 0.20
            WHEN 'Promotional' THEN 0.15
            ELSE 0.00
        END AS category_discount,
        
        -- Seasonal promotion
        CASE 
            WHEN MONTH(o.order_date) IN (11, 12) THEN 0.10  -- Black Friday/Christmas
            WHEN MONTH(o.order_date) = 7 THEN 0.05          -- Summer sale
            ELSE 0.00
        END AS seasonal_discount,
        
        -- Loyalty bonus (orders in last 30 days)
        CASE 
            WHEN (SELECT COUNT(*) FROM orders o2 
                  WHERE o2.customer_id = o.customer_id 
                  AND o2.order_date >= DATE_SUB(o.order_date, INTERVAL 30 DAY)) >= 3 
            THEN 0.05
            ELSE 0.00
        END AS loyalty_discount
        
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN customer_tiers ct ON o.customer_id = ct.customer_id
)
SELECT 
    order_item_id,
    product_name,
    category,
    quantity,
    customer_tier,
    base_price,
    
    -- Calculate total discount (max 40%)
    LEAST(
        tier_discount + quantity_discount + category_discount + 
        seasonal_discount + loyalty_discount,
        0.40
    ) AS total_discount_pct,
    
    -- Apply discount
    base_price * (1 - LEAST(
        tier_discount + quantity_discount + category_discount + 
        seasonal_discount + loyalty_discount,
        0.40
    )) AS unit_price_after_discount,
    
    -- Line total
    quantity * base_price * (1 - LEAST(
        tier_discount + quantity_discount + category_discount + 
        seasonal_discount + loyalty_discount,
        0.40
    )) AS line_total,
    
    -- Discount breakdown
    CONCAT(
        'Tier: ', ROUND(tier_discount * 100, 0), '% | ',
        'Qty: ', ROUND(quantity_discount * 100, 0), '% | ',
        'Category: ', ROUND(category_discount * 100, 0), '% | ',
        'Seasonal: ', ROUND(seasonal_discount * 100, 0), '% | ',
        'Loyalty: ', ROUND(loyalty_discount * 100, 0), '%'
    ) AS discount_breakdown
FROM pricing_rules
ORDER BY line_total DESC;
```

**Simplified stored procedure version:**
```sql
DELIMITER $$
CREATE FUNCTION calculate_discount(
    p_customer_tier VARCHAR(20),
    p_quantity INT,
    p_category VARCHAR(50),
    p_order_month INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
    DECLARE v_tier_discount DECIMAL(5,4);
    DECLARE v_qty_discount DECIMAL(5,4);
    DECLARE v_cat_discount DECIMAL(5,4);
    DECLARE v_season_discount DECIMAL(5,4);
    DECLARE v_total_discount DECIMAL(5,4);
    
    -- Tier discount
    SET v_tier_discount = CASE p_customer_tier
        WHEN 'Diamond' THEN 0.20
        WHEN 'Platinum' THEN 0.15
        WHEN 'Gold' THEN 0.10
        ELSE 0.05
    END;
    
    -- Quantity discount
    SET v_qty_discount = CASE 
        WHEN p_quantity >= 100 THEN 0.15
        WHEN p_quantity >= 50 THEN 0.10
        WHEN p_quantity >= 20 THEN 0.07
        WHEN p_quantity >= 10 THEN 0.05
        ELSE 0.00
    END;
    
    -- Category discount
    SET v_cat_discount = CASE p_category
        WHEN 'Clearance' THEN 0.30
        WHEN 'Seasonal' THEN 0.20
        ELSE 0.00
    END;
    
    -- Seasonal discount
    SET v_season_discount = CASE 
        WHEN p_order_month IN (11, 12) THEN 0.10
        WHEN p_order_month = 7 THEN 0.05
        ELSE 0.00
    END;
    
    -- Total (max 40%)
    SET v_total_discount = LEAST(
        v_tier_discount + v_qty_discount + v_cat_discount + v_season_discount,
        0.40
    );
    
    RETURN v_total_discount;
END$$
DELIMITER ;

-- Usage
SELECT 
    product_name,
    calculate_discount(tier, quantity, category, MONTH(order_date)) AS discount
FROM order_items;
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 2 questions
- Medium: 3 questions
- Hard: 2 questions
- Expert: 1 question

**Topics Covered:**
- ✅ Simple vs Searched CASE
- ✅ CASE in all clauses (SELECT, WHERE, ORDER BY, GROUP BY, HAVING)
- ✅ Conditional aggregates
- ✅ Pivoting data with CASE
- ✅ NULL handling (COALESCE, IFNULL, ISNULL, NULLIF)
- ✅ Nested CASE statements
- ✅ IIF and DECODE functions
- ✅ Complex business logic implementation

**Key Takeaways:**
- Simple CASE for value mapping
- Searched CASE for complex conditions
- Use COALESCE for portability
- Conditional aggregates avoid multiple queries
- CASE can pivot rows to columns
- Nested CASE gets hard to read - use CTEs
- IIF for simple binary logic only
- Always include ELSE for completeness

**Next Steps:**
- Chapter 12: Transactions
- Practice building complex pricing rules
- Implement customer segmentation logic
