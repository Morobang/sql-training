/*
============================================================================
Lesson 07.09 - Conversion Functions
============================================================================

Description:
Master data type conversions with CAST, CONVERT, TRY_CAST, and TRY_CONVERT.
Learn safe conversion techniques, format codes, and handle conversion errors.

Topics Covered:
• CAST function (ANSI standard)
• CONVERT function (SQL Server specific)
• TRY_CAST and TRY_CONVERT (safe conversions)
• Format codes for CONVERT
• String to number conversions
• String to date conversions
• Number to string formatting
• Implicit vs explicit conversion

Prerequisites:
• Lesson 07.04 - Number Precision
• Lesson 07.07 - Temporal Data Generation

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: CAST Function (ANSI Standard)
============================================================================
CAST(expression AS data_type)
Portable across database systems (standard SQL)
*/

-- Example 1.1: Basic CAST operations
SELECT 
    CAST(123 AS VARCHAR(10)) AS NumberToString,
    CAST('456' AS INT) AS StringToNumber,
    CAST(123.456 AS DECIMAL(10,2)) AS RoundedNumber,
    CAST('2025-01-15' AS DATE) AS StringToDate;

-- Example 1.2: CAST with precision
SELECT 
    CAST(123.456 AS INT) AS ToInteger,                    -- 123 (truncates)
    CAST(123.456 AS DECIMAL(5,2)) AS ToDecimal,           -- 123.46 (rounds)
    CAST(123.456 AS NUMERIC(10,4)) AS ToNumeric,          -- 123.4560
    CAST(123 AS DECIMAL(10,2)) AS IntToDecimal;           -- 123.00

-- Example 1.3: CAST dates
SELECT 
    CAST(GETDATE() AS DATE) AS DateOnly,
    CAST(GETDATE() AS TIME) AS TimeOnly,
    CAST('2025-01-15 14:30:00' AS DATETIME) AS StringToDateTime;

-- Example 1.4: CAST in calculations
SELECT 
    ProductID,
    ProductName,
    Price,
    Stock,
    CAST(Price * Stock AS DECIMAL(10,2)) AS InventoryValue
FROM Products;

-- Example 1.5: CAST error example
-- ❌ This will ERROR:
-- SELECT CAST('Not a number' AS INT);  
-- Error: Conversion failed

-- ✅ Use TRY_CAST instead (see Part 3)


/*
============================================================================
PART 2: CONVERT Function (SQL Server Specific)
============================================================================
CONVERT(data_type, expression [, style])
Additional style parameter for formatting dates and numbers
*/

-- Example 2.1: Basic CONVERT
SELECT 
    CONVERT(VARCHAR(10), 123) AS NumberToString,
    CONVERT(INT, '456') AS StringToNumber,
    CONVERT(DECIMAL(10,2), 123.456) AS RoundedNumber,
    CONVERT(DATE, '2025-01-15') AS StringToDate;

-- Example 2.2: CONVERT with style codes for dates
DECLARE @Date DATETIME = '2025-01-15 14:30:45';

SELECT 
    CONVERT(VARCHAR, @Date, 101) AS USA_Format,           -- 01/15/2025
    CONVERT(VARCHAR, @Date, 103) AS UK_Format,            -- 15/01/2025
    CONVERT(VARCHAR, @Date, 105) AS Italian_Format,       -- 15-01-2025
    CONVERT(VARCHAR, @Date, 106) AS MonDDYYYY,            -- Jan 15 2025
    CONVERT(VARCHAR, @Date, 107) AS MonDD_YYYY,           -- Jan 15, 2025
    CONVERT(VARCHAR, @Date, 110) AS USA_Dashes,           -- 01-15-2025
    CONVERT(VARCHAR, @Date, 111) AS Japan_Format,         -- 2025/01/15
    CONVERT(VARCHAR, @Date, 112) AS ISO_Format,           -- 20250115
    CONVERT(VARCHAR, @Date, 120) AS ODBC_Canonical,       -- 2025-01-15 14:30:45
    CONVERT(VARCHAR, @Date, 126) AS ISO8601;              -- 2025-01-15T14:30:45.000

-- Example 2.3: CONVERT time formats
SELECT 
    CONVERT(VARCHAR, @Date, 8) AS TimeHHMMSS,             -- 14:30:45
    CONVERT(VARCHAR, @Date, 108) AS LongTime,             -- 14:30:45
    CONVERT(VARCHAR, @Date, 14) AS Time_ms;               -- 14:30:45:000

