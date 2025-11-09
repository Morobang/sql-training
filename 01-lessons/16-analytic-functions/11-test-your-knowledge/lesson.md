# Lesson 16.11: Test Your Knowledge - Analytic Functions

## Overview

This comprehensive assessment tests your mastery of SQL analytic/window functions covered in Chapter 16. The exercises range from basic to advanced and mirror real-world analytical scenarios you'll encounter in business intelligence, data analysis, and reporting roles.

**Estimated Time:** 90 minutes  
**Difficulty:** Mixed (Basic to Advanced)  
**Total Points:** 350 points

---

## Assessment Structure

| Section | Topic | Points | Difficulty |
|---------|-------|--------|------------|
| Part 1 | Basic Window Functions | 50 | ⭐ Basic |
| Part 2 | Ranking Functions | 50 | ⭐⭐ Intermediate |
| Part 3 | Moving Calculations | 60 | ⭐⭐ Intermediate |
| Part 4 | LAG/LEAD Analysis | 60 | ⭐⭐ Intermediate |
| Part 5 | Complex Multi-Function | 80 | ⭐⭐⭐ Advanced |
| Part 6 | Real-World Scenarios | 50 | ⭐⭐⭐ Advanced |

---

## Instructions

1. **Database:** Use the RetailStore database from previous lessons
2. **Time Limit:** Try to complete within 90 minutes
3. **Resources:** You may reference lesson materials
4. **Scoring:** Partial credit given for partially correct solutions
5. **Testing:** Verify your queries produce expected output formats

---

## Part 1: Basic Window Functions (50 points)

### Exercise 1.1: Sales Performance Dashboard (15 points)

Create a query showing each sale with:
- Sale ID, date, amount, and region
- Overall total sales (across all rows)
- Regional total sales
- Percentage of overall total
- Percentage of regional total

**Expected Columns:**
```
SaleID, SaleDate, SaleAmount, Region, OverallTotal, RegionalTotal, PctOfOverall, PctOfRegional
```

**Grading Criteria:**
- Correct window aggregates (5 points)
- Accurate percentage calculations (5 points)
- Proper PARTITION BY usage (5 points)

---

### Exercise 1.2: Running Totals Report (15 points)

Show cumulative sales progress with:
- Sale date and amount
- Running total by date
- Running count of transactions
- Running average sale amount
- Percentage of completion (running total / grand total)

**Expected Columns:**
```
SaleDate, SaleAmount, RunningTotal, RunningCount, RunningAvg, PctComplete
```

**Grading Criteria:**
- Correct ORDER BY for running calculations (7 points)
- Accurate percentage completion (8 points)

---

### Exercise 1.3: Statistical Summary (20 points)

For each product, calculate:
- Product name and category
- Number of sales, total amount, average amount
- Minimum and maximum sale amounts
- Range (max - min)
- Comparison to category average (above/below/equal)

**Expected Columns:**
```
ProductName, Category, SalesCount, TotalSales, AvgSale, MinSale, MaxSale, SaleRange, CategoryComparison
```

**Grading Criteria:**
- Window aggregates within partitions (10 points)
- Statistical calculations (5 points)
- Comparison logic (5 points)

---

## Part 2: Ranking Functions (50 points)

### Exercise 2.1: Product Performance Matrix (20 points)

Rank products using all four ranking functions:
- Product name, total sales, total quantity
- ROW_NUMBER by sales amount
- RANK by sales amount
- DENSE_RANK by sales amount
- NTILE(4) by sales amount (quartiles)

Show how ties are handled differently by each function.

**Expected Columns:**
```
ProductName, TotalSales, TotalQuantity, RowNum, RankNum, DenseRankNum, Quartile
```

**Grading Criteria:**
- All four ranking functions correctly implemented (12 points)
- Proper tie handling demonstration (8 points)

---

### Exercise 2.2: Customer Segmentation (30 points)

Implement RFM (Recency, Frequency, Monetary) analysis:
- Customer name and metrics (most recent purchase date, purchase count, total spent)
- Recency rank (1 = most recent)
- Frequency rank (1 = most purchases)
- Monetary rank (1 = highest spending)
- RFM Score (sum of three ranks, lower is better)
- Customer segment:
  - Score ≤ 6: "Champions"
  - Score ≤ 12: "Loyal"
  - Score ≤ 18: "Potential"
  - Score > 18: "At Risk"

