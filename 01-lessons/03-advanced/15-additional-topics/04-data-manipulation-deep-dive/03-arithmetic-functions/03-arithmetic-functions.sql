/*
============================================================================
Lesson 07.03 - Arithmetic Functions
============================================================================

Description:
Master mathematical operations and numeric functions in SQL Server.
Essential for calculations, statistics, and data analysis.

Topics Covered:
• Basic arithmetic operators (+, -, *, /, %)
• ABS (absolute value)
• ROUND, CEILING, FLOOR
• POWER and SQRT
• SIGN function
• Mathematical constants
• Order of operations

Prerequisites:
• Basic SELECT statements
• Understanding of data types

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic Arithmetic Operators
============================================================================
+  Addition
-  Subtraction
*  Multiplication
/  Division
%  Modulo (remainder)
*/

-- Example 1.1: Addition
SELECT 
    10 + 5 AS Addition,
    Price AS OriginalPrice,
    Price + 10 AS PriceIncrease
FROM Products
WHERE ProductID = 1;

-- Example 1.2: Subtraction
SELECT 
    10 - 3 AS Subtraction,
    Price AS OriginalPrice,
    Price - 5 AS Discount
FROM Products
WHERE ProductID = 1;

-- Example 1.3: Multiplication
SELECT 
    Price,
    Quantity,
    Price * Quantity AS LineTotal
FROM OrderDetails
WHERE OrderDetailID <= 5;

-- Example 1.4: Division
SELECT 
    TotalAmount,
    TotalAmount / 2 AS HalfAmount
FROM Orders
WHERE OrderID <= 5;

-- ⚠️ CRITICAL: Integer Division Trap!
SELECT 
    5 / 2 AS IntegerDivision,      -- Result: 2 (not 2.5!)
    5.0 / 2 AS DecimalDivision,    -- Result: 2.5 ✓
    5 / 2.0 AS AlsoDecimal,        -- Result: 2.5 ✓
    CAST(5 AS DECIMAL) / 2 AS CastToDecimal;  -- Result: 2.5 ✓

-- Example 1.5: Calculate percentage (watch out for integer division!)
SELECT 
    ProductName,
    Stock,
    100 AS TotalInventory,
    -- ❌ WRONG:
    Stock / 100 AS WrongPercentage,         -- Integer division!
    -- ✅ CORRECT:
    (Stock * 100.0) / 100 AS CorrectPercentage,
    CAST(Stock AS DECIMAL(10,2)) / 100 * 100 AS AlsoCorrect
FROM Products
WHERE ProductID <= 5;

-- Example 1.6: Modulo (remainder) operator
SELECT 
    10 % 3 AS Remainder,           -- Result: 1 (10 ÷ 3 = 3 remainder 1)
    15 % 4 AS Remainder2,          -- Result: 3
    20 % 5 AS Remainder3;          -- Result: 0 (divides evenly)

-- Example 1.7: Check if number is even or odd
SELECT 
    ProductID,
    ProductID % 2 AS Remainder,
    CASE 
        WHEN ProductID % 2 = 0 THEN 'Even'
        ELSE 'Odd'
    END AS EvenOrOdd
FROM Products;


/*
============================================================================
PART 2: Order of Operations (PEMDAS)
============================================================================
Parentheses, Exponents, Multiplication/Division, Addition/Subtraction
*/

-- Example 2.1: Without parentheses
SELECT 
    5 + 3 * 2 AS WithoutParens;    -- Result: 11 (3*2=6, then 6+5=11)

-- Example 2.2: With parentheses
SELECT 
    (5 + 3) * 2 AS WithParens;     -- Result: 16 (5+3=8, then 8*2=16)

-- Example 2.3: Complex calculation - discount and tax
SELECT 
    ProductName,
    Price,
    -- Wrong order:
    Price - 10 + Price * 0.08 AS WrongCalculation,
    -- Correct with parentheses:
    (Price - 10) * 1.08 AS CorrectCalculation  -- Discount first, then tax
FROM Products
WHERE ProductID = 1;

-- Example 2.4: Calculate total with discount and tax
SELECT 
    od.Quantity,
    od.UnitPrice,
    -- Step by step:
    od.Quantity * od.UnitPrice AS Subtotal,
    od.Quantity * od.UnitPrice * 0.10 AS Discount,
    (od.Quantity * od.UnitPrice - od.Quantity * od.UnitPrice * 0.10) AS AfterDiscount,
    (od.Quantity * od.UnitPrice - od.Quantity * od.UnitPrice * 0.10) * 1.08 AS FinalTotal