-- Example 2.4: Common date style codes
-- Style Code | Format
-- 0 or 100   | mon dd yyyy hh:miAM/PM
-- 1 or 101   | mm/dd/yyyy
-- 2 or 102   | yyyy.mm.dd
-- 3 or 103   | dd/mm/yyyy
-- 4 or 104   | dd.mm.yyyy
-- 5 or 105   | dd-mm-yyyy
-- 6 or 106   | dd mon yyyy
-- 7 or 107   | mon dd, yyyy
-- 10 or 110  | mm-dd-yyyy
-- 11 or 111  | yyyy/mm/dd
-- 12 or 112  | yyyymmdd
-- 120        | yyyy-mm-dd hh:mi:ss (ODBC canonical)
-- 126        | yyyy-mm-ddThh:mi:ss.mmm (ISO8601)


/*
============================================================================
PART 3: TRY_CAST and TRY_CONVERT (Safe Conversions)
============================================================================
Returns NULL instead of error if conversion fails
*/

-- Example 3.1: TRY_CAST safety
SELECT 
    TRY_CAST('123' AS INT) AS ValidConversion,           -- 123
    TRY_CAST('ABC' AS INT) AS InvalidConversion,         -- NULL (no error!)
    TRY_CAST('999999999999' AS INT) AS OverflowConv;     -- NULL

-- Example 3.2: TRY_CONVERT with dates
SELECT 
    TRY_CONVERT(DATE, '2025-01-15') AS ValidDate,
    TRY_CONVERT(DATE, '2025-13-45') AS InvalidDate,      -- NULL
    TRY_CONVERT(DATE, 'Not a date') AS NotADate;         -- NULL

-- Example 3.3: Clean dirty data with TRY_CAST
CREATE TABLE #DirtyData (
    ID INT,
    ValueText VARCHAR(50)
);

INSERT INTO #DirtyData VALUES
(1, '123'),
(2, '456.78'),
(3, 'Not a number'),
(4, '789'),
(5, '12.34.56');  -- Invalid decimal

SELECT 
    ID,
    ValueText,
    TRY_CAST(ValueText AS INT) AS AsInteger,
    TRY_CAST(ValueText AS DECIMAL(10,2)) AS AsDecimal,
    CASE 
        WHEN TRY_CAST(ValueText AS DECIMAL(10,2)) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid'
    END AS ValidationStatus
FROM #DirtyData;

DROP TABLE #DirtyData;

-- Example 3.4: Use TRY_CONVERT for user input validation
CREATE TABLE #UserInput (
    InputID INT,
    DateInput VARCHAR(50)
);

INSERT INTO #UserInput VALUES
(1, '2025-01-15'),
(2, '01/15/2025'),
(3, 'January 15, 2025'),
(4, 'Not a date'),
(5, '2025-13-45');

SELECT 
    InputID,
    DateInput,
    TRY_CONVERT(DATE, DateInput, 101) AS USFormat,        -- mm/dd/yyyy
    TRY_CONVERT(DATE, DateInput, 103) AS UKFormat,        -- dd/mm/yyyy
    TRY_CONVERT(DATE, DateInput, 120) AS ISOFormat,       -- yyyy-mm-dd
    CASE 
        WHEN TRY_CONVERT(DATE, DateInput) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid'
    END AS Status
FROM #UserInput;

DROP TABLE #UserInput;


/*
============================================================================
PART 4: String to Number Conversions
============================================================================
*/

-- Example 4.1: Clean and convert strings
SELECT 
    CAST(REPLACE('$1,234.56', '$', '') AS VARCHAR) AS Step1_RemoveDollar,
    CAST(REPLACE(REPLACE('$1,234.56', '$', ''), ',', '') AS DECIMAL(10,2)) AS Step2_ConvertToNumber;

-- Example 4.2: Handle different formats
SELECT 
    TRY_CAST(REPLACE(REPLACE('(123.45)', '(', '-'), ')', '') AS DECIMAL(10,2)) AS ParenthesesNegative,
    TRY_CAST(REPLACE(REPLACE('1,234.56', ',', ''), ' ', '') AS DECIMAL(10,2)) AS WithCommas,
    TRY_CAST(REPLACE('$999.99', '$', '') AS DECIMAL(10,2)) AS WithDollarSign;

-- Example 4.3: Phone numbers to numeric
CREATE TABLE #Phones (PhoneText VARCHAR(50));
INSERT INTO #Phones VALUES ('(555) 123-4567'), ('555-987-6543'), ('5551234567');

SELECT 
    PhoneText,
    TRY_CAST(
        REPLACE(REPLACE(REPLACE(REPLACE(PhoneText, '(', ''), ')', ''), '-', ''), ' ', '')
        AS BIGINT
    ) AS PhoneNumeric
