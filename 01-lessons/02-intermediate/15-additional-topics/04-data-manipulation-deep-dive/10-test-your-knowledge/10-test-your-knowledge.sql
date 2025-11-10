/*
============================================================================
Lesson 07.10 - TEST YOUR KNOWLEDGE
Data Generation and Manipulation - Comprehensive Assessment
============================================================================

Total Points: 500
Passing Score: 350 (70%)
Estimated Time: 60 minutes

Topics Covered:
• String generation and manipulation
• Arithmetic functions
• Number precision and rounding
• Temporal data generation
• Temporal data manipulation
• Type conversions
• Combined transformations

Instructions:
1. Complete all exercises in order
2. Write your query below each question
3. Check your results against expected output
4. Award yourself points based on correctness
5. Review mistakes and learn from them

============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION 1: String Generation (5 questions × 5 points = 25 points)
============================================================================
*/

-- Question 1.1 (5 points)
-- Create full customer names in format: "LastName, FirstName"
-- Expected columns: CustomerID, FormattedName

-- YOUR QUERY HERE:




-- Question 1.2 (5 points)
-- Generate email suggestions for customers in format: "firstname.lastname@retailstore.com"
-- Use lowercase for the email
-- Expected columns: CustomerID, FirstName, LastName, SuggestedEmail

-- YOUR QUERY HERE:




-- Question 1.3 (5 points)
-- Create product codes in format: "PROD-CAT##-ID#####"
-- Example: Category 2, Product 15 → "PROD-CAT02-ID00015"
-- Expected columns: ProductID, CategoryID, ProductCode

-- YOUR QUERY HERE:




-- Question 1.4 (5 points)
-- Build a simple invoice header with separator lines
-- Use REPLICATE to create '=' separator (50 characters wide)
-- Format: 
-- ==================================================
-- INVOICE #<OrderID>
-- ==================================================
-- Expected columns: OrderID, InvoiceHeader (multiline string)

-- YOUR QUERY HERE:




-- Question 1.5 (5 points)
-- Mask phone numbers showing only last 4 digits
-- Format: "***-***-1234"
-- Expected columns: CustomerID, Phone, MaskedPhone

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 2: String Manipulation (5 questions × 5 points = 25 points)
============================================================================
*/

-- Question 2.1 (5 points)
-- Extract initials from customer names (first letter of each name)
-- Expected columns: CustomerID, FirstName, LastName, Initials

-- YOUR QUERY HERE:




-- Question 2.2 (5 points)
-- Find products with names longer than 20 characters
-- Show the name and its length
-- Expected columns: ProductID, ProductName, NameLength
-- Order by length descending

-- YOUR QUERY HERE:




-- Question 2.3 (5 points)
-- Extract domain name from customer emails (part after @)
-- Expected columns: CustomerID, Email, Domain

-- YOUR QUERY HERE:




-- Question 2.4 (5 points)
-- Clean product names by:
-- - Converting to uppercase
-- - Trimming whitespace
-- - Replacing '&' with 'AND'
-- Expected columns: ProductID, OriginalName, CleanedName

-- YOUR QUERY HERE:




-- Question 2.5 (5 points)
-- Truncate product names to 25 characters with '...' if longer
-- Expected columns: ProductID, ProductName, DisplayName

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 3: Arithmetic Functions (5 questions × 8 points = 40 points)
============================================================================
*/

-- Question 3.1 (8 points)
-- Calculate 15% discount and 8% tax on products
-- Round final price to 2 decimals
-- Expected columns: ProductID, ProductName, OriginalPrice, 
--                   DiscountAmount, PriceAfterDiscount, TaxAmount, FinalPrice

-- YOUR QUERY HERE:




-- Question 3.2 (8 points)
-- Calculate how many full cases of 24 units can be shipped per product
-- Also show remaining units after full cases
-- Expected columns: ProductID, ProductName, Stock, FullCases, RemainingUnits

-- YOUR QUERY HERE:




-- Question 3.3 (8 points)
-- Round all prices to nearest $10
-- Show difference between original and rounded price
-- Expected columns: ProductID, ProductName, OriginalPrice, 
--                   RoundedPrice, Difference