**Expected Columns:**
```
CustomerName, LastPurchase, PurchaseCount, TotalSpent, RecencyRank, FrequencyRank, MonetaryRank, RFMScore, Segment
```

**Grading Criteria:**
- Correct ranking for each dimension (15 points)
- Accurate RFM score calculation (8 points)
- Proper segmentation logic (7 points)

---

## Part 3: Moving Calculations (60 points)

### Exercise 3.1: Moving Averages Analysis (25 points)

Calculate multiple moving averages:
- Sale date and amount
- 3-period moving average
- 5-period moving average
- 7-period moving average
- Difference between current amount and 5-period MA
- Signal: "Buy" if current > 5-MA and 5-MA > 7-MA, otherwise "Hold"

**Expected Columns:**
```
SaleDate, SaleAmount, MA3, MA5, MA7, DiffFromMA5, Signal
```

**Grading Criteria:**
- Correct window frame specifications (15 points)
- Accurate moving average calculations (7 points)
- Signal logic (3 points)

---

### Exercise 3.2: Rolling Statistics (20 points)

For a 7-sale rolling window, calculate:
- Sale date and amount
- Rolling sum
- Rolling average
- Rolling standard deviation
- Rolling minimum and maximum
- Rolling range (max - min)
- Coefficient of variation (stdev / avg)

**Expected Columns:**
```
SaleDate, SaleAmount, RollingSum7, RollingAvg7, RollingStdDev7, RollingMin7, RollingMax7, RollingRange7, CV7
```

**Grading Criteria:**
- Correct 7-row window specification (10 points)
- All statistical functions accurate (10 points)

---

### Exercise 3.3: Window Frames Challenge (15 points)

Create a query showing:
- Sale date and amount
- Sum of previous 3 sales (not including current)
- Sum of current sale
- Sum of next 3 sales (not including current)
- Sum of 3 before + current + 3 after (7-sale window)
- Flag if current sale is the peak in the 7-sale window

**Expected Columns:**
```
SaleDate, SaleAmount, Prev3Sum, CurrentSum, Next3Sum, Total7Sum, IsPeak
```

**Grading Criteria:**
- Correct backward window (5 points)
- Correct forward window (5 points)
- Peak detection logic (5 points)

---

## Part 4: LAG/LEAD Analysis (60 points)

### Exercise 4.1: Period-over-Period Changes (25 points)

Calculate comprehensive change metrics:
- Sale date, amount, and region
- Previous sale amount (overall)
- Absolute change from previous
- Percentage change from previous
- Previous sale amount within region
- Absolute change from previous regional sale
- Percentage change from previous regional sale

**Expected Columns:**
```
SaleDate, SaleAmount, Region, PrevSale, AbsChange, PctChange, PrevRegionalSale, RegionalAbsChange, RegionalPctChange
```

**Grading Criteria:**
- Overall LAG calculations (10 points)
- Partitioned LAG calculations (10 points)
- Percentage calculations with NULL handling (5 points)

---

### Exercise 4.2: Gap Analysis (20 points)

Identify time gaps in sales activity:
- Sale date and amount
- Previous sale date
- Days since previous sale
- Next sale date
- Days until next sale
- Average days between sales (overall)
- Classification:
  - Gap > 2x average: "Large Gap"
  - Gap > average: "Above Average Gap"
  - Otherwise: "Normal"

**Expected Columns:**
```
SaleDate, SaleAmount, PrevDate, DaysSincePrev, NextDate, DaysUntilNext, AvgDaysBetween, GapClassification
```

**Grading Criteria:**
- LAG and LEAD for dates (10 points)
- Gap calculations (5 points)
- Classification logic (5 points)

---

### Exercise 4.3: Trend Detection (15 points)

Identify trends using sequential data:
- Sale date and amount
- Previous 2 sale amounts (Lag1, Lag2)
- Next 2 sale amounts (Lead1, Lead2)
- Trend classification:
  - "Strong Uptrend": Current > Lag1 > Lag2 AND Lead1 > Current > Lag1
  - "Uptrend": Current > Lag1 AND Lead1 > Current
  - "Strong Downtrend": Current < Lag1 < Lag2 AND Lead1 < Current < Lag1
  - "Downtrend": Current < Lag1 AND Lead1 < Current
  - Otherwise: "Mixed"