FROM #Phones;

DROP TABLE #Phones;


/*
============================================================================
PART 5: String to Date Conversions
============================================================================
*/

-- Example 5.1: Different date formats
SELECT 
    TRY_CONVERT(DATE, '01/15/2025', 101) AS USA_MDY,         -- mm/dd/yyyy
    TRY_CONVERT(DATE, '15/01/2025', 103) AS UK_DMY,          -- dd/mm/yyyy
    TRY_CONVERT(DATE, '2025-01-15', 120) AS ISO,             -- yyyy-mm-dd
    TRY_CONVERT(DATE, '20250115', 112) AS Compact;           -- yyyymmdd

-- Example 5.2: Ambiguous dates - format matters!
SELECT 
    TRY_CONVERT(DATE, '01/02/2025', 101) AS USA_Format,      -- Jan 2, 2025
    TRY_CONVERT(DATE, '01/02/2025', 103) AS UK_Format;       -- Feb 1, 2025
-- Same string, different interpretations!

-- Example 5.3: Always use ISO format for clarity
-- ✅ BEST PRACTICE: Use ISO format (YYYY-MM-DD)
SELECT 
    CONVERT(DATE, '2025-01-15') AS UnambiguousDate;

-- Example 5.4: Parse text dates
CREATE TABLE #DateStrings (DateText VARCHAR(50));
INSERT INTO #DateStrings VALUES 
('January 15, 2025'),
('2025-01-15'),
('01/15/2025'),
('15-Jan-2025');

SELECT 
    DateText,
    TRY_CONVERT(DATE, DateText) AS ParsedDate,
    CASE 
        WHEN TRY_CONVERT(DATE, DateText) IS NOT NULL 
        THEN 'Valid' 
        ELSE 'Invalid' 
    END AS Status
FROM #DateStrings;

DROP TABLE #DateStrings;


/*
============================================================================
PART 6: Number to String Formatting
============================================================================
*/

-- Example 6.1: Basic number formatting
SELECT 
    CAST(1234.56 AS VARCHAR(20)) AS BasicCast,
    CONVERT(VARCHAR(20), 1234.56) AS BasicConvert,
    FORMAT(1234.56, 'N2') AS WithCommas,                     -- 1,234.56
    FORMAT(1234.56, 'C2') AS Currency;                       -- $1,234.56

-- Example 6.2: FORMAT function (SQL Server 2012+)
SELECT 
    FORMAT(1234567.89, 'N0') AS NoDecimals,                  -- 1,234,568
    FORMAT(1234567.89, 'N2') AS TwoDecimals,                 -- 1,234,567.89
    FORMAT(1234567.89, 'C') AS Currency,                     -- $1,234,567.89
    FORMAT(0.85, 'P0') AS Percentage;                        -- 85 %

-- Example 6.3: Custom number formats
SELECT 
    FORMAT(123, '000000') AS PaddedZeros,                    -- 000123
    FORMAT(1234.5, '0000.00') AS FixedWidth,                 -- 1234.50
    FORMAT(1234567, '#,##0') AS ThousandsSeparator;          -- 1,234,567

-- Example 6.4: Format prices
SELECT 
    ProductID,
    ProductName,
    Price,
    '$' + CAST(Price AS VARCHAR) AS SimplePrice,
    '$' + FORMAT(Price, 'N2') AS FormattedPrice,
    FORMAT(Price, 'C2') AS CurrencyPrice
FROM Products;


/*
============================================================================
PART 7: Implicit vs Explicit Conversion
============================================================================
*/

-- Example 7.1: Implicit conversion (automatic)
SELECT 
    '100' + '200' AS StringConcat,                           -- '100200' (string)
    100 + 200 AS IntAddition,                                -- 300 (int)
    '100' + 200 AS ImplicitConvert;                          -- 300 (SQL converts string to int)

-- Example 7.2: Implicit can cause errors
-- ❌ This will ERROR:
-- SELECT '100' + 'ABC';  
-- Error: Cannot convert 'ABC' to int

-- ✅ Be explicit:
SELECT CAST('100' AS INT) + CAST('200' AS INT) AS ExplicitConversion;

-- Example 7.3: Precedence matters
SELECT 
    10 / 3 AS IntegerDivision,                               -- 3 (int / int = int)
    10.0 / 3 AS DecimalDivision,                             -- 3.333... (decimal / int = decimal)
    CAST(10 AS DECIMAL(10,2)) / 3 AS ExplicitDecimal;       -- 3.33 (explicit)