FROM OrderDetails od
WHERE od.OrderDetailID = 1;


/*
============================================================================
PART 3: ABS (Absolute Value)
============================================================================
Returns the positive value of a number.

Syntax: ABS(numeric_expression)
*/

-- Example 3.1: Basic absolute value
SELECT 
    -10 AS NegativeNumber,
    ABS(-10) AS AbsoluteValue,     -- Result: 10
    10 AS PositiveNumber,
    ABS(10) AS StillPositive;      -- Result: 10

-- Example 3.2: Calculate price difference (always positive)
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    ABS(p1.Price - p2.Price) AS PriceDifference
FROM Products p1
CROSS JOIN Products p2
WHERE p1.ProductID = 1 AND p2.ProductID = 2;

-- Example 3.3: Find variance from average
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AveragePrice,
    ABS(Price - (SELECT AVG(Price) FROM Products)) AS VarianceFromAverage
FROM Products;

-- Example 3.4: Calculate absolute margin
SELECT 
    od.UnitPrice AS SoldPrice,
    p.Price AS CurrentPrice,
    ABS(od.UnitPrice - p.Price) AS AbsoluteDifference,
    CASE 
        WHEN od.UnitPrice > p.Price THEN 'Sold Higher'
        WHEN od.UnitPrice < p.Price THEN 'Sold Lower'
        ELSE 'Same Price'
    END AS PriceComparison
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
WHERE od.OrderDetailID <= 5;


/*
============================================================================
PART 4: ROUND Function
============================================================================
Rounds a number to specified decimal places.

Syntax: ROUND(numeric_expression, length [, function])
  length: number of decimal places
  function: 0 = round (default), 1 = truncate
*/

-- Example 4.1: Basic rounding
SELECT 
    123.456 AS Original,
    ROUND(123.456, 2) AS RoundTo2,     -- Result: 123.46
    ROUND(123.456, 1) AS RoundTo1,     -- Result: 123.5
    ROUND(123.456, 0) AS RoundTo0;     -- Result: 123

-- Example 4.2: Rounding negative decimals
SELECT 
    123.456 AS Original,
    ROUND(123.456, -1) AS RoundToTens,      -- Result: 120
    ROUND(123.456, -2) AS RoundToHundreds;  -- Result: 100

-- Example 4.3: Truncate instead of round
SELECT 
    123.456 AS Original,
    ROUND(123.456, 2) AS Rounded,      -- Result: 123.46 (rounds up)
    ROUND(123.456, 2, 1) AS Truncated; -- Result: 123.45 (cuts off)

-- Example 4.4: Round prices for display
SELECT 
    ProductName,
    Price AS ExactPrice,
    ROUND(Price, 2) AS DisplayPrice,
    ROUND(Price, 0) AS DollarPrice
FROM Products;

-- Example 4.5: Calculate discounted price with rounding
SELECT 
    ProductName,
    Price,
    ROUND(Price * 0.85, 2) AS DiscountedPrice,  -- 15% off, rounded
    ROUND(Price * 0.85 * 1.08, 2) AS WithTax    -- + 8% tax, rounded
FROM Products;


/*
============================================================================
PART 5: CEILING and FLOOR Functions
============================================================================
CEILING - Round UP to nearest integer
FLOOR - Round DOWN to nearest integer
*/

-- Example 5.1: CEILING (always rounds up)
SELECT 
    4.1 AS Original,
    CEILING(4.1) AS Ceiling,       -- Result: 5
    CEILING(4.9) AS Ceiling2,      -- Result: 5
    CEILING(-4.1) AS NegCeiling;   -- Result: -4 (up toward zero)

-- Example 5.2: FLOOR (always rounds down)
SELECT 
    4.9 AS Original,
    FLOOR(4.9) AS Floor,           -- Result: 4
    FLOOR(4.1) AS Floor2,          -- Result: 4
    FLOOR(-4.9) AS NegFloor;       -- Result: -5 (down away from zero)

-- Example 5.3: Calculate shipping boxes needed
SELECT 
    ProductName,
    Stock,
    CEILING(Stock / 10.0) AS BoxesNeeded  -- Each box holds 10 units
FROM Products;

-- Example 5.4: Price buckets
SELECT 
    ProductName,
    Price,
    FLOOR(Price / 10) * 10 AS PriceBucket,
    CAST(FLOOR(Price / 10) * 10 AS VARCHAR) + '-' + 
    CAST(CEILING(Price / 10) * 10 AS VARCHAR) AS PriceRange
