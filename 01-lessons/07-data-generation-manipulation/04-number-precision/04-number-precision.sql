/*
============================================================================
Lesson 07.04 - Number Precision
============================================================================

Description:
Master numeric data types, precision, and scale in SQL Server.
Understanding precision is critical for accurate calculations, especially
with money and scientific data.

Topics Covered:
• DECIMAL and NUMERIC types
• Precision and scale
• FLOAT vs DECIMAL
• Money calculations
• Precision loss and overflow
• CAST and CONVERT for numbers
• Rounding strategies

Prerequisites:
• Lesson 07.03 - Arithmetic Functions
• Understanding of data types

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Precision and Scale
============================================================================
DECIMAL(precision, scale)
  precision = total number of digits
  scale = digits after decimal point

Example: DECIMAL(10,2)
  - Total: 10 digits
  - After decimal: 2 digits
  - Max value: 99999999.99
*/

-- Example 1.1: Different precisions
SELECT 
    CAST(123.456 AS DECIMAL(5,2)) AS Decimal_5_2,    -- 123.46 (rounded)
    CAST(123.456 AS DECIMAL(6,3)) AS Decimal_6_3,    -- 123.456 (exact)
    CAST(123.456 AS DECIMAL(10,4)) AS Decimal_10_4;  -- 123.4560

-- Example 1.2: Scale determines decimal places
SELECT 
    CAST(99.999 AS DECIMAL(5,0)) AS Scale0,    -- 100 (rounded to integer)
    CAST(99.999 AS DECIMAL(5,1)) AS Scale1,    -- 100.0 (1 decimal)
    CAST(99.999 AS DECIMAL(5,2)) AS Scale2,    -- 100.00 (2 decimals)
    CAST(99.999 AS DECIMAL(5,3)) AS Scale3;    -- 99.999 (3 decimals)

-- Example 1.3: Maximum values by precision
SELECT 
    CAST(999.99 AS DECIMAL(5,2)) AS Max_5_2,           -- 999.99
    CAST(9999999.99 AS DECIMAL(9,2)) AS Max_9_2,       -- 9999999.99
    CAST(999999999999.99 AS DECIMAL(14,2)) AS Max_14_2; -- For money

-- Example 1.4: Precision too small causes overflow error
-- ❌ This will ERROR:
-- SELECT CAST(12345.67 AS DECIMAL(5,2));  
-- Error: Arithmetic overflow (needs at least DECIMAL(7,2))

-- ✅ Correct precision:
SELECT CAST(12345.67 AS DECIMAL(7,2)) AS CorrectPrecision;


/*
============================================================================
PART 2: DECIMAL vs NUMERIC vs FLOAT
============================================================================
DECIMAL/NUMERIC: Exact precision (use for money!)
FLOAT/REAL: Approximate precision (use for scientific)
*/