**Expected Columns:**
```
SaleDate, SaleAmount, Lag1, Lag2, Lead1, Lead2, Trend
```

**Grading Criteria:**
- Multiple LAG/LEAD offsets (7 points)
- Complex trend logic (8 points)

---

## Part 5: Complex Multi-Function Scenarios (80 points)

### Exercise 5.1: Comprehensive Product Analytics (30 points)

Create the ultimate product performance report:
- Product name and category
- Total sales, total quantity, transaction count
- Overall rank by sales
- Rank within category by sales
- Quartile by sales (NTILE(4))
- Percentage of category total sales
- Difference from category average
- 3-sale moving average (by date sold)
- Growth rate from previous sale (LAG)

**Expected Columns:**
```
ProductName, Category, TotalSales, TotalQty, TxnCount, OverallRank, CategoryRank, SalesQuartile, PctOfCategory, DiffFromCategoryAvg, MA3, GrowthRate
```

**Grading Criteria:**
- Multiple ranking functions (10 points)
- Aggregate window functions (8 points)
- Moving calculations (7 points)
- LAG for growth rate (5 points)

---

### Exercise 5.2: Customer Lifetime Value Dashboard (25 points)

Build a customer LTV tracking query:
- Customer name and sale date
- Purchase number (ROW_NUMBER by date)
- Current sale amount
- Cumulative lifetime value (running total)
- Running average purchase value
- Days since previous purchase (LAG)
- Predicted next purchase date (last date + average days between)
- Customer health score:
  - LTV > $10,000 AND avg days < 30: "Platinum"
  - LTV > $5,000 AND avg days < 60: "Gold"
  - LTV > $1,000: "Silver"
  - Otherwise: "Bronze"

**Expected Columns:**
```
CustomerName, SaleDate, PurchaseNum, CurrentSale, LifetimeValue, AvgPurchase, DaysSincePrev, PredictedNextPurchase, HealthScore
```

**Grading Criteria:**
- ROW_NUMBER and running totals (8 points)
- LAG for days calculation (7 points)
- Health score logic (10 points)

---

### Exercise 5.3: Regional Performance Comparison (25 points)

Compare regional performance across multiple dimensions:
- Region
- Total sales, average sale, sale count
- Rank by total sales
- Rank by average sale
- Rank by sale count
- Month-over-month growth (latest month vs previous)
- Year-to-date total
- Percentage of YTD company total
- Performance grade:
  - Rank 1 in any metric: "A"
  - Rank 2 in any metric: "B"
  - Otherwise: "C"

**Expected Columns:**
```
Region, TotalSales, AvgSale, SaleCount, SalesRank, AvgRank, CountRank, MoMGrowth, YTDTotal, PctOfYTD, Grade
```

**Grading Criteria:**
- Multiple ranking metrics (10 points)
- Time-based calculations (MoM, YTD) (10 points)
- Grading logic (5 points)

---

## Part 6: Real-World Business Scenarios (50 points)

### Exercise 6.1: Sales Forecasting Dataset (25 points)

Prepare data for forecasting model:
- Sale date and amount
- Day of week, month, quarter
- 7-day moving average
- 30-day moving average
- Previous week same day (LAG by 7)
- Percentage change from previous week
- Month-to-date total
- Year-over-year growth (if data available)
- Seasonal index (current amount / 30-day MA)
- Trend indicator:
  - 7-MA > 30-MA AND increasing: "Strong Growth"
  - 7-MA > 30-MA: "Growing"
  - 7-MA < 30-MA AND decreasing: "Declining"
  - Otherwise: "Stable"

**Expected Columns:**
```
SaleDate, SaleAmount, DayOfWeek, Month, Quarter, MA7, MA30, PrevWeekSale, WeekOverWeekChange, MTDTotal, YoYGrowth, SeasonalIndex, TrendIndicator
```

**Grading Criteria:**
- Time-based extractions (5 points)
- Moving averages (8 points)
- LAG for week-over-week (7 points)
- Trend logic (5 points)

---

### Exercise 6.2: Inventory Optimization Analysis (25 points)

Analyze product inventory needs:
- Product name and category
- Average daily sales (total qty / days with sales)
- Maximum sales in a single day
- Minimum sales in a single day
- Standard deviation of daily sales
- Coefficient of variation (CV = stdev / avg)
- Recommended safety stock (2 × max daily sales)
- Recommended reorder point (avg × lead time + safety stock, assume 7-day lead time)
- Inventory volatility classification:
  - CV > 1.0: "Highly Variable"
  - CV > 0.5: "Variable"
  - Otherwise: "Stable"