FROM Products;

-- Example 5.5: Round to nearest 5
SELECT 
    Price,
    FLOOR(Price / 5) * 5 AS RoundDownTo5,
    CEILING(Price / 5) * 5 AS RoundUpTo5,
    ROUND(Price / 5, 0) * 5 AS RoundNearestTo5
FROM Products;


/*
============================================================================
PART 6: POWER and SQRT Functions
============================================================================
POWER - Raise number to a power
SQRT - Square root
*/

-- Example 6.1: POWER function
SELECT 
    2 AS Base,
    3 AS Exponent,
    POWER(2, 3) AS Result;         -- Result: 8 (2³ = 2*2*2)

-- Example 6.2: Calculate compound interest
DECLARE @Principal DECIMAL(10,2) = 1000;
DECLARE @Rate DECIMAL(5,4) = 0.05;  -- 5%
DECLARE @Years INT = 10;

SELECT 
    @Principal AS InitialAmount,
    @Rate * 100 AS InterestRate,
    @Years AS Years,
    @Principal * POWER(1 + @Rate, @Years) AS FutureValue,
    @Principal * POWER(1 + @Rate, @Years) - @Principal AS InterestEarned;

-- Example 6.3: Square root
SELECT 
    16 AS Number,
    SQRT(16) AS SquareRoot,        -- Result: 4
    POWER(16, 0.5) AS AlsoSqrt;    -- Result: 4 (same thing)

-- Example 6.4: Calculate distance (Pythagorean theorem)
DECLARE @SideA DECIMAL(10,2) = 3;
DECLARE @SideB DECIMAL(10,2) = 4;

SELECT 
    @SideA AS SideA,
    @SideB AS SideB,
    SQRT(POWER(@SideA, 2) + POWER(@SideB, 2)) AS Hypotenuse;
-- Result: 5

-- Example 6.5: Exponential growth calculation
SELECT 
    Year,
    1000 * POWER(1.1, Year) AS Value  -- 10% growth per year
FROM (VALUES (0), (1), (2), (3), (4), (5)) AS Years(Year);


/*
============================================================================
PART 7: SIGN Function
============================================================================
Returns -1 for negative, 0 for zero, 1 for positive.

Syntax: SIGN(numeric_expression)
*/

-- Example 7.1: Basic SIGN function
SELECT 
    -10 AS Negative,
    SIGN(-10) AS Sign1,            -- Result: -1
    0 AS Zero,
    SIGN(0) AS Sign2,              -- Result: 0
    10 AS Positive,
    SIGN(10) AS Sign3;             -- Result: 1

-- Example 7.2: Determine profit or loss
SELECT 
    ProductName,
    Price,
    50 AS Cost,
    Price - 50 AS Margin,
    CASE SIGN(Price - 50)
        WHEN 1 THEN 'Profit'
        WHEN 0 THEN 'Break Even'
        WHEN -1 THEN 'Loss'
    END AS Status
FROM Products;

-- Example 7.3: Count positive vs negative values
SELECT 
    SUM(CASE WHEN SIGN(Price - 50) = 1 THEN 1 ELSE 0 END) AS Profitable,
    SUM(CASE WHEN SIGN(Price - 50) = 0 THEN 1 ELSE 0 END) AS BreakEven,
    SUM(CASE WHEN SIGN(Price - 50) = -1 THEN 1 ELSE 0 END) AS Losses
FROM Products;


/*
============================================================================
PART 8: Combining Arithmetic Functions
============================================================================
*/

-- Example 8.1: Price analysis with multiple functions
SELECT 
    ProductName,
    Price,
    ROUND(Price, 0) AS RoundedPrice,
    CEILING(Price) AS CeilingPrice,
    FLOOR(Price) AS FloorPrice,
    ABS(Price - ROUND(Price, 0)) AS RoundingDifference,
    SIGN(Price - 100) AS ComparedTo100
FROM Products;

-- Example 8.2: Calculate statistics
SELECT 
    AVG(Price) AS AvgPrice,
    ROUND(AVG(Price), 2) AS RoundedAvg,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    MAX(Price) - MIN(Price) AS PriceRange,
    SQRT(
        SUM(POWER(Price - AVG(Price), 2)) / COUNT(*)
    ) AS StandardDeviation
FROM Products;

