/*
============================================================================
Lesson 07.05 - Signed Data
============================================================================

Description:
Work with positive and negative numbers, understand signed data types,
and handle scenarios involving credits, debits, gains, and losses.

Topics Covered:
• Signed vs unsigned integers
• SIGN function
• ABS function revisited
• Working with negative numbers
• Credits and debits
• Gains and losses
• Balance calculations

Prerequisites:
• Lesson 07.03 - Arithmetic Functions
• Lesson 07.04 - Number Precision

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Signed Data Types
============================================================================
In SQL Server, numeric types are SIGNED by default (can be negative).

Common signed types:
  TINYINT: 0 to 255 (unsigned-like, but can't explicitly be unsigned)
  SMALLINT: -32,768 to 32,767
  INT: -2,147,483,648 to 2,147,483,647
  BIGINT: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
*/

-- Example 1.1: Positive and negative values
SELECT 
    100 AS PositiveInt,
    -100 AS NegativeInt,
    0 AS Zero,
    CAST(-32768 AS SMALLINT) AS MinSmallInt,
    CAST(32767 AS SMALLINT) AS MaxSmallInt;

-- Example 1.2: Overflow with signed types
-- ❌ This will ERROR:
-- SELECT CAST(32768 AS SMALLINT);  -- Too large for SMALLINT

-- ✅ Use appropriate type:
SELECT CAST(32768 AS INT) AS ValidInt;

-- Example 1.3: Negative money values
DECLARE @Credit DECIMAL(10,2) = 50.00;
DECLARE @Debit DECIMAL(10,2) = -30.00;

SELECT 
    @Credit AS CreditAmount,
    @Debit AS DebitAmount,
    @Credit + @Debit AS Balance;  -- 20.00


/*
============================================================================
PART 2: SIGN Function in Depth
============================================================================
SIGN returns: -1 for negative, 0 for zero, +1 for positive
*/

-- Example 2.1: SIGN with different values
SELECT 
    SIGN(-100) AS NegativeSign,     -- -1
    SIGN(0) AS ZeroSign,            -- 0
    SIGN(100) AS PositiveSign;      -- 1

-- Example 2.2: Categorize transactions
CREATE TABLE #Transactions (
    TransactionID INT,
    Amount DECIMAL(10,2)
);

INSERT INTO #Transactions VALUES
(1, 500.00),    -- Income
(2, -150.00),   -- Expense
(3, 0.00),      -- No change
(4, -75.50),    -- Expense
(5, 1000.00);   -- Income

SELECT 
    TransactionID,
    Amount,
    SIGN(Amount) AS SignValue,
    CASE SIGN(Amount)
        WHEN 1 THEN 'Income'
        WHEN -1 THEN 'Expense'
        ELSE 'No Change'
    END AS TransactionType
FROM #Transactions;

DROP TABLE #Transactions;

-- Example 2.3: Count positive vs negative
SELECT 
    SUM(CASE WHEN SIGN(Stock - 50) = 1 THEN 1 ELSE 0 END) AS AboveThreshold,
    SUM(CASE WHEN SIGN(Stock - 50) = 0 THEN 1 ELSE 0 END) AS AtThreshold,
    SUM(CASE WHEN SIGN(Stock - 50) = -1 THEN 1 ELSE 0 END) AS BelowThreshold
FROM Products;

-- Example 2.4: Direction of change
SELECT 
    ProductID,
    ProductName,
    50 AS TargetStock,
    Stock AS CurrentStock,
    Stock - 50 AS Difference,
    CASE SIGN(Stock - 50)
        WHEN 1 THEN 'Overstocked'
        WHEN 0 THEN 'On Target'
        WHEN -1 THEN 'Understocked'
    END AS StockStatus
FROM Products;


/*
============================================================================
PART 3: ABS Function for Magnitude
============================================================================
Get absolute value (always positive) while preserving sign separately.
*/

-- Example 3.1: Absolute values
SELECT 
    -100 AS Negative,
    ABS(-100) AS AbsoluteValue,
    100 AS Positive,
    ABS(100) AS StillPositive;

-- Example 3.2: Calculate distance regardless of direction
SELECT 
    ProductID,
    ProductName,
    Stock,
    50 AS TargetStock,
    Stock - 50 AS Difference,
    ABS(Stock - 50) AS DistanceFromTarget,
    SIGN(Stock - 50) AS Direction
FROM Products;

