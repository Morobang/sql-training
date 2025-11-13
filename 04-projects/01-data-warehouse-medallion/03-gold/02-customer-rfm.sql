-- ========================================
-- Gold: Customer RFM Analysis
-- ========================================
-- Purpose: Recency, Frequency, Monetary segmentation
-- ========================================

USE TechStore_Warehouse;
GO

IF OBJECT_ID('gold.customer_rfm', 'U') IS NOT NULL
    DROP TABLE gold.customer_rfm;
GO

CREATE TABLE gold.customer_rfm (
    customer_key INT PRIMARY KEY,
    customer_id VARCHAR(50),
    customer_name VARCHAR(200),
    
    -- RFM raw values
    recency_days INT,           -- Days since last purchase
    frequency_count INT,        -- Number of purchases
    monetary_value DECIMAL(18,2), -- Total spent
    
    -- RFM scores (1-5, 5 is best)
    recency_score INT,
    frequency_score INT,
    monetary_score INT,
    rfm_score INT,              -- Combined score (sum of 3)
    
    -- Segment based on RFM
    rfm_segment VARCHAR(50),
    
    gold_created_at DATETIME DEFAULT GETDATE()
);
GO

WITH rfm_calc AS (
    SELECT 
        c.customer_key,
        c.customer_id,
        c.full_name,
        
        -- R: Days since last purchase
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS recency_days,
        
        -- F: Number of purchases
        COUNT(DISTINCT o.order_id) AS frequency_count,
        
        -- M: Total spent
        SUM(o.total_amount) AS monetary_value
        
    FROM silver.customers c
    LEFT JOIN silver.orders o ON c.customer_key = o.customer_key
    GROUP BY c.customer_key, c.customer_id, c.full_name
),
rfm_scores AS (
    SELECT 
        *,
        -- Recency score (lower days = better)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        
        -- Frequency score (more purchases = better)
        CASE 
            WHEN frequency_count >= 20 THEN 5
            WHEN frequency_count >= 10 THEN 4
            WHEN frequency_count >= 5 THEN 3
            WHEN frequency_count >= 2 THEN 2
            ELSE 1
        END AS frequency_score,
        
        -- Monetary score (more spent = better)
        CASE 
            WHEN monetary_value >= 5000 THEN 5
            WHEN monetary_value >= 2000 THEN 4
            WHEN monetary_value >= 1000 THEN 3
            WHEN monetary_value >= 500 THEN 2
            ELSE 1
        END AS monetary_score
    FROM rfm_calc
)
INSERT INTO gold.customer_rfm
SELECT 
    customer_key,
    customer_id,
    full_name,
    recency_days,
    frequency_count,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score AS rfm_score,
    
    -- Segment customers
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 4 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
        WHEN monetary_score >= 4 THEN 'Big Spenders'
        ELSE 'Regular'
    END AS rfm_segment,
    
    GETDATE()
FROM rfm_scores;
GO

PRINT 'RFM Analysis complete!';
SELECT rfm_segment, COUNT(*) AS customer_count
FROM gold.customer_rfm
GROUP BY rfm_segment
ORDER BY customer_count DESC;
GO
