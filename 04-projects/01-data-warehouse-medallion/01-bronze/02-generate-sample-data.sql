-- ========================================
-- Generate Sample Data for Bronze Layer
-- ========================================
-- Purpose: Create realistic messy data to simulate real-world sources
-- This data intentionally includes quality issues that we'll fix in Silver layer
-- ========================================

USE TechStore_Warehouse;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('bronze', '02-generate-sample-data.sql', 'running');
GO

DECLARE @run_id INT = SCOPE_IDENTITY();
GO

-- ========================================
-- Helper: Date Function (generates random dates)
-- ========================================
CREATE OR ALTER FUNCTION dbo.fn_RandomDate
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @DaysDiff INT = DATEDIFF(DAY, @StartDate, @EndDate);
    
    -- Prevent divide-by-zero error
    IF @DaysDiff = 0
        SET @DaysDiff = 1;
    
    DECLARE @RandomDays INT = ABS(CHECKSUM(NEWID())) % @DaysDiff;
    DECLARE @RandomDate DATE = DATEADD(DAY, @RandomDays, @StartDate);
    
    -- Return in different formats to simulate messy data
    DECLARE @Format INT = ABS(CHECKSUM(NEWID())) % 4;
    
    RETURN CASE @Format
        WHEN 0 THEN CONVERT(VARCHAR(50), @RandomDate, 23)  -- YYYY-MM-DD
        WHEN 1 THEN CONVERT(VARCHAR(50), @RandomDate, 101) -- MM/DD/YYYY
        WHEN 2 THEN CONVERT(VARCHAR(50), @RandomDate, 103) -- DD/MM/YYYY
        ELSE CONVERT(VARCHAR(50), @RandomDate, 120)        -- YYYY-MM-DD HH:MM:SS
    END;
END;
GO

-- ========================================
-- Helper: Random String Generator
-- ========================================
CREATE OR ALTER FUNCTION dbo.fn_RandomString
(
    @Length INT
)
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @Result VARCHAR(100) = '';
    DECLARE @Chars VARCHAR(52) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    DECLARE @i INT = 0;
    
    WHILE @i < @Length
    BEGIN
        SET @Result = @Result + SUBSTRING(@Chars, ABS(CHECKSUM(NEWID())) % 52 + 1, 1);
        SET @i = @i + 1;
    END;
    
    RETURN @Result;
END;
GO

-- ========================================
-- Generate Customers (10,000 records with duplicates)
-- ========================================
PRINT 'Generating customer data...';

DECLARE @CustomerCount INT = 1;
DECLARE @DuplicateEvery INT = 50; -- Create duplicate every 50 records