-- YOUR QUERY HERE:




-- Question 3.4 (8 points)
-- Calculate compound interest: $1000 at 5% for 10 years
-- Formula: FV = PV * (1 + rate)^years
-- Show year-by-year growth
-- Expected columns: Year, Amount (rounded to 2 decimals)
-- Hint: Generate numbers 0-10 and use POWER

-- YOUR QUERY HERE:




-- Question 3.5 (8 points)
-- Determine price status for each product:
-- - "Above Average" if price > average
-- - "Average" if price = average  
-- - "Below Average" if price < average
-- Use SIGN function and a subquery
-- Expected columns: ProductID, ProductName, Price, AveragePrice, Status

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 4: Temporal Data Generation (5 questions × 8 points = 40 points)
============================================================================
*/

-- Question 4.1 (8 points)
-- Calculate shipping dates: 3 business days from order date
-- Add 7 days for weekend fallback
-- Expected columns: OrderID, OrderDate, EstimatedShipping

-- YOUR QUERY HERE:




-- Question 4.2 (8 points)
-- Generate the first and last day of each month in 2025
-- Expected columns: MonthNum, MonthName, FirstDay, LastDay
-- Hint: Use DATEFROMPARTS and EOMONTH

-- YOUR QUERY HERE:




-- Question 4.3 (8 points)
-- Create a list of all Fridays in the next 90 days
-- Expected columns: FridayDate, WeekNumber
-- Hint: Generate date range, filter for DATEPART(WEEKDAY) = 6

-- YOUR QUERY HERE:




-- Question 4.4 (8 points)
-- Calculate warranty expiration (1 year from order date)
-- Show days until expiration, mark as "Expired" or "Active"
-- Expected columns: OrderID, OrderDate, WarrantyExpires, 
--                   DaysUntilExpiration, Status

-- YOUR QUERY HERE:




-- Question 4.5 (8 points)
-- Generate quarter boundaries for fiscal year 2025 (April-March)
-- Expected columns: Quarter, FiscalQuarter, StartDate, EndDate
-- Hint: Fiscal Q1 = Apr-Jun, Q2 = Jul-Sep, Q3 = Oct-Dec, Q4 = Jan-Mar

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 5: Temporal Data Manipulation (5 questions × 10 points = 50 points)
============================================================================
*/

-- Question 5.1 (10 points)
-- Calculate customer tenure in years, months, and days
-- From first order date to today
-- Expected columns: CustomerID, CustomerName, FirstOrder, 
--                   TenureYears, TenureMonths, TenureDays

-- YOUR QUERY HERE:




-- Question 5.2 (10 points)
-- Find orders placed on weekends
-- Show order details with day name
-- Expected columns: OrderID, OrderDate, DayName, TotalAmount
-- Order by OrderDate

-- YOUR QUERY HERE:




-- Question 5.3 (10 points)
-- Calculate average days between orders for each customer
-- Only include customers with 2+ orders
-- Expected columns: CustomerID, CustomerName, TotalOrders, AvgDaysBetween
-- Round to 1 decimal

-- YOUR QUERY HERE:




-- Question 5.4 (10 points)
-- Create an aging report for orders
-- Buckets: 0-30 days, 31-60 days, 61-90 days, 90+ days
-- Show count and total amount per bucket
-- Expected columns: AgingBucket, OrderCount, TotalAmount

-- YOUR QUERY HERE:




-- Question 5.5 (10 points)
-- Find products ordered in each month of the current year
-- Show matrix of ProductName and months (use PIVOT or CASE)
-- Expected columns: ProductName, Jan, Feb, Mar, ..., Dec (count of orders)

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 6: Type Conversions (5 questions × 10 points = 50 points)
============================================================================
*/

-- Question 6.1 (10 points)
-- Convert prices to different formats:
-- - As integer (truncated)
-- - As DECIMAL(10,2)
-- - As VARCHAR with currency symbol
-- - As VARCHAR with commas for thousands
-- Expected columns: ProductID, ProductName, PriceInt, PriceDecimal, 
--                   PriceCurrency, PriceFormatted

