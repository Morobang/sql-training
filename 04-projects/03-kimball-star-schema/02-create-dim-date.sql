-- ============================================================================
-- Create Date Dimension (dim_date)
-- ============================================================================
-- THE MOST IMPORTANT DIMENSION!
-- Every fact table joins to date dimension
-- Pre-populate with 10+ years of dates for historical and future analysis
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create dim_date Table
-- ============================================================================

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    -- Surrogate Key (Integer format: YYYYMMDD)
    date_key INT PRIMARY KEY COMMENT 'Surrogate key in YYYYMMDD format (20240315)',
    
    -- Full Date
    full_date DATE NOT NULL UNIQUE COMMENT 'Actual date value',
    
    -- Day Attributes
    day_of_week TINYINT COMMENT '1=Sunday, 2=Monday, ..., 7=Saturday',
    day_of_week_name VARCHAR(20) COMMENT 'Sunday, Monday, Tuesday, ...',
    day_of_week_short CHAR(3) COMMENT 'Sun, Mon, Tue, ...',
    day_of_month TINYINT COMMENT '1-31',
    day_of_year SMALLINT COMMENT '1-366',
    day_suffix CHAR(4) COMMENT '1st, 2nd, 3rd, 4th, ..., 31st',
    
    -- Week Attributes
    week_of_year TINYINT COMMENT 'ISO week number 1-53',
    week_of_month TINYINT COMMENT '1-5 (first week, second week, ...)',
    first_day_of_week DATE COMMENT 'Date of Sunday (week start)',
    last_day_of_week DATE COMMENT 'Date of Saturday (week end)',
    
    -- Month Attributes
    month_number TINYINT COMMENT '1-12',
    month_name VARCHAR(20) COMMENT 'January, February, ..., December',
    month_name_short CHAR(3) COMMENT 'Jan, Feb, Mar, ...',
    first_day_of_month DATE COMMENT 'First day of the month',
    last_day_of_month DATE COMMENT 'Last day of the month',
    days_in_month TINYINT COMMENT '28-31',
    
    -- Quarter Attributes
    quarter_number TINYINT COMMENT '1-4',
    quarter_name VARCHAR(20) COMMENT 'Q1, Q2, Q3, Q4',
    first_day_of_quarter DATE COMMENT 'First day of the quarter',
    last_day_of_quarter DATE COMMENT 'Last day of the quarter',
    
    -- Year Attributes
    year_number SMALLINT COMMENT '2020, 2021, 2022, ...',
    year_name VARCHAR(20) COMMENT 'Year 2024',
    is_leap_year BOOLEAN COMMENT 'TRUE if leap year',
    
    -- Fiscal Attributes (if fiscal year differs from calendar year)
    fiscal_year SMALLINT COMMENT 'Fiscal year (e.g., FY 2024)',
    fiscal_quarter TINYINT COMMENT 'Fiscal quarter 1-4',
    fiscal_month TINYINT COMMENT 'Fiscal month 1-12',
    
    -- Weekend/Weekday Flags
    is_weekend BOOLEAN COMMENT 'TRUE if Saturday or Sunday',
    is_weekday BOOLEAN COMMENT 'TRUE if Monday-Friday',
    
    -- Holiday Flags (US holidays - customize for your region)
    is_holiday BOOLEAN COMMENT 'TRUE if public holiday',
    holiday_name VARCHAR(50) COMMENT 'Name of holiday if applicable',
    
    -- Business Day Indicators
    is_business_day BOOLEAN COMMENT 'TRUE if weekday and not a holiday',
    business_day_of_month TINYINT COMMENT 'Business day counter within month',
    business_day_of_year SMALLINT COMMENT 'Business day counter within year',
    
    -- Relative Date Helpers
    days_from_today INT COMMENT 'Negative for past, 0 for today, positive for future',
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_full_date (full_date),
    INDEX idx_year_month (year_number, month_number),
    INDEX idx_year_quarter (year_number, quarter_number)
    
) COMMENT 'Date dimension - covers 2020-2030 with full calendar attributes';