-- Example 3.3: Find largest variance (positive or negative)
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS Variance,
    ABS(Price - (SELECT AVG(Price) FROM Products)) AS AbsVariance
FROM Products
ORDER BY ABS(Price - (SELECT AVG(Price) FROM Products)) DESC;

-- Example 3.4: Total adjustments needed (sum of absolute values)
SELECT 
    SUM(ABS(Stock - 50)) AS TotalAdjustmentsNeeded,
    SUM(Stock - 50) AS NetAdjustment  -- Could be zero if balanced!
FROM Products;


/*
============================================================================
PART 4: Credits and Debits
============================================================================
Financial transactions often use signed values:
  Positive = Credit (money in)
  Negative = Debit (money out)
*/

-- Example 4.1: Account ledger
CREATE TABLE #Ledger (
    EntryID INT,
    EntryDate DATE,
    Description VARCHAR(100),
    Amount DECIMAL(10,2)
);

INSERT INTO #Ledger VALUES
(1, '2025-01-01', 'Opening Balance', 1000.00),
(2, '2025-01-05', 'Expense: Office Supplies', -150.00),
(3, '2025-01-10', 'Income: Sales', 500.00),
(4, '2025-01-15', 'Expense: Rent', -800.00),
(5, '2025-01-20', 'Income: Consulting', 1200.00),
(6, '2025-01-25', 'Expense: Utilities', -120.00);

-- Calculate running balance
SELECT 
    EntryID,
    EntryDate,
    Description,
    Amount,
    CASE WHEN Amount > 0 THEN 'Credit' ELSE 'Debit' END AS Type,
    SUM(Amount) OVER (ORDER BY EntryDate, EntryID) AS RunningBalance
FROM #Ledger
ORDER BY EntryDate, EntryID;

DROP TABLE #Ledger;

-- Example 4.2: Separate credits and debits
CREATE TABLE #Transactions (
    TransID INT,
    Amount DECIMAL(10,2)
);

INSERT INTO #Transactions VALUES
(1, 500), (2, -200), (3, 300), (4, -150), (5, -75);

SELECT 
    SUM(CASE WHEN Amount > 0 THEN Amount ELSE 0 END) AS TotalCredits,
    SUM(CASE WHEN Amount < 0 THEN ABS(Amount) ELSE 0 END) AS TotalDebits,
    SUM(Amount) AS NetBalance
FROM #Transactions;

DROP TABLE #Transactions;


/*
============================================================================
PART 5: Gains and Losses
============================================================================
*/

-- Example 5.1: Calculate profit/loss on sales
CREATE TABLE #Sales (
    ProductID INT,
    Cost DECIMAL(10,2),
    SalePrice DECIMAL(10,2)
);

INSERT INTO #Sales VALUES
(1, 50.00, 75.00),   -- Profit
(2, 100.00, 90.00),  -- Loss
(3, 25.00, 50.00),   -- Profit
(4, 80.00, 70.00);   -- Loss

SELECT 
    ProductID,
    Cost,
    SalePrice,
    SalePrice - Cost AS ProfitLoss,
    ABS(SalePrice - Cost) AS Magnitude,
    CASE 
        WHEN SalePrice > Cost THEN 'Profit'
        WHEN SalePrice < Cost THEN 'Loss'
        ELSE 'Break Even'
    END AS Status,
    CASE 
        WHEN SalePrice > Cost THEN (SalePrice - Cost) / Cost * 100
        ELSE (Cost - SalePrice) / Cost * 100
    END AS PercentChange
FROM #Sales;

DROP TABLE #Sales;

-- Example 5.2: Investment gains/losses
DECLARE @InitialInvestment DECIMAL(10,2) = 10000.00;
DECLARE @CurrentValue DECIMAL(10,2) = 12500.00;

SELECT 
    @InitialInvestment AS InitialInvestment,
    @CurrentValue AS CurrentValue,
    @CurrentValue - @InitialInvestment AS GainLoss,
    (@CurrentValue - @InitialInvestment) / @InitialInvestment * 100 AS PercentReturn,
    CASE 
        WHEN @CurrentValue > @InitialInvestment THEN 'Gain'
        WHEN @CurrentValue < @InitialInvestment THEN 'Loss'
        ELSE 'Break Even'
    END AS Status;


/*
============================================================================
PART 6: Balance Calculations
============================================================================
*/

-- Example 6.1: Account balance from transactions
CREATE TABLE #AccountActivity (
    ActivityID INT,
    ActivityDate DATE,
    TransactionType VARCHAR(20),
    Amount DECIMAL(10,2)
);