- Stock status based on comparison with similar products in category

**Expected Columns:**
```
ProductName, Category, AvgDailySales, MaxDailySales, MinDailySales, StdDevSales, CV, SafetyStock, ReorderPoint, VolatilityClass, RelativeDemand
```

**Grading Criteria:**
- Statistical calculations (10 points)
- Safety stock/reorder logic (8 points)
- Classification logic (7 points)

---

## Bonus Challenge (50 points)

### Ultimate Analytics Dashboard

Create a single comprehensive query that combines:
1. Product performance metrics (sales, rankings)
2. Customer segmentation (RFM)
3. Time-series analysis (trends, seasonality)
4. Predictive indicators (moving averages, growth rates)
5. Regional comparisons

The query should be:
- Efficient (minimal redundant calculations)
- Well-structured (using CTEs)
- Documented (comments explaining logic)
- Comprehensive (at least 15 meaningful columns)

**Grading Criteria:**
- Query efficiency and structure (15 points)
- Breadth of analytics (15 points)
- Accuracy of calculations (10 points)
- Code quality and documentation (10 points)

---

## Solutions

**Note:** Solutions are provided in a separate file: `11-test-your-knowledge/solutions.sql`

Do not look at solutions until you've attempted all exercises!

---

## Scoring Guide

| Total Score | Grade | Proficiency Level |
|-------------|-------|-------------------|
| 315-350 | A+ | Expert |
| 280-314 | A | Advanced |
| 245-279 | B+ | Proficient |
| 210-244 | B | Competent |
| 175-209 | C+ | Intermediate |
| 140-174 | C | Developing |
| Below 140 | Review | Needs More Practice |

---

## Self-Assessment Checklist

After completing the assessment, can you:

- [ ] Write window functions with appropriate PARTITION BY and ORDER BY?
- [ ] Choose the correct ranking function (ROW_NUMBER, RANK, DENSE_RANK, NTILE)?
- [ ] Calculate running totals and cumulative aggregates?
- [ ] Specify window frames (ROWS vs RANGE)?
- [ ] Use LAG and LEAD for sequential analysis?
- [ ] Combine multiple window functions effectively?
- [ ] Compare individual values to group aggregates?
- [ ] Identify when to use window functions vs GROUP BY?
- [ ] Optimize window function performance?
- [ ] Apply window functions to real business problems?

---

## Next Steps

### If you scored 280+:
Congratulations! You've mastered analytic functions. Move on to:
- **Chapter 17:** Large Databases - Working with big data
- Practice with production-sized datasets
- Explore advanced optimization techniques

### If you scored 210-279:
Good foundation! Strengthen your skills by:
- Reviewing lessons where you struggled
- Redoing exercises you found challenging
- Creating your own practice scenarios
- Working through the bonus challenge

### If you scored below 210:
Take time to review:
- Re-read lessons focusing on concepts you missed
- Work through examples step-by-step
- Practice with simpler queries first
- Ask for help on specific concepts
- Retake assessment after review

---

## Additional Practice Resources

1. **Practice Datasets:** Create your own sales, customer, or inventory data
2. **Real Data:** Use publicly available datasets (Kaggle, data.gov)
3. **Business Cases:** Apply to your own work scenarios
4. **Time Challenges:** Redo exercises with time limits
5. **Code Review:** Compare your solutions with provided answers

---

## Reflection Questions

1. Which window function concept did you find most challenging?
2. Which real-world scenario was most interesting to you?
3. How would you use these functions in your current role?
4. What performance considerations did you discover?
5. Which exercises took longer than expected? Why?

---

## Congratulations!

You've completed Chapter 16: Analytic Functions. These powerful tools enable sophisticated analysis that would be complex or impossible with traditional SQL. Window functions are essential for:

- Business intelligence and reporting
- Time-series analysis
- Customer analytics and segmentation
- Performance tracking and KPIs
- Trend detection and forecasting

Master these concepts, and you'll be able to tackle advanced analytical challenges with confidence!

---

**Continue to:** Chapter 17 - Large Databases  
**Revisit:** Any lessons where you need more practice  
**Practice:** Apply these concepts to your own datasets