-- Example 2.1: DECIMAL vs NUMERIC (they're identical)
SELECT 
    CAST(123.45 AS DECIMAL(10,2)) AS DecimalValue,
    CAST(123.45 AS NUMERIC(10,2)) AS NumericValue;
-- Result: Both are 123.45 (no difference)

-- Example 2.2: FLOAT approximation issues
SELECT 
    CAST(0.1 AS FLOAT) + CAST(0.2 AS FLOAT) AS FloatResult,
    CAST(0.1 AS DECIMAL(10,2)) + CAST(0.2 AS DECIMAL(10,2)) AS DecimalResult;
-- Float: 0.30000000000000004 (approximation error!)
-- Decimal: 0.30 (exact!)

-- Example 2.3: Why NEVER use FLOAT for money
DECLARE @FloatPrice FLOAT = 19.99;
DECLARE @DecimalPrice DECIMAL(10,2) = 19.99;

SELECT 
    @FloatPrice * 3 AS FloatTotal,      -- 59.97000000000001
    @DecimalPrice * 3 AS DecimalTotal;  -- 59.97 (exact!)

-- Example 2.4: Storage size comparison
-- INT: 4 bytes
-- DECIMAL(9,2): 5 bytes
-- DECIMAL(18,2): 9 bytes
-- FLOAT: 8 bytes
-- Use appropriate size for your needs

-- Example 2.5: When to use FLOAT
-- Scientific calculations where approximation is acceptable:
SELECT 
    POWER(CAST(2.0 AS FLOAT), 100) AS LargeExponent,  -- 1.26765e+30
    SQRT(CAST(2.0 AS FLOAT)) AS SquareRoot;           -- 1.4142135623731


/*
============================================================================
PART 3: Money Data Type
============================================================================
MONEY: Special type for currency (4 decimal places, fixed precision)
Range: -922,337,203,685,477.5808 to 922,337,203,685,477.5807
*/

-- Example 3.1: MONEY vs DECIMAL
SELECT 
    CAST(19.99 AS MONEY) AS MoneyValue,
    CAST(19.99 AS DECIMAL(10,2)) AS DecimalValue;

-- Example 3.2: MONEY automatic rounding to 4 decimals
SELECT 
    CAST(19.123456 AS MONEY) AS MoneyRounded;  -- 19.1235 (rounds to 4)

-- Example 3.3: MONEY calculations
DECLARE @Price MONEY = 19.99;
DECLARE @Quantity INT = 3;

SELECT 
    @Price AS UnitPrice,
    @Quantity AS Quantity,
    @Price * @Quantity AS Total,
    (@Price * @Quantity) * 0.08 AS Tax;

-- Example 3.4: Convert MONEY to DECIMAL for display
SELECT 
    ProductID,
    ProductName,
    Price,
    CAST(Price AS DECIMAL(10,2)) AS DisplayPrice
FROM Products;

-- Example 3.5: MONEY vs DECIMAL for business
-- ✅ MONEY: Good for simple currency (faster, less storage)
-- ✅ DECIMAL(19,4): Good for high precision financial calculations
-- ✅ DECIMAL(10,2): Good for typical business prices


/*
============================================================================
PART 4: Precision Loss in Calculations
============================================================================
*/

-- Example 4.1: Division precision loss
SELECT 
    10 / 3 AS IntDivision,              -- 3 (loses precision)
    10.0 / 3 AS DecimalDivision,        -- 3.333333...
    CAST(10 AS DECIMAL(10,5)) / 3 AS HighPrecision;  -- 3.33333

-- Example 4.2: Multiplication precision growth
DECLARE @Value1 DECIMAL(5,2) = 123.45;
DECLARE @Value2 DECIMAL(5,2) = 67.89;

SELECT 
    @Value1 * @Value2 AS Result,                    -- 8379.6405
    CAST(@Value1 * @Value2 AS DECIMAL(10,2)) AS Rounded;  -- 8379.64

-- Example 4.3: Chain calculations accumulate errors
SELECT 
    ((10.0 / 3) * 3) AS ChainCalculation,   -- 10.000000 (not exactly 10)
    10.0 AS Original;

-- Example 4.4: Order of operations affects precision
DECLARE @Price DECIMAL(10,2) = 100.00;

SELECT 
    @Price * 0.1 / 0.1 AS Method1,      -- Might lose precision
    @Price * (0.1 / 0.1) AS Method2;    -- Simplifies to @Price * 1

-- Example 4.5: Percentage calculations
SELECT 
    ProductName,
    Price,
    Stock,
    -- ❌ Wrong: Integer division
    Stock / 100 AS WrongPercent,
    -- ✅ Correct: Decimal division
    CAST(Stock AS DECIMAL(10,2)) / 100 AS CorrectPercent
FROM Products;


/*
============================================================================
PART 5: Rounding and Truncation
============================================================================
*/

-- Example 5.1: Different rounding methods
DECLARE @Value DECIMAL(10,5) = 123.45678;

SELECT 
    @Value AS Original,
    ROUND(@Value, 2) AS RoundTo2,           -- 123.46000 (rounds)
    ROUND(@Value, 2, 1) AS TruncateTo2,     -- 123.45000 (truncates)
    CAST(@Value AS DECIMAL(10,2)) AS CastTo2,  -- 123.46 (rounds)
    FLOOR(@Value) AS FloorValue,            -- 123 (always down)
    CEILING(@Value) AS CeilingValue;        -- 124 (always up)

-- Example 5.2: Banker's rounding (round to even)
-- SQL Server uses "round half up" by default
SELECT 
    ROUND(2.5, 0) AS Round_2_5,    -- 3 (up)
    ROUND(3.5, 0) AS Round_3_5;    -- 4 (up)

-- Example 5.3: Consistent rounding for money
SELECT 
    ProductName,
    Price,
    Price * 0.85 AS DiscountCalculation,
    ROUND(Price * 0.85, 2) AS DiscountRounded,
    CAST(ROUND(Price * 0.85, 2) AS DECIMAL(10,2)) AS FinalPrice
FROM Products;

-- Example 5.4: Round before storing
-- Good practice: Round at the calculation point
SELECT 
    OrderID,
    Quantity,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS LineTotal
FROM OrderDetails
WHERE OrderID = 1;


/*
============================================================================
PART 6: CAST vs CONVERT for Numbers
============================================================================
*/

-- Example 6.1: CAST (ANSI standard)
SELECT 
    CAST(123.456 AS INT) AS CastToInt,                -- 123
    CAST(123.456 AS DECIMAL(5,2)) AS CastToDecimal,   -- 123.46
    CAST('123.45' AS DECIMAL(10,2)) AS CastFromString; -- 123.45

-- Example 6.2: CONVERT (SQL Server specific)
SELECT 
    CONVERT(INT, 123.456) AS ConvertToInt,
    CONVERT(DECIMAL(5,2), 123.456) AS ConvertToDecimal,
    CONVERT(DECIMAL(10,2), '123.45') AS ConvertFromString;

-- Example 6.3: TRY_CAST for safe conversion
SELECT 
    TRY_CAST('123.45' AS DECIMAL(10,2)) AS ValidConversion,   -- 123.45
    TRY_CAST('ABC' AS DECIMAL(10,2)) AS InvalidConversion,    -- NULL (no error)
    TRY_CAST('999999' AS DECIMAL(5,2)) AS OverflowConversion; -- NULL

-- Example 6.4: Convert string to number safely
SELECT 
    CustomerID,
    Phone,
    TRY_CAST(REPLACE(REPLACE(REPLACE(Phone, '-', ''), '(', ''), ')', '') AS BIGINT) AS PhoneNumeric
FROM Customers
WHERE Phone IS NOT NULL;


/*
============================================================================
PART 7: Overflow and Underflow
============================================================================
*/

-- Example 7.1: Arithmetic overflow error
-- ❌ This will ERROR:
-- DECLARE @TooSmall DECIMAL(5,2) = 999.99;
-- SELECT @TooSmall * 1000;  -- Result needs DECIMAL(8,2) or larger

-- ✅ Correct: Use appropriate precision
DECLARE @Correct DECIMAL(10,2) = 999.99;
SELECT @Correct * 1000 AS Result;  -- 999990.00

-- Example 7.2: Detecting potential overflow
SELECT 
    ProductName,
    Price,
    Stock,
    CASE 
        WHEN Price * Stock > 999999.99 THEN 'Potential Overflow'
        ELSE 'OK'
    END AS OverflowCheck,
    TRY_CAST(Price * Stock AS DECIMAL(10,2)) AS TotalValue
FROM Products;

-- Example 7.3: Scale overflow (too many decimals)
SELECT 
    1.0 / 3.0 AS Division,                  -- 0.333333
    CAST(1.0 / 3.0 AS DECIMAL(20,10)) AS HighPrecision;  -- 0.3333333333


/*
============================================================================
PART 8: Practical Money Calculations
============================================================================
*/

-- Example 8.1: Calculate invoice totals with tax
SELECT 
    o.OrderID,
    SUM(od.Quantity * od.UnitPrice) AS Subtotal,
    ROUND(SUM(od.Quantity * od.UnitPrice) * 0.08, 2) AS Tax,
    ROUND(SUM(od.Quantity * od.UnitPrice) * 1.08, 2) AS Total,
    -- Alternative: Add rounded tax to subtotal
    SUM(od.Quantity * od.UnitPrice) + ROUND(SUM(od.Quantity * od.UnitPrice) * 0.08, 2) AS AlternateTotal
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID;

-- Example 8.2: Multi-tiered discount calculation
SELECT 
    ProductName,
    Price,
    Stock,
    CASE 
        WHEN Stock >= 100 THEN ROUND(Price * 0.85, 2)  -- 15% off
        WHEN Stock >= 50 THEN ROUND(Price * 0.90, 2)   -- 10% off
        WHEN Stock >= 20 THEN ROUND(Price * 0.95, 2)   -- 5% off
        ELSE Price
    END AS DiscountedPrice,
    ROUND(
        Price - CASE 
            WHEN Stock >= 100 THEN ROUND(Price * 0.85, 2)
            WHEN Stock >= 50 THEN ROUND(Price * 0.90, 2)
            WHEN Stock >= 20 THEN ROUND(Price * 0.95, 2)
            ELSE Price
        END, 2
    ) AS Savings
FROM Products;

-- Example 8.3: Commission calculation with precision
SELECT 
    o.OrderID,
    o.TotalAmount,
    CASE 
        WHEN o.TotalAmount >= 1000 THEN CAST(o.TotalAmount * 0.10 AS DECIMAL(10,2))
        WHEN o.TotalAmount >= 500 THEN CAST(o.TotalAmount * 0.05 AS DECIMAL(10,2))
        ELSE CAST(o.TotalAmount * 0.02 AS DECIMAL(10,2))
    END AS Commission
FROM Orders o;

-- Example 8.4: Price adjustment with rounding
SELECT 
    ProductName,
    Price AS OldPrice,
    ROUND(Price * 1.05, 2) AS NewPrice_5Percent,
    ROUND(Price * 1.05, 0) AS RoundedToDollar,
    CEILING(Price * 1.05) AS RoundUpToDollar,
    FLOOR(Price * 1.05 / 5) * 5 AS RoundedTo5Dollars
FROM Products;


/*
============================================================================
PART 9: Best Practices
============================================================================
*/

-- Best Practice 9.1: Always specify precision for DECIMAL
-- ❌ BAD: 
-- DECLARE @Price DECIMAL;  -- Defaults to DECIMAL(18,0)!

-- ✅ GOOD:
DECLARE @Price DECIMAL(10,2);  -- Explicit precision

-- Best Practice 9.2: Use DECIMAL for money, not FLOAT
-- ❌ BAD:
DECLARE @BadPrice FLOAT = 19.99;

-- ✅ GOOD:
DECLARE @GoodPrice DECIMAL(10,2) = 19.99;

-- Best Practice 9.3: Round at calculation time, not storage time
-- ✅ GOOD:
SELECT 
    OrderID,
    ROUND(Quantity * UnitPrice, 2) AS LineTotal
FROM OrderDetails;

-- Best Practice 9.4: Use appropriate precision
SELECT 
    -- Typical prices: DECIMAL(10,2)
    CAST(19.99 AS DECIMAL(10,2)) AS ProductPrice,
    -- High precision finance: DECIMAL(19,4)
    CAST(0.0575 AS DECIMAL(19,4)) AS InterestRate,
    -- Percentages: DECIMAL(5,2)
    CAST(15.75 AS DECIMAL(5,2)) AS DiscountPercent;

-- Best Practice 9.5: Test for overflow in calculations
SELECT 
    ProductID,
    Price,
    Stock,
    CASE 
        WHEN TRY_CAST(Price * Stock AS DECIMAL(18,2)) IS NULL 
        THEN 'Overflow Risk!'
        ELSE CAST(Price * Stock AS VARCHAR)
    END AS InventoryValue
FROM Products;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions below:

1. Convert all prices to DECIMAL(10,2) and calculate 7.5% tax
2. Find products where Price * Stock exceeds DECIMAL(10,2) capacity
3. Calculate commission with DECIMAL(10,4) precision
4. Round prices to nearest $0.25
5. Compare FLOAT vs DECIMAL accuracy over 1000 iterations

Solutions below ↓
*/

-- Solution 1: Price with tax
SELECT 
    ProductID,
    ProductName,
    CAST(Price AS DECIMAL(10,2)) AS Price,
    CAST(Price * 1.075 AS DECIMAL(10,2)) AS PriceWithTax,
    CAST(Price * 0.075 AS DECIMAL(10,2)) AS TaxAmount
FROM Products;

-- Solution 2: Find overflow risk
SELECT 
    ProductID,
    ProductName,
    Price,
    Stock,
    Price * Stock AS CalculatedValue,
    CASE 
        WHEN Price * Stock > 99999999.99 THEN 'Overflow Risk'
        ELSE 'OK'
    END AS Status
FROM Products
WHERE TRY_CAST(Price * Stock AS DECIMAL(10,2)) IS NULL
   OR Price * Stock > 99999999.99;

-- Solution 3: High precision commission
SELECT 
    OrderID,
    TotalAmount,
    CAST(TotalAmount * 0.0575 AS DECIMAL(10,4)) AS Commission
FROM Orders;

-- Solution 4: Round to $0.25
SELECT 
    ProductName,
    Price,
    ROUND(Price * 4, 0) / 4 AS RoundedToQuarter
FROM Products;

-- Solution 5: FLOAT vs DECIMAL accumulation
DECLARE @FloatSum FLOAT = 0;
DECLARE @DecimalSum DECIMAL(18,10) = 0;
DECLARE @Counter INT = 1;

WHILE @Counter <= 1000
BEGIN
    SET @FloatSum = @FloatSum + 0.1;
    SET @DecimalSum = @DecimalSum + 0.1;
    SET @Counter = @Counter + 1;
END

SELECT 
    @FloatSum AS FloatResult,           -- Approximation errors
    @DecimalSum AS DecimalResult,       -- Exact: 100.0000000000
    @FloatSum - 100 AS FloatError,
    @DecimalSum - 100 AS DecimalError;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ PRECISION AND SCALE:
  • DECIMAL(p, s): p=total digits, s=after decimal
  • Choose appropriate size for your data
  • Too small = overflow errors
  • Too large = wasted storage

✓ DATA TYPES:
  • DECIMAL/NUMERIC: Exact (use for money!)
  • MONEY: Fixed 4 decimals
  • FLOAT/REAL: Approximate (scientific only)
  • INT: Whole numbers only

✓ CALCULATIONS:
  • Always specify precision explicitly
  • Round at calculation time
  • Watch for overflow in multiplications
  • Use TRY_CAST for safe conversions

✓ MONEY BEST PRACTICES:
  • DECIMAL(10,2) for typical prices
  • DECIMAL(19,4) for high precision finance
  • Never use FLOAT for currency
  • Round before storing

✓ COMMON PITFALLS:
  • Integer division: 10/3 = 3
  • Precision loss in chain calculations
  • Overflow with inadequate precision
  • Float approximation errors

============================================================================
NEXT: Lesson 07.05 - Signed Data
Learn to work with positive and negative numbers effectively.
============================================================================
*/