-- YOUR QUERY HERE:




-- Question 6.2 (10 points)
-- Convert dates to different string formats:
-- - ISO format (YYYY-MM-DD)
-- - US format (MM/DD/YYYY)
-- - Long format (Month DD, YYYY)
-- - Custom format (DD-Mon-YYYY)
-- Expected columns: OrderID, OrderDate, ISO, US, Long, Custom

-- YOUR QUERY HERE:




-- Question 6.3 (10 points)
-- Safely convert potentially invalid data using TRY_CAST
-- Create a temp table with mixed data types and convert safely
-- Expected: Create table, insert data, convert with error handling

-- YOUR QUERY HERE:




-- Question 6.4 (10 points)
-- Convert stock quantities to different representations:
-- - Dozens (divide by 12)
-- - Gross (divide by 144)
-- - As percentage of total inventory
-- Expected columns: ProductID, ProductName, Stock, Dozens, Gross, PercentOfTotal

-- YOUR QUERY HERE:




-- Question 6.5 (10 points)
-- Parse and convert phone numbers from various formats to standard format
-- Input: "123-456-7890", "(123) 456-7890", "1234567890"
-- Output: "(123) 456-7890"
-- Handle all formats
-- Expected columns: CustomerID, OriginalPhone, StandardPhone

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 7: Combined Transformations (6 questions × 15 points = 90 points)
============================================================================
*/

-- Question 7.1 (15 points)
-- Create a formatted customer directory entry:
-- "LASTNAME, Firstname | email@domain.com | (123) 456-7890 | City, ST"
-- - Uppercase last name
-- - Title case first name
-- - Lowercase email
-- - Formatted phone
-- Expected columns: CustomerID, DirectoryEntry

-- YOUR QUERY HERE:




-- Question 7.2 (15 points)
-- Generate a monthly sales summary with formatted output:
-- Month name, year, total sales (formatted with $), order count
-- "November 2025: $1,234.56 from 15 orders"
-- Expected columns: OrderMonth, SummaryText
-- Group by month

-- YOUR QUERY HERE:




-- Question 7.3 (15 points)
-- Create product labels with all details:
-- Multiple lines with separators, formatted text:
/*
==================================================
PRODUCT: LAPTOP PRO
Price: $899.99 | Stock: 25 units
Category: Electronics
Added: November 8, 2025
==================================================
*/
-- Expected columns: ProductID, ProductLabel (multiline string)

-- YOUR QUERY HERE:




-- Question 7.4 (15 points)
-- Calculate tiered commission for employees:
-- Orders < $500: 2%
-- Orders $500-$1000: 5%
-- Orders > $1000: 10%
-- Show employee, total sales, commission (rounded to 2 decimals)
-- Expected columns: EmployeeID, EmployeeName, TotalSales, 
--                   Commission, EffectiveRate

-- YOUR QUERY HERE:




-- Question 7.5 (15 points)
-- Create a customer retention report:
-- Show customers grouped by:
-- - Number of orders
-- - Average order value (rounded)
-- - Days since last order
-- - Risk category (High/Medium/Low based on recency)
-- Expected columns: CustomerID, CustomerName, OrderCount, AvgOrderValue,
--                   DaysSinceLastOrder, RiskCategory
-- Risk: High if >90 days, Medium if 30-90 days, Low if <30 days

-- YOUR QUERY HERE:




-- Question 7.6 (15 points)
-- Build a comprehensive order analysis:
-- For each order show:
-- - Order details with formatted date
-- - Line items with quantity × price
-- - Subtotal, discount (10%), tax (8%), final total
-- - All monetary values formatted with $ and 2 decimals
-- Expected columns: OrderID, OrderDetails (formatted multiline string)

-- YOUR QUERY HERE:





/*
============================================================================
SECTION 8: Real-World Scenarios (5 questions × 20 points = 100 points)
============================================================================
*/

-- Scenario 8.1 (20 points)
-- Data Quality Report
-- Create a report identifying data quality issues:
-- - Missing emails
-- - Invalid phone format (not 10 digits)
-- - Duplicate names (same first+last name)
-- - Customers with no orders
-- Expected columns: IssueType, RecordCount, Examples (sample IDs)