-- ============================================================================
-- STEP 2: Create Stored Procedure to Populate dim_date
-- ============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_populate_dim_date$$

CREATE PROCEDURE sp_populate_dim_date(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    DECLARE current_date DATE;
    DECLARE current_date_key INT;
    
    -- Fiscal year offset (if fiscal year starts in month other than January)
    -- Example: If fiscal year starts July 1, offset = 6
    DECLARE fiscal_year_offset INT DEFAULT 0;
    
    SET current_date = start_date;
    
    -- Truncate existing data
    TRUNCATE TABLE dim_date;
    
    -- Loop through each date
    WHILE current_date <= end_date DO
        
        -- Calculate date_key (YYYYMMDD format)
        SET current_date_key = YEAR(current_date) * 10000 
                             + MONTH(current_date) * 100 
                             + DAY(current_date);
        
        -- Insert date record
        INSERT INTO dim_date (
            date_key,
            full_date,
            day_of_week,
            day_of_week_name,
            day_of_week_short,
            day_of_month,
            day_of_year,
            day_suffix,
            week_of_year,
            week_of_month,
            first_day_of_week,
            last_day_of_week,
            month_number,
            month_name,
            month_name_short,
            first_day_of_month,
            last_day_of_month,
            days_in_month,
            quarter_number,
            quarter_name,
            first_day_of_quarter,
            last_day_of_quarter,
            year_number,
            year_name,
            is_leap_year,
            fiscal_year,
            fiscal_quarter,
            fiscal_month,
            is_weekend,
            is_weekday,
            is_holiday,
            holiday_name,
            is_business_day,
            days_from_today
        )
        VALUES (
            current_date_key,
            current_date,
            DAYOFWEEK(current_date),
            DAYNAME(current_date),
            LEFT(DAYNAME(current_date), 3),
            DAY(current_date),
            DAYOFYEAR(current_date),
            -- Day suffix (1st, 2nd, 3rd, 4th, ...)
            CASE 
                WHEN DAY(current_date) IN (1, 21, 31) THEN CONCAT(DAY(current_date), 'st')
                WHEN DAY(current_date) IN (2, 22) THEN CONCAT(DAY(current_date), 'nd')
                WHEN DAY(current_date) IN (3, 23) THEN CONCAT(DAY(current_date), 'rd')
                ELSE CONCAT(DAY(current_date), 'th')
            END,
            WEEK(current_date, 3),  -- ISO week
            CEILING(DAY(current_date) / 7),  -- Week of month
            current_date - INTERVAL (DAYOFWEEK(current_date) - 1) DAY,  -- First day of week (Sunday)
            current_date + INTERVAL (7 - DAYOFWEEK(current_date)) DAY,  -- Last day of week (Saturday)
            MONTH(current_date),
            MONTHNAME(current_date),
            LEFT(MONTHNAME(current_date), 3),
            DATE_FORMAT(current_date, '%Y-%m-01'),  -- First day of month
            LAST_DAY(current_date),  -- Last day of month
            DAY(LAST_DAY(current_date)),  -- Days in month
            QUARTER(current_date),
            CONCAT('Q', QUARTER(current_date)),
            -- First day of quarter
            CASE QUARTER(current_date)
                WHEN 1 THEN DATE_FORMAT(current_date, '%Y-01-01')
                WHEN 2 THEN DATE_FORMAT(current_date, '%Y-04-01')
                WHEN 3 THEN DATE_FORMAT(current_date, '%Y-07-01')
                WHEN 4 THEN DATE_FORMAT(current_date, '%Y-10-01')
            END,
            -- Last day of quarter
            CASE QUARTER(current_date)
                WHEN 1 THEN DATE_FORMAT(current_date, '%Y-03-31')
                WHEN 2 THEN DATE_FORMAT(current_date, '%Y-06-30')
                WHEN 3 THEN DATE_FORMAT(current_date, '%Y-09-30')
                WHEN 4 THEN DATE_FORMAT(current_date, '%Y-12-31')
            END,
            YEAR(current_date),
            CONCAT('Year ', YEAR(current_date)),
            -- Leap year check
            (YEAR(current_date) % 4 = 0 AND YEAR(current_date) % 100 != 0) OR (YEAR(current_date) % 400 = 0),
            -- Fiscal year (adjust based on fiscal year start month)
            YEAR(DATE_ADD(current_date, INTERVAL -fiscal_year_offset MONTH)),
            -- Fiscal quarter
            QUARTER(DATE_ADD(current_date, INTERVAL -fiscal_year_offset MONTH)),
            -- Fiscal month
            MONTH(DATE_ADD(current_date, INTERVAL -fiscal_year_offset MONTH)),
            -- Is weekend (Saturday or Sunday)
            DAYOFWEEK(current_date) IN (1, 7),
            -- Is weekday (Monday-Friday)
            DAYOFWEEK(current_date) BETWEEN 2 AND 6,
            -- Is holiday (will be set separately)
            FALSE,
            NULL,
            -- Is business day (weekday and not holiday)
            DAYOFWEEK(current_date) BETWEEN 2 AND 6,
            -- Days from today
            DATEDIFF(current_date, CURDATE())
        );
        
        -- Move to next date
        SET current_date = DATE_ADD(current_date, INTERVAL 1 DAY);
        
    END WHILE;
    
    -- Log ETL run
    INSERT INTO metadata_etl_log (table_name, process_name, start_time, end_time, rows_inserted, status)
    VALUES ('dim_date', 'sp_populate_dim_date', NOW(), NOW(), DATEDIFF(end_date, start_date) + 1, 'success');
    
END$$

DELIMITER ;

-- ============================================================================
-- STEP 3: Populate dim_date (2020-2030)
-- ============================================================================

CALL sp_populate_dim_date('2020-01-01', '2030-12-31');

SELECT CONCAT('Loaded ', COUNT(*), ' days into dim_date') AS status FROM dim_date;

-- ============================================================================
-- STEP 4: Update Holiday Flags (US Holidays)
-- ============================================================================

-- New Year's Day (January 1)
UPDATE dim_date 
SET is_holiday = TRUE, 
    holiday_name = 'New Year''s Day',
    is_business_day = FALSE
WHERE month_number = 1 AND day_of_month = 1;

-- Martin Luther King Jr. Day (Third Monday in January)
UPDATE dim_date d1
JOIN (
    SELECT year_number, MIN(full_date) AS holiday_date
    FROM dim_date
    WHERE month_number = 1 
      AND day_of_week_name = 'Monday'
      AND week_of_month = 3
    GROUP BY year_number
) d2 ON d1.full_date = d2.holiday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Martin Luther King Jr. Day',
    d1.is_business_day = FALSE;

-- Presidents' Day (Third Monday in February)
UPDATE dim_date d1
JOIN (
    SELECT year_number, MIN(full_date) AS holiday_date
    FROM dim_date
    WHERE month_number = 2 
      AND day_of_week_name = 'Monday'
      AND week_of_month = 3
    GROUP BY year_number
) d2 ON d1.full_date = d2.holiday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Presidents'' Day',
    d1.is_business_day = FALSE;

-- Memorial Day (Last Monday in May)
UPDATE dim_date d1
JOIN (
    SELECT year_number, MAX(full_date) AS holiday_date
    FROM dim_date
    WHERE month_number = 5 
      AND day_of_week_name = 'Monday'
    GROUP BY year_number
) d2 ON d1.full_date = d2.holiday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Memorial Day',
    d1.is_business_day = FALSE;

-- Independence Day (July 4)
UPDATE dim_date 
SET is_holiday = TRUE, 
    holiday_name = 'Independence Day',
    is_business_day = FALSE
WHERE month_number = 7 AND day_of_month = 4;

-- Labor Day (First Monday in September)
UPDATE dim_date d1
JOIN (
    SELECT year_number, MIN(full_date) AS holiday_date
    FROM dim_date
    WHERE month_number = 9 
      AND day_of_week_name = 'Monday'
    GROUP BY year_number
) d2 ON d1.full_date = d2.holiday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Labor Day',
    d1.is_business_day = FALSE;

-- Thanksgiving (Fourth Thursday in November)
UPDATE dim_date d1
JOIN (
    SELECT year_number, MIN(full_date) AS holiday_date
    FROM dim_date
    WHERE month_number = 11 
      AND day_of_week_name = 'Thursday'
      AND week_of_month = 4
    GROUP BY year_number
) d2 ON d1.full_date = d2.holiday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Thanksgiving',
    d1.is_business_day = FALSE;

-- Christmas (December 25)
UPDATE dim_date 
SET is_holiday = TRUE, 
    holiday_name = 'Christmas',
    is_business_day = FALSE
WHERE month_number = 12 AND day_of_month = 25;

-- Black Friday (Day after Thanksgiving)
UPDATE dim_date d1
JOIN (
    SELECT full_date + INTERVAL 1 DAY AS black_friday_date
    FROM dim_date
    WHERE holiday_name = 'Thanksgiving'
) d2 ON d1.full_date = d2.black_friday_date
SET d1.is_holiday = TRUE,
    d1.holiday_name = 'Black Friday';
    -- Note: Black Friday is often a business day for retail

-- ============================================================================
-- STEP 5: Calculate Business Day Numbers
-- ============================================================================

-- Business day of month (1st business day, 2nd business day, ...)
UPDATE dim_date d1
SET business_day_of_month = (
    SELECT COUNT(*)
    FROM dim_date d2
    WHERE d2.year_number = d1.year_number
      AND d2.month_number = d1.month_number
      AND d2.is_business_day = TRUE
      AND d2.full_date <= d1.full_date
)
WHERE is_business_day = TRUE;

-- Business day of year
UPDATE dim_date d1
SET business_day_of_year = (
    SELECT COUNT(*)
    FROM dim_date d2
    WHERE d2.year_number = d1.year_number
      AND d2.is_business_day = TRUE
      AND d2.full_date <= d1.full_date
)
WHERE is_business_day = TRUE;

-- ============================================================================
-- STEP 6: Verification Queries
-- ============================================================================

-- Count of records
SELECT 
    COUNT(*) AS total_days,
    MIN(full_date) AS start_date,
    MAX(full_date) AS end_date,
    COUNT(DISTINCT year_number) AS years_covered
FROM dim_date;

-- Sample data
SELECT * FROM dim_date WHERE full_date = CURDATE();
SELECT * FROM dim_date WHERE is_holiday = TRUE LIMIT 10;
SELECT * FROM dim_date WHERE full_date BETWEEN '2024-01-01' AND '2024-01-31' ORDER BY full_date;

-- Business days per month in 2024
SELECT 
    month_name,
    COUNT(*) AS business_days
FROM dim_date
WHERE year_number = 2024
  AND is_business_day = TRUE
GROUP BY month_number, month_name
ORDER BY month_number;

-- Holidays in 2024
SELECT 
    full_date,
    day_of_week_name,
    holiday_name
FROM dim_date
WHERE year_number = 2024
  AND is_holiday = TRUE
ORDER BY full_date;

/*
============================================================================
DIM_DATE COMPLETE!
============================================================================

✅ 11 years of dates (2020-2030) = ~4,018 rows
✅ Full calendar attributes (day, week, month, quarter, year)
✅ Fiscal year support
✅ US holidays marked
✅ Business day calculations
✅ Helper columns for reporting

Next: 03-create-dim-store.sql
============================================================================
*/