WHILE @CustomerCount <= 10000
BEGIN
    DECLARE @CustomerID VARCHAR(50) = 'C' + RIGHT('00000' + CAST(@CustomerCount AS VARCHAR), 5);
    DECLARE @FirstName VARCHAR(100) = dbo.fn_RandomString(CAST(RAND() * 10 + 3 AS INT));
    DECLARE @LastName VARCHAR(100) = dbo.fn_RandomString(CAST(RAND() * 10 + 5 AS INT));
    DECLARE @City VARCHAR(100) = CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
        WHEN 4 THEN 'Phoenix'
        WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio'
        WHEN 7 THEN 'San Diego'
        WHEN 8 THEN 'Dallas'
        ELSE 'Austin'
    END;
    
    -- Intentional data quality issues
    DECLARE @FullName VARCHAR(200);
    DECLARE @Email VARCHAR(255);
    DECLARE @Phone VARCHAR(50);
    DECLARE @Zip VARCHAR(20);
    DECLARE @Tier VARCHAR(50);
    
    -- Different name formats
    IF @CustomerCount % 3 = 0
        SET @FullName = @FirstName + ' ' + @LastName;  -- First Last
    ELSE IF @CustomerCount % 3 = 1
        SET @FullName = @LastName + ', ' + @FirstName; -- Last, First
    ELSE
        SET @FullName = @FirstName; -- Only first name (bad data)
    
    -- Email issues (10% invalid, 5% NULL)
    IF @CustomerCount % 20 = 0
        SET @Email = NULL;
    ELSE IF @CustomerCount % 10 = 0
        SET @Email = @FirstName + '@invalid';  -- Missing domain
    ELSE
        SET @Email = LOWER(@FirstName + '.' + @LastName + '@email.com');
    
    -- Phone format variations
    IF @CustomerCount % 4 = 0
        SET @Phone = '555-' + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR), 3) + '-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4);
    ELSE IF @CustomerCount % 4 = 1
        SET @Phone = '(555)' + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR), 3) + '-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4);
    ELSE IF @CustomerCount % 4 = 2
        SET @Phone = '555' + RIGHT('0000000' + CAST(ABS(CHECKSUM(NEWID())) % 10000000 AS VARCHAR), 7);
    ELSE
        SET @Phone = NULL; -- Missing phone
    
    -- Zip code variations
    IF @CustomerCount % 5 = 0
        SET @Zip = RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR), 5); -- 5 digits
    ELSE IF @CustomerCount % 5 = 1
        SET @Zip = RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR), 5) + '-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4); -- 9 digits
    ELSE
        SET @Zip = NULL;
    
    -- Customer tier (sometimes empty)
    IF @CustomerCount % 15 = 0
        SET @Tier = '';  -- Empty string
    ELSE IF @CustomerCount % 4 = 0
        SET @Tier = 'Gold';
    ELSE IF @CustomerCount % 4 = 1
        SET @Tier = 'Silver';
    ELSE IF @CustomerCount % 4 = 2
        SET @Tier = 'Bronze';
    ELSE
        SET @Tier = 'Standard';
    
    INSERT INTO bronze.customers (customer_id, full_name, email, phone, city, state, zip_code, join_date, customer_tier)
    VALUES (
        @CustomerID,
        @FullName,
        @Email,
        @Phone,
        @City,
        'TX', -- State
        @Zip,
        dbo.fn_RandomDate('2020-01-01', '2024-12-31'),
        @Tier
    );
    
    -- Create duplicates every N records
    IF @CustomerCount % @DuplicateEvery = 0
    BEGIN
        INSERT INTO bronze.customers (customer_id, full_name, email, phone, city, state, zip_code, join_date, customer_tier)
        VALUES (
            @CustomerID,  -- Same customer ID (duplicate!)
            @FullName,
            @Email,
            @Phone,
            @City,
            'TX',
            @Zip,
            dbo.fn_RandomDate('2020-01-01', '2024-12-31'),
            @Tier
        );
    END;
    
    SET @CustomerCount = @CustomerCount + 1;
END;

PRINT 'Customer data generated: ' + CAST((SELECT COUNT(*) FROM bronze.customers) AS VARCHAR) + ' records';
GO

-- ========================================
-- Generate Products/Inventory (5,000 products)
-- ========================================
PRINT 'Generating inventory data...';

DECLARE @ProductCount INT = 1;
DECLARE @Categories TABLE (Name VARCHAR(100));
INSERT INTO @Categories VALUES ('Laptops'), ('Monitors'), ('Keyboards'), ('Mice'), ('Headphones'), ('Speakers'), ('Webcams'), ('Cables'), ('Storage'), ('Networking');

