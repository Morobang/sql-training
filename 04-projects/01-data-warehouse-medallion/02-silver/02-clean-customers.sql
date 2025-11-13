-- ========================================
-- Clean and Load Silver Customers
-- ========================================
-- Purpose: Transform bronze customers into clean silver data
-- ========================================

USE TechStore_Warehouse;
GO

PRINT 'Cleaning customer data from bronze to silver...';

-- ========================================
-- Clean Customers with CTE
-- ========================================

WITH cleaned_customers AS (
    SELECT 
        customer_id,
        full_name,
        
        -- Parse first and last name
        CASE 
            -- "Last, First" format
            WHEN full_name LIKE '%, %' THEN LTRIM(RTRIM(SUBSTRING(full_name, CHARINDEX(',', full_name) + 1, LEN(full_name))))
            -- "First Last" format
            WHEN full_name LIKE '% %' THEN LTRIM(RTRIM(LEFT(full_name, CHARINDEX(' ', full_name) - 1)))
            -- Single name only
            ELSE full_name
        END AS first_name,
        
        CASE 
            -- "Last, First" format
            WHEN full_name LIKE '%, %' THEN LTRIM(RTRIM(LEFT(full_name, CHARINDEX(',', full_name) - 1)))
            -- "First Last" format
            WHEN full_name LIKE '% %' THEN LTRIM(RTRIM(SUBSTRING(full_name, CHARINDEX(' ', full_name) + 1, LEN(full_name))))
            -- Single name only (use as last name)
            ELSE full_name
        END AS last_name,
        
        -- Validate and clean email
        CASE 
            WHEN email LIKE '%@%.%' THEN LOWER(LTRIM(RTRIM(email)))
            ELSE NULL
        END AS email_clean,
        
        -- Standardize phone to (555) 555-5555 format
        CASE 
            WHEN phone LIKE '___-___-____' THEN '(' + LEFT(phone, 3) + ') ' + SUBSTRING(phone, 5, 3) + '-' + RIGHT(phone, 4)
            WHEN phone LIKE '(___)___-____' THEN '(' + SUBSTRING(phone, 2, 3) + ') ' + SUBSTRING(phone, 6, 3) + '-' + RIGHT(phone, 4)
            WHEN phone LIKE '__________' THEN '(' + LEFT(phone, 3) + ') ' + SUBSTRING(phone, 4, 3) + '-' + RIGHT(phone, 4)
            ELSE NULL
        END AS phone_clean,
        
        city,
        state,
        
        -- Standardize zip code (5 or 9 digits)
        CASE 
            WHEN zip_code LIKE '_____' THEN zip_code
            WHEN zip_code LIKE '_____-____' THEN zip_code
            ELSE NULL
        END AS zip_clean,
        
        -- Parse join date (handle multiple formats)
        CASE 
            WHEN TRY_CAST(join_date AS DATE) IS NOT NULL THEN CAST(join_date AS DATE)
            ELSE NULL
        END AS join_date_clean,
        
        -- Standardize tier
        CASE 
            WHEN customer_tier IN ('Gold', 'Silver', 'Bronze', 'Standard') THEN customer_tier
            WHEN customer_tier = '' OR customer_tier IS NULL THEN 'Standard'
            ELSE 'Standard'
        END AS tier_clean,
        
        bronze_row_number,
        bronze_loaded_at,
        
        -- Deduplication: rank by most recent load
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY bronze_loaded_at DESC) AS row_rank
        
    FROM bronze.customers
    WHERE customer_id IS NOT NULL 
      AND customer_id <> ''  -- Remove records with missing customer_id
)
INSERT INTO silver.customers (
    customer_id, first_name, last_name, full_name, email, phone, 
    city, state, zip_code, join_date, customer_tier, bronze_row_id
)
SELECT 
    customer_id,
    first_name,
    last_name,
    first_name + ' ' + last_name AS full_name,  -- Standardized to "First Last"
    email_clean,
    phone_clean,
    city,
    state,
    zip_clean,
    join_date_clean,
    tier_clean,
    bronze_row_number
FROM cleaned_customers
WHERE row_rank = 1;  -- Keep only the most recent record for each customer
GO

-- ========================================
-- Verification
-- ========================================

PRINT '';
PRINT 'Customer cleaning complete!';
PRINT 'Bronze records: ' + CAST((SELECT COUNT(*) FROM bronze.customers) AS VARCHAR);
PRINT 'Silver records: ' + CAST((SELECT COUNT(*) FROM silver.customers) AS VARCHAR);
PRINT 'Records removed: ' + CAST((SELECT COUNT(*) FROM bronze.customers) - (SELECT COUNT(*) FROM silver.customers) AS VARCHAR);
PRINT '';

-- Show sample of cleaned data
SELECT TOP 10
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    customer_tier
FROM silver.customers
ORDER BY customer_key;
GO