INSERT INTO #AccountActivity VALUES
(1, '2025-01-01', 'Deposit', 1000.00),
(2, '2025-01-05', 'Withdrawal', -200.00),
(3, '2025-01-10', 'Deposit', 500.00),
(4, '2025-01-15', 'Fee', -15.00),
(5, '2025-01-20', 'Deposit', 300.00);

SELECT 
    *,
    SUM(Amount) OVER (ORDER BY ActivityDate, ActivityID) AS Balance,
    CASE 
        WHEN SUM(Amount) OVER (ORDER BY ActivityDate, ActivityID) < 0 
        THEN 'Overdrawn'
        ELSE 'OK'
    END AS AccountStatus
FROM #AccountActivity;

DROP TABLE #AccountActivity;

-- Example 6.2: Inventory adjustments
CREATE TABLE #InventoryAdjustments (
    AdjustmentID INT,
    ProductID INT,
    Quantity INT,  -- Positive = add, Negative = remove
    Reason VARCHAR(50)
);

INSERT INTO #InventoryAdjustments VALUES
(1, 1, 100, 'Restock'),
(2, 1, -25, 'Sold'),
(3, 1, -10, 'Damaged'),
(4, 1, 50, 'Restock'),
(5, 1, -30, 'Sold');

SELECT 
    AdjustmentID,
    Quantity,
    CASE WHEN Quantity > 0 THEN 'Addition' ELSE 'Removal' END AS Type,
    ABS(Quantity) AS QuantityMagnitude,
    Reason,
    SUM(Quantity) OVER (ORDER BY AdjustmentID) AS RunningInventory
FROM #InventoryAdjustments;

DROP TABLE #InventoryAdjustments;


/*
============================================================================
PART 7: Practical Applications
============================================================================
*/

-- Application 7.1: Customer credit/debit summary
CREATE TABLE #CustomerTransactions (
    CustomerID INT,
    TransactionType VARCHAR(20),
    Amount DECIMAL(10,2)
);

INSERT INTO #CustomerTransactions VALUES
(1, 'Purchase', -150.00),
(1, 'Payment', 100.00),
(1, 'Purchase', -75.00),
(2, 'Purchase', -200.00),
(2, 'Payment', 200.00),
(2, 'Refund', 50.00);

SELECT 
    CustomerID,
    SUM(CASE WHEN Amount > 0 THEN Amount ELSE 0 END) AS TotalPayments,
    SUM(CASE WHEN Amount < 0 THEN ABS(Amount) ELSE 0 END) AS TotalPurchases,
    SUM(Amount) AS AccountBalance,
    CASE 
        WHEN SUM(Amount) > 0 THEN 'Credit Balance'
        WHEN SUM(Amount) < 0 THEN 'Amount Owed'
        ELSE 'Paid Up'
    END AS Status
FROM #CustomerTransactions
GROUP BY CustomerID;

DROP TABLE #CustomerTransactions;

-- Application 7.2: Temperature variations (can be negative)
CREATE TABLE #TemperatureLog (
    LogID INT,
    LogDate DATE,
    Temperature INT  -- Can be negative (Celsius/Fahrenheit)
);

INSERT INTO #TemperatureLog VALUES
(1, '2025-01-01', -5),
(2, '2025-01-02', -3),
(3, '2025-01-03', 2),
(4, '2025-01-04', 5),
(5, '2025-01-05', 8);

SELECT 
    LogDate,
    Temperature,
    LAG(Temperature) OVER (ORDER BY LogDate) AS PreviousDay,
    Temperature - LAG(Temperature) OVER (ORDER BY LogDate) AS Change,
    CASE SIGN(Temperature - LAG(Temperature) OVER (ORDER BY LogDate))
        WHEN 1 THEN 'Warmer'
        WHEN -1 THEN 'Cooler'
        ELSE 'Same'
    END AS Trend,
    CASE WHEN Temperature < 0 THEN 'Freezing' ELSE 'Above Freezing' END AS Status
FROM #TemperatureLog;

DROP TABLE #TemperatureLog;


/*
============================================================================
PART 8: Handling Negative Numbers in Calculations
============================================================================
*/

-- Example 8.1: Negate values
SELECT 
    100 AS Positive,
    -100 AS Negative,
    -(-100) AS NegatedNegative,  -- Becomes positive
    -(100) AS NegatedPositive;   -- Becomes negative