-- Example 7.4: String concatenation with numbers
SELECT 
    'Total: ' + CAST(100 AS VARCHAR) AS WithCast,
    CONCAT('Total: ', 100) AS WithConcat;                    -- CONCAT handles conversion


/*
============================================================================
PART 8: Practical Conversion Scenarios
============================================================================
*/

-- Scenario 8.1: Import CSV data (all strings)
CREATE TABLE #CSVImport (
    OrderID_Text VARCHAR(50),
    OrderDate_Text VARCHAR(50),
    Amount_Text VARCHAR(50)
);

INSERT INTO #CSVImport VALUES
('1', '2025-01-15', '123.45'),
('2', '2025-01-16', '678.90'),
('3', 'Invalid', 'Not a number');  -- Bad data

-- Clean and convert:
SELECT 
    TRY_CAST(OrderID_Text AS INT) AS OrderID,
    TRY_CONVERT(DATE, OrderDate_Text, 120) AS OrderDate,
    TRY_CAST(Amount_Text AS DECIMAL(10,2)) AS Amount,
    CASE 
        WHEN TRY_CAST(OrderID_Text AS INT) IS NULL 
          OR TRY_CONVERT(DATE, OrderDate_Text, 120) IS NULL
          OR TRY_CAST(Amount_Text AS DECIMAL(10,2)) IS NULL
        THEN 'Invalid Row'
        ELSE 'Valid'
    END AS DataQuality
FROM #CSVImport;

DROP TABLE #CSVImport;

-- Scenario 8.2: Format report output
SELECT 
    ProductID,
    ProductName,
    FORMAT(Price, 'C2') AS UnitPrice,
    Stock,
    FORMAT(Price * Stock, 'C2') AS InventoryValue,
    CONVERT(VARCHAR, GETDATE(), 107) AS ReportDate
FROM Products;

-- Scenario 8.3: Safe division with conversion
SELECT 
    ProductID,
    Stock,
    100 AS TargetStock,
    CASE 
        WHEN Stock > 0 
        THEN CAST((CAST(Stock AS DECIMAL(10,2)) / 100) * 100 AS DECIMAL(5,2))
        ELSE 0 
    END AS PercentOfTarget
FROM Products;


/*
============================================================================
PART 9: Best Practices
============================================================================
*/

-- Best Practice 9.1: Use TRY_CAST/TRY_CONVERT for untrusted data
-- ❌ BAD: Will error on invalid data
-- SELECT CAST(UserInput AS INT) FROM UntrustedTable;

-- ✅ GOOD: Returns NULL for invalid data
-- SELECT TRY_CAST(UserInput AS INT) FROM UntrustedTable;

-- Best Practice 9.2: Always specify precision for DECIMAL
-- ❌ BAD:
-- SELECT CAST(Price AS DECIMAL) FROM Products;  -- Defaults to (18,0)!

-- ✅ GOOD:
SELECT CAST(Price AS DECIMAL(10,2)) FROM Products;

-- Best Practice 9.3: Use ISO date format (YYYY-MM-DD)
-- ❌ AMBIGUOUS:
-- SELECT CONVERT(DATE, '01/02/2025');  -- Jan 2 or Feb 1?

-- ✅ CLEAR:
SELECT CONVERT(DATE, '2025-01-15', 120);  -- Always Jan 15

-- Best Practice 9.4: Explicit is better than implicit
-- ❌ IMPLICIT:
SELECT 10 / 3;  -- Result: 3 (integer division)

-- ✅ EXPLICIT:
SELECT CAST(10 AS DECIMAL(10,2)) / 3;  -- Result: 3.33

-- Best Practice 9.5: CAST for portability, CONVERT for SQL Server features
-- Use CAST for standard SQL (works across databases)
-- Use CONVERT only when you need style codes or SQL Server specific features


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own:

1. Convert all product prices to formatted currency strings
2. Parse phone numbers from text to BIGINT
3. Safely convert user date input (multiple formats)
4. Format numbers with thousand separators
5. Create data quality report showing conversion success/failure

Solutions below ↓
*/

-- Solution 1: Format prices
SELECT 
    ProductID,
    ProductName,
    Price,
    '$' + FORMAT(Price, 'N2') AS FormattedPrice,
    FORMAT(Price, 'C2') AS CurrencyFormat
FROM Products;

-- Solution 2: Phone numbers
CREATE TABLE #PhoneData (Phone VARCHAR(50));
INSERT INTO #PhoneData VALUES ('(555) 123-4567'), ('555-999-8888');