WHILE @ProductCount <= 5000
BEGIN
    DECLARE @ProductID VARCHAR(50) = 'P' + RIGHT('00000' + CAST(@ProductCount AS VARCHAR), 5);
    DECLARE @Category VARCHAR(100) = (SELECT TOP 1 Name FROM @Categories ORDER BY NEWID());
    DECLARE @ProductName VARCHAR(200) = @Category + ' Model ' + dbo.fn_RandomString(5);
    
    -- Intentional issues
    DECLARE @ProductCode VARCHAR(100);
    DECLARE @Cost VARCHAR(50);
    DECLARE @Price VARCHAR(50);
    DECLARE @Quantity VARCHAR(50);
    DECLARE @IsActive VARCHAR(10);
    
    -- Product code with special characters
    IF @ProductCount % 10 = 0
        SET @ProductCode = 'SKU#' + @ProductID + '!';
    ELSE
        SET @ProductCode = 'SKU-' + @ProductID;
    
    -- Price variations (sometimes with $ or commas)
    DECLARE @BasePrice DECIMAL(10,2) = CAST(RAND() * 1000 + 50 AS DECIMAL(10,2));
    IF @ProductCount % 5 = 0
        SET @Cost = '$' + CAST(@BasePrice * 0.6 AS VARCHAR);
    ELSE IF @ProductCount % 5 = 1
        SET @Cost = REPLACE(CAST(@BasePrice * 0.6 AS VARCHAR), '.', ','); -- European format
    ELSE
        SET @Cost = CAST(@BasePrice * 0.6 AS VARCHAR);
    
    IF @ProductCount % 5 = 0
        SET @Price = '$' + CAST(@BasePrice AS VARCHAR);
    ELSE
        SET @Price = CAST(@BasePrice AS VARCHAR);
    
    -- Quantity (sometimes negative!)
    IF @ProductCount % 100 = 0
        SET @Quantity = CAST(-1 * ABS(CHECKSUM(NEWID())) % 50 AS VARCHAR); -- Oversold!
    ELSE IF @ProductCount % 50 = 0
        SET @Quantity = 'N/A'; -- String instead of number
    ELSE
        SET @Quantity = CAST(ABS(CHECKSUM(NEWID())) % 500 AS VARCHAR);
    
    -- is_active variations
    IF @ProductCount % 6 = 0
        SET @IsActive = 'true';
    ELSE IF @ProductCount % 6 = 1
        SET @IsActive = 'false';
    ELSE IF @ProductCount % 6 = 2
        SET @IsActive = '1';
    ELSE IF @ProductCount % 6 = 3
        SET @IsActive = '0';
    ELSE IF @ProductCount % 6 = 4
        SET @IsActive = 'yes';
    ELSE
        SET @IsActive = ''; -- Empty
    
    INSERT INTO bronze.inventory (product_id, product_code, product_name, category, supplier_id, supplier_name, cost_price, sell_price, stock_quantity, reorder_level, warehouse_location, last_restocked, is_active)
    VALUES (
        @ProductID,
        @ProductCode,
        @ProductName,
        @Category,
        'SUP' + CAST(ABS(CHECKSUM(NEWID())) % 100 + 1 AS VARCHAR),
        'Supplier ' + dbo.fn_RandomString(8),
        @Cost,
        @Price,
        @Quantity,
        CAST(ABS(CHECKSUM(NEWID())) % 50 + 10 AS VARCHAR),
        'Warehouse-' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR),
        dbo.fn_RandomDate('2024-01-01', '2024-12-31'),
        @IsActive
    );
    
    SET @ProductCount = @ProductCount + 1;
END;

PRINT 'Inventory data generated: ' + CAST((SELECT COUNT(*) FROM bronze.inventory) AS VARCHAR) + ' records';
GO

-- ========================================
-- Generate Orders (50,000 orders)
-- ========================================
PRINT 'Generating orders data...';

DECLARE @OrderCount INT = 1;