-- Example 8.3: Complex pricing calculation
SELECT 
    ProductName,
    Price AS OriginalPrice,
    ROUND(Price * 0.85, 2) AS After15PercentOff,
    CEILING(ROUND(Price * 0.85, 2)) AS RoundedUpPrice,
    FLOOR(ROUND(Price * 0.85, 2) / 5) * 5 AS RoundedTo5,
    POWER(Price / 100, 2) AS PriceSquared
FROM Products;


/*
============================================================================
PART 9: Practical Applications
============================================================================
*/

-- Application 9.1: Tiered commission calculation
SELECT 
    o.OrderID,
    o.TotalAmount,
    CASE 
        WHEN o.TotalAmount >= 1000 THEN ROUND(o.TotalAmount * 0.10, 2)
        WHEN o.TotalAmount >= 500 THEN ROUND(o.TotalAmount * 0.05, 2)
        ELSE ROUND(o.TotalAmount * 0.02, 2)
    END AS Commission
FROM Orders o;

-- Application 9.2: Inventory replenishment (round up to case size)
SELECT 
    ProductName,
    Stock AS CurrentStock,
    100 AS TargetStock,
    100 - Stock AS UnitsNeeded,
    CEILING((100 - Stock) / 12.0) AS CasesNeeded,  -- 12 per case
    CEILING((100 - Stock) / 12.0) * 12 AS UnitsToOrder
FROM Products
WHERE Stock < 100;

-- Application 9.3: Progressive tax brackets
DECLARE @Income DECIMAL(10,2) = 75000;

SELECT 
    @Income AS TotalIncome,
    -- First $10k at 10%
    10000 * 0.10 AS Bracket1Tax,
    -- Next $30k at 20%
    30000 * 0.20 AS Bracket2Tax,
    -- Remainder at 30%
    CASE 
        WHEN @Income > 40000 THEN (@Income - 40000) * 0.30
        ELSE 0
    END AS Bracket3Tax,
    -- Total
    ROUND(
        10000 * 0.10 + 
        30000 * 0.20 + 
        CASE WHEN @Income > 40000 THEN (@Income - 40000) * 0.30 ELSE 0 END,
        2
    ) AS TotalTax;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions below:

1. Calculate 15% discount on all products, rounded to 2 decimals
2. Find how many full boxes of 24 units you can ship for each product
3. Calculate the square root of each product's price
4. Determine if each product's price is above or below average
5. Round all prices to nearest $5

Solutions below ↓
*/

-- Solution 1: 15% discount
SELECT 
    ProductName,
    Price,
    ROUND(Price * 0.85, 2) AS DiscountedPrice
FROM Products;

-- Solution 2: Full boxes (24 per box)
SELECT 
    ProductName,
    Stock,
    FLOOR(Stock / 24.0) AS FullBoxes,
    Stock % 24 AS RemainingUnits
FROM Products;

-- Solution 3: Square root of price
SELECT 
    ProductName,
    Price,
    ROUND(SQRT(Price), 2) AS SqrtPrice
FROM Products;

-- Solution 4: Above/below average
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    SIGN(Price - (SELECT AVG(Price) FROM Products)) AS Comparison,
    CASE SIGN(Price - (SELECT AVG(Price) FROM Products))
        WHEN 1 THEN 'Above Average'
        WHEN 0 THEN 'At Average'
        ELSE 'Below Average'
    END AS Status
FROM Products;

-- Solution 5: Round to nearest $5
SELECT 
    ProductName,
    Price,
    ROUND(Price / 5, 0) * 5 AS RoundedTo5
FROM Products;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ ARITHMETIC OPERATORS:
  • + - * / % (modulo for remainder)
  • Watch out for integer division!
  • Use parentheses to control order

✓ ROUNDING:
  • ROUND(n, decimals) - Round to decimals
  • CEILING(n) - Always round up
  • FLOOR(n) - Always round down

✓ OTHER FUNCTIONS:
  • ABS(n) - Absolute value
  • POWER(base, exp) - Exponentiation
  • SQRT(n) - Square root
  • SIGN(n) - -1, 0, or 1

✓ BEST PRACTICES:
  • Always use DECIMAL for money calculations
  • Round monetary values to 2 decimals
  • Be explicit with data type conversions
  • Test edge cases (0, negative, very large)
  • Consider order of operations

✓ COMMON PITFALLS:
  • Integer division: 5/2 = 2 (not 2.5!)
  • Forgetting to round monetary values
  • Not handling division by zero
  • Precision loss with FLOAT/REAL

============================================================================
NEXT: Lesson 07.04 - Number Precision
Learn about DECIMAL, NUMERIC, and precision management.
============================================================================
*/