SELECT 
    Phone,
    TRY_CAST(
        REPLACE(REPLACE(REPLACE(REPLACE(Phone, '(', ''), ')', ''), '-', ''), ' ', '')
        AS BIGINT
    ) AS PhoneNumber
FROM #PhoneData;

DROP TABLE #PhoneData;

-- Solution 3: Multi-format date parsing
CREATE TABLE #DateInputs (DateText VARCHAR(50));
INSERT INTO #DateInputs VALUES 
('2025-01-15'),
('01/15/2025'),
('15-Jan-2025'),
('Invalid');

SELECT 
    DateText,
    COALESCE(
        TRY_CONVERT(DATE, DateText, 120),  -- Try ISO
        TRY_CONVERT(DATE, DateText, 101),  -- Try USA
        TRY_CONVERT(DATE, DateText)        -- Try default
    ) AS ParsedDate
FROM #DateInputs;

DROP TABLE #DateInputs;

-- Solution 4: Thousand separators
SELECT 
    Stock,
    CAST(Stock AS VARCHAR) AS NoFormat,
    FORMAT(Stock, 'N0') AS WithCommas,
    FORMAT(Stock, '#,##0') AS CustomFormat
FROM Products;

-- Solution 5: Data quality report
CREATE TABLE #ImportData (
    RecordID INT,
    NumericField VARCHAR(50),
    DateField VARCHAR(50),
    AmountField VARCHAR(50)
);

INSERT INTO #ImportData VALUES
(1, '123', '2025-01-15', '456.78'),
(2, 'ABC', '2025-01-16', '123.45'),
(3, '789', 'Invalid', '999.99'),
(4, '456', '2025-01-17', 'Not a number');

SELECT 
    RecordID,
    CASE WHEN TRY_CAST(NumericField AS INT) IS NOT NULL THEN 'Valid' ELSE 'Invalid' END AS NumericStatus,
    CASE WHEN TRY_CONVERT(DATE, DateField) IS NOT NULL THEN 'Valid' ELSE 'Invalid' END AS DateStatus,
    CASE WHEN TRY_CAST(AmountField AS DECIMAL(10,2)) IS NOT NULL THEN 'Valid' ELSE 'Invalid' END AS AmountStatus,
    CASE 
        WHEN TRY_CAST(NumericField AS INT) IS NOT NULL 
         AND TRY_CONVERT(DATE, DateField) IS NOT NULL
         AND TRY_CAST(AmountField AS DECIMAL(10,2)) IS NOT NULL
        THEN 'All Valid'
        ELSE 'Has Errors'
    END AS OverallStatus
FROM #ImportData;

DROP TABLE #ImportData;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CAST vs CONVERT:
  • CAST: ANSI standard, portable
  • CONVERT: SQL Server specific, has style codes
  • Use CAST for portability
  • Use CONVERT when you need format control

✓ SAFE CONVERSIONS:
  • TRY_CAST returns NULL on failure
  • TRY_CONVERT returns NULL on failure
  • Use for untrusted/user input
  • Always validate results

✓ COMMON CONVERSIONS:
  • String to Number: TRY_CAST(str AS INT/DECIMAL)
  • String to Date: TRY_CONVERT(DATE, str, style)
  • Number to String: CAST/FORMAT
  • Date to String: CONVERT with style codes

✓ FORMAT FUNCTION:
  • N0, N2: Number with thousand separators
  • C, C2: Currency format
  • P0, P2: Percentage format
  • Custom patterns: 000000, #,##0.00

✓ STYLE CODES (CONVERT):
  • 101: mm/dd/yyyy (USA)
  • 103: dd/mm/yyyy (UK)
  • 120: yyyy-mm-dd hh:mi:ss (ODBC)
  • 126: ISO8601

✓ BEST PRACTICES:
  • Always specify precision for DECIMAL
  • Use ISO date format (YYYY-MM-DD)
  • Prefer explicit over implicit conversion
  • Use TRY_* for user input
  • Test with edge cases and invalid data
  • Document expected format in comments

✓ COMMON PITFALLS:
  • Integer division (10/3 = 3)
  • Ambiguous date formats
  • Missing precision in DECIMAL
  • Not handling NULL results from TRY_*
  • Assuming implicit conversion rules

============================================================================
CONGRATULATIONS! You've completed Chapter 07: Data Generation and Manipulation!

You now know how to:
✓ Generate and manipulate strings
✓ Perform arithmetic with precision
✓ Handle signed data (positive/negative)
✓ Work with time zones
✓ Generate and manipulate dates/times
✓ Convert between data types safely

Take the comprehensive test to validate your knowledge!
============================================================================
*/