-- Example 8.2: Absolute difference
SELECT 
    ProductID,
    ProductName,
    Stock,
    50 AS Target,
    Stock - 50 AS SignedDifference,
    ABS(Stock - 50) AS AbsoluteDifference,
    CASE 
        WHEN Stock > 50 THEN 'Reduce by ' + CAST(Stock - 50 AS VARCHAR)
        WHEN Stock < 50 THEN 'Add ' + CAST(50 - Stock AS VARCHAR)
        ELSE 'On Target'
    END AS Action
FROM Products;

-- Example 8.3: Min/Max with negatives
CREATE TABLE #Values (Value INT);
INSERT INTO #Values VALUES (-100), (-50), (0), (50), (100);

SELECT 
    MIN(Value) AS MinValue,      -- -100
    MAX(Value) AS MaxValue,      -- 100
    MIN(ABS(Value)) AS MinAbs,   -- 0
    MAX(ABS(Value)) AS MaxAbs;   -- 100

DROP TABLE #Values;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own:

1. Create a profit/loss report showing gain or loss for each product
2. Calculate net cash flow from positive and negative transactions
3. Find products with largest deviation (+ or -) from average price
4. Create running balance with overdraft warnings
5. Categorize all numbers as positive, negative, or zero

Solutions below ↓
*/

-- Solution 1: Profit/loss report
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price AS SalePrice,
    p.Price * 0.6 AS EstimatedCost,
    p.Price - (p.Price * 0.6) AS ProfitPerUnit,
    SIGN(p.Price - (p.Price * 0.6)) AS ProfitSign
FROM Products p;

-- Solution 2: Net cash flow
CREATE TABLE #CashFlow (TxID INT, Amount DECIMAL(10,2));
INSERT INTO #CashFlow VALUES (1, 500), (2, -200), (3, 300), (4, -150);

SELECT 
    SUM(CASE WHEN Amount > 0 THEN Amount ELSE 0 END) AS Inflow,
    ABS(SUM(CASE WHEN Amount < 0 THEN Amount ELSE 0 END)) AS Outflow,
    SUM(Amount) AS NetFlow
FROM #CashFlow;

DROP TABLE #CashFlow;

-- Solution 3: Largest deviation
SELECT TOP 5
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS Deviation,
    ABS(Price - (SELECT AVG(Price) FROM Products)) AS AbsDeviation
FROM Products
ORDER BY ABS(Price - (SELECT AVG(Price) FROM Products)) DESC;

-- Solution 4: Running balance with warnings
CREATE TABLE #Transactions (TxID INT, Amount DECIMAL(10,2));
INSERT INTO #Transactions VALUES (1, 1000), (2, -400), (3, -700), (4, 200);

SELECT 
    *,
    SUM(Amount) OVER (ORDER BY TxID) AS Balance,
    CASE 
        WHEN SUM(Amount) OVER (ORDER BY TxID) < 0 THEN 'OVERDRAFT!'
        WHEN SUM(Amount) OVER (ORDER BY TxID) < 100 THEN 'Low Balance'
        ELSE 'OK'
    END AS Warning
FROM #Transactions;

DROP TABLE #Transactions;

-- Solution 5: Categorize numbers
SELECT 
    Stock,
    CASE SIGN(Stock - 50)
        WHEN 1 THEN 'Positive (above 50)'
        WHEN 0 THEN 'Zero (equals 50)'
        WHEN -1 THEN 'Negative (below 50)'
    END AS Category
FROM Products;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SIGNED DATA:
  • SQL Server types are signed by default
  • Can store positive, negative, or zero
  • Choose appropriate range for your data

✓ SIGN FUNCTION:
  • Returns: -1, 0, or 1
  • Categorize values by direction
  • Useful for conditional logic

✓ ABS FUNCTION:
  • Always returns positive value
  • Calculate magnitude/distance
  • Combine with SIGN to preserve direction info

✓ FINANCIAL USES:
  • Credits (positive) vs Debits (negative)
  • Gains vs Losses
  • Running balances
  • Profit/Loss calculations

✓ BEST PRACTICES:
  • Use signed types when negatives are possible
  • Store debits as negative values
  • Use ABS for magnitude, SIGN for direction
  • Handle zero explicitly in CASE statements
  • Test with negative, zero, and positive values

============================================================================
NEXT: Lesson 07.06 - Time Zones
Learn to handle time zones and UTC conversions.
============================================================================
*/