WHILE @OrderCount <= 50000
BEGIN
    DECLARE @OrderID VARCHAR(50) = 'ORD' + RIGHT('0000000' + CAST(@OrderCount AS VARCHAR), 7);
    
    -- Get random customer (sometimes NULL for missing customer_id)
    DECLARE @CustID VARCHAR(50);
    IF @OrderCount % 100 = 0
        SET @CustID = NULL;  -- Missing customer
    ELSE IF @OrderCount % 100 = 1
        SET @CustID = '';    -- Empty string
    ELSE
        SET @CustID = 'C' + RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 + 1 AS VARCHAR), 5);
    
    -- Get random product
    DECLARE @ProdID VARCHAR(50) = 'P' + RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 5000 + 1 AS VARCHAR), 5);
    DECLARE @ProdName VARCHAR(200) = 'Product ' + dbo.fn_RandomString(10);
    
    -- Quantity (sometimes invalid)
    DECLARE @Qty VARCHAR(50);
    IF @OrderCount % 500 = 0
        SET @Qty = 'N/A';
    ELSE IF @OrderCount % 300 = 0
        SET @Qty = CAST(-1 * (ABS(CHECKSUM(NEWID())) % 5 + 1) AS VARCHAR); -- Negative
    ELSE
        SET @Qty = CAST(ABS(CHECKSUM(NEWID())) % 10 + 1 AS VARCHAR);
    
    -- Order date (sometimes future or invalid format)
    DECLARE @OrderDate VARCHAR(50);
    IF @OrderCount % 1000 = 0
        SET @OrderDate = '2024-99-99'; -- Invalid date
    ELSE IF @OrderCount % 800 = 0
        SET @OrderDate = dbo.fn_RandomDate('2025-01-01', '2025-12-31'); -- Future date
    ELSE
        SET @OrderDate = dbo.fn_RandomDate('2024-01-01', '2024-11-13');
    
    -- Amount (sometimes with $ or invalid)
    DECLARE @Amount VARCHAR(50) = CAST(CAST(RAND() * 500 + 20 AS DECIMAL(10,2)) AS VARCHAR);
    IF @OrderCount % 7 = 0
        SET @Amount = '$' + @Amount;
    
    -- Payment method
    DECLARE @Payment VARCHAR(50) = CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Debit Card'
        WHEN 2 THEN 'PayPal'
        ELSE 'Cash'
    END;
    
    -- Status
    DECLARE @Status VARCHAR(50) = CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Processing'
        WHEN 2 THEN 'Shipped'
        WHEN 3 THEN 'Delivered'
        ELSE 'Cancelled'
    END;
    
    INSERT INTO bronze.orders (order_id, customer_id, product_id, product_name, quantity, order_date, total_amount, payment_method, order_status, bronze_source_file)
    VALUES (
        @OrderID,
        @CustID,
        @ProdID,
        @ProdName,
        @Qty,
        @OrderDate,
        @Amount,
        @Payment,
        @Status,
        'orders_export_' + CONVERT(VARCHAR, GETDATE(), 112) + '.csv'
    );
    
    SET @OrderCount = @OrderCount + 1;
END;

PRINT 'Orders data generated: ' + CAST((SELECT COUNT(*) FROM bronze.orders) AS VARCHAR) + ' records';
GO

-- ========================================
-- Update Pipeline Status
-- ========================================

DECLARE @total_rows INT = (
    SELECT (SELECT COUNT(*) FROM bronze.customers) +
           (SELECT COUNT(*) FROM bronze.inventory) +
           (SELECT COUNT(*) FROM bronze.orders)
);

UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = @total_rows
WHERE layer = 'bronze' 
  AND script_name = '02-generate-sample-data.sql'
  AND status = 'running';
GO

-- ========================================
-- Cleanup Helper Functions
-- ========================================
DROP FUNCTION IF EXISTS dbo.fn_RandomDate;
DROP FUNCTION IF EXISTS dbo.fn_RandomString;
GO

PRINT '';
PRINT '========================================';
PRINT 'Sample Data Generation Complete!';
PRINT '========================================';
PRINT 'Customers: ' + CAST((SELECT COUNT(*) FROM bronze.customers) AS VARCHAR);
PRINT 'Inventory: ' + CAST((SELECT COUNT(*) FROM bronze.inventory) AS VARCHAR);
PRINT 'Orders: ' + CAST((SELECT COUNT(*) FROM bronze.orders) AS VARCHAR);
PRINT '';
PRINT 'Next: Run 03-verify-bronze-data.sql to check data quality issues';
GO