-- YOUR QUERY HERE:




-- Scenario 8.2 (20 points)
-- Inventory Reorder Report
-- Calculate reorder needs based on:
-- - Current stock
-- - Average daily sales (last 30 days)
-- - Lead time: 7 days
-- - Safety stock: 14 days of average sales
-- - Reorder point: (Average daily sales × (Lead time + Safety stock))
-- Flag products below reorder point
-- Expected columns: ProductID, ProductName, CurrentStock, AvgDailySales,
--                   ReorderPoint, UnitsNeeded, Status

-- YOUR QUERY HERE:




-- Scenario 8.3 (20 points)
-- Customer Segmentation (RFM Analysis)
-- Calculate for each customer:
-- - Recency: Days since last order
-- - Frequency: Total number of orders
-- - Monetary: Total amount spent
-- Assign scores 1-5 for each dimension
-- Create RFM segment code (e.g., "5-5-5" = best customers)
-- Expected columns: CustomerID, CustomerName, Recency, Frequency, Monetary,
--                   RecencyScore, FrequencyScore, MonetaryScore, RFMSegment

-- YOUR QUERY HERE:




-- Scenario 8.4 (20 points)
-- Sales Trend Analysis
-- Calculate month-over-month growth:
-- - Total sales per month
-- - Growth amount vs previous month
-- - Growth percentage
-- - 3-month moving average
-- Format all numbers appropriately
-- Expected columns: YearMonth, MonthlySales, PreviousMonth, GrowthAmount,
--                   GrowthPercent, MovingAverage3Month

-- YOUR QUERY HERE:




-- Scenario 8.5 (20 points)
-- Product Performance Dashboard
-- Create comprehensive product metrics:
-- - Total units sold
-- - Total revenue
-- - Average selling price
-- - Days since last sale
-- - Inventory turnover ratio
-- - Performance rating (A/B/C/D based on revenue)
-- Format monetary values with $ and commas
-- Expected columns: ProductID, ProductName, UnitsSold, Revenue,
--                   AvgPrice, DaysSinceLastSale, TurnoverRatio,
--                   PerformanceGrade

-- YOUR QUERY HERE:





/*
============================================================================
BONUS CHALLENGES (5 questions × 20 points = 100 bonus points)
Maximum total: 600 points
============================================================================
*/

-- BONUS 1 (20 points)
-- Create a calendar table for 2025 with ALL the following:
-- - Every date in the year
-- - Day name, month name
-- - Week number, quarter
-- - Is weekend, is holiday (US federal holidays)
-- - Fiscal period (year starting April)
-- - Days until year end
-- Expected columns: DateValue, DayName, MonthName, WeekNum, Quarter,
--                   IsWeekend, IsHoliday, HolidayName, FiscalYear, 
--                   FiscalQuarter, DaysToYearEnd

-- YOUR QUERY HERE:




-- BONUS 2 (20 points)
-- Parse and validate complex email addresses:
-- - Extract username, domain, TLD
-- - Validate format (has @ and ., proper structure)
-- - Categorize domain type (gmail, company, etc.)
-- - Calculate email strength score
-- Expected columns: CustomerID, Email, Username, Domain, TLD,
--                   IsValid, ValidationErrors, DomainType, StrengthScore

-- YOUR QUERY HERE:




-- BONUS 3 (20 points)
-- Create a sophisticated pricing model:
-- - Base price
-- - Volume discount tiers (5%, 10%, 15%)
-- - Seasonal markup (20% in Dec, -10% in Jan-Feb)
-- - Competitive adjustment based on category average
-- - Final recommended price
-- Show all calculation steps
-- Expected columns: ProductID, ProductName, BasePrice, VolumeDiscount,
--                   SeasonalAdjustment, CompetitiveAdjustment, 
--                   RecommendedPrice, ExpectedMargin

-- YOUR QUERY HERE:




-- BONUS 4 (20 points)
-- Generate a complex recurring schedule:
-- - Payment schedule for subscriptions
-- - Skip weekends and holidays
-- - Adjust for month-end (bills on 30th/31st → last business day)
-- - Handle leap years
-- - Show for next 12 months
-- Expected columns: PaymentNumber, ScheduledDate, AdjustedDate,
--                   DayName, IsAdjusted, AdjustmentReason

-- YOUR QUERY HERE:




-- BONUS 5 (20 points)
-- Advanced string fuzzy matching:
-- Find potential duplicate customers using:
-- - SOUNDEX for phonetic matching
-- - Levenshtein distance approximation
-- - First initial + last name matching
-- - Similar email domains
-- Create match confidence score
-- Expected columns: CustomerID1, Customer1Name, CustomerID2, Customer2Name,
--                   MatchType, ConfidenceScore, MatchReason

-- YOUR QUERY HERE:





/*
============================================================================
ANSWER KEY AND SCORING GUIDE
============================================================================

Section 1: String Generation (25 points)
1.1: CONCAT(LastName, ', ', FirstName)
1.2: LOWER(CONCAT(FirstName, '.', LastName, '@retailstore.com'))
1.3: CONCAT('PROD-CAT', RIGHT('00' + CAST(CategoryID AS VARCHAR), 2), '-ID', 
            RIGHT('00000' + CAST(ProductID AS VARCHAR), 5))
1.4: Use REPLICATE('=', 50) + CHAR(13) + CHAR(10) + ...
1.5: '***-***-' + RIGHT(Phone, 4)

Section 2: String Manipulation (25 points)
2.1: LEFT(FirstName, 1) + LEFT(LastName, 1)
2.2: WHERE LEN(ProductName) > 20 ORDER BY LEN(ProductName) DESC
2.3: SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email))
2.4: UPPER(LTRIM(RTRIM(REPLACE(ProductName, '&', 'AND'))))
2.5: CASE WHEN LEN(ProductName) <= 25 THEN ProductName 
          ELSE LEFT(ProductName, 22) + '...' END

Section 3: Arithmetic Functions (40 points)
3.1: Use *, ROUND, proper order of operations
3.2: FLOOR(Stock / 24.0), Stock % 24
3.3: ROUND(Price / 10, 0) * 10, ABS(Price - RoundedPrice)
3.4: Use POWER(1.05, Year) with generated numbers
3.5: Use SIGN(Price - AVG) with CASE

Section 4-8: Similar detailed answer patterns
Check your work for:
- Correct functions used
- Proper data type handling
- Accurate calculations
- Clean formatting
- NULL handling

Scoring:
500-600: Expert Level! 🏆
400-499: Advanced - Excellent work! ⭐
350-399: Proficient - Good job! ✓
300-349: Developing - Review weak areas
<300: Needs practice - Revisit lessons

============================================================================
*/

-- Calculate your score here:
SELECT 
    'Section 1' AS Section, 0 AS YourScore, 25 AS MaxScore
UNION ALL SELECT 'Section 2', 0, 25
UNION ALL SELECT 'Section 3', 0, 40
UNION ALL SELECT 'Section 4', 0, 40
UNION ALL SELECT 'Section 5', 0, 50
UNION ALL SELECT 'Section 6', 0, 50
UNION ALL SELECT 'Section 7', 0, 90
UNION ALL SELECT 'Section 8', 0, 100
UNION ALL SELECT 'BONUS', 0, 100
UNION ALL SELECT 'TOTAL', 0, 600;

/*
============================================================================
REFLECTION QUESTIONS
============================================================================

After completing this test, reflect on:

1. Which section was most challenging? Why?

2. Which functions do you feel most confident using?

3. What real-world scenarios can you apply these skills to?

4. Which topics need more practice?

5. How will you use data transformation in your work?

============================================================================
NEXT STEPS
============================================================================

Congratulations on completing Chapter 07!

Next Chapter: 08 - Grouping and Aggregates
Learn to summarize data, calculate statistics, and create powerful reports.

Continue practicing:
- Work with real-world datasets
- Combine functions creatively
- Focus on performance optimization
- Build reusable patterns

Keep coding! 🚀
============================================================================
*/
