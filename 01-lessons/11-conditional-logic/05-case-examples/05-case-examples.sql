/*
============================================================================
Lesson 11.05 - CASE Examples
============================================================================

Description:
Comprehensive real-world CASE expression examples covering customer
segmentation, grade calculation, status classification, dynamic sorting,
conditional formatting, and complex business rules.

Topics Covered:
• Customer segmentation
• Grade and score calculation
• Status and workflow classification
• Dynamic sorting and ordering
• Conditional formatting
• Complex business rules
• Multi-criteria categorization

Prerequisites:
• Lessons 11.01-11.04

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Customer Segmentation
============================================================================
*/

-- Example 1.1: RFM Segmentation (Recency, Frequency, Monetary)
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS Frequency,
        SUM(o.TotalAmount) AS MonetaryValue,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS Recency
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerID,
    CustomerName,
    Frequency,
    MonetaryValue,
    Recency,
    CASE 
        WHEN Frequency >= 10 AND MonetaryValue >= 5000 AND Recency <= 30 THEN 'Champions'
        WHEN Frequency >= 5 AND MonetaryValue >= 2000 AND Recency <= 60 THEN 'Loyal Customers'
        WHEN Frequency >= 3 AND MonetaryValue >= 1000 AND Recency <= 90 THEN 'Potential Loyalists'
        WHEN Recency <= 30 THEN 'New Customers'
        WHEN Recency > 180 THEN 'At Risk'
        WHEN Recency > 365 THEN 'Lost'
        ELSE 'Regular'
    END AS Segment
FROM CustomerMetrics
ORDER BY 
    CASE 
        WHEN Frequency >= 10 AND MonetaryValue >= 5000 THEN 1
        WHEN Frequency >= 5 AND MonetaryValue >= 2000 THEN 2
        ELSE 3
    END,
    MonetaryValue DESC;

-- Example 1.2: Customer Lifetime Value Categories
WITH CustomerValue AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent,
        COALESCE(COUNT(o.OrderID), 0) AS OrderCount
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    TotalSpent,
    OrderCount,
    CASE 
        WHEN TotalSpent >= 10000 THEN 'Platinum - VIP Treatment'
        WHEN TotalSpent >= 5000 THEN 'Gold - Priority Service'
        WHEN TotalSpent >= 2000 THEN 'Silver - Regular Service'
        WHEN TotalSpent >= 500 THEN 'Bronze - Standard Service'
        WHEN TotalSpent > 0 THEN 'Standard - Encourage Growth'
        ELSE 'Inactive - Re-engagement Campaign'
    END AS CustomerTier,
    CASE 
        WHEN TotalSpent >= 10000 THEN 20.0
        WHEN TotalSpent >= 5000 THEN 15.0
        WHEN TotalSpent >= 2000 THEN 10.0
        WHEN TotalSpent >= 500 THEN 5.0
        ELSE 0.0
    END AS DiscountPercent
FROM CustomerValue
ORDER BY TotalSpent DESC;

-- Example 1.3: Engagement Level
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    MAX(o.OrderDate) AS LastOrderDate,
    CASE 
        WHEN COUNT(o.OrderID) = 0 THEN 'Never Ordered'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 30 AND COUNT(o.OrderID) >= 5 
            THEN 'Highly Engaged'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 60 AND COUNT(o.OrderID) >= 3 
            THEN 'Moderately Engaged'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 90 
            THEN 'Somewhat Engaged'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) > 180 
            THEN 'Disengaged - Action Needed'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY EngagementLevel;


/*
============================================================================
PART 2: Grade and Score Calculation
============================================================================
*/

-- Example 2.1: Letter Grade Assignment
CREATE TABLE #StudentScores (
    StudentID INT,
    StudentName VARCHAR(50),
    Score DECIMAL(5,2)
);

INSERT INTO #StudentScores VALUES
(1, 'Alice', 95.5),
(2, 'Bob', 87.0),
(3, 'Charlie', 76.5),
(4, 'David', 68.0),
(5, 'Eve', 54.5),
(6, 'Frank', 92.0),
(7, 'Grace', 83.5),
(8, 'Henry', 71.0);

SELECT 
    StudentName,
    Score,
    CASE 
        WHEN Score >= 90 THEN 'A'
        WHEN Score >= 80 THEN 'B'
        WHEN Score >= 70 THEN 'C'
        WHEN Score >= 60 THEN 'D'
        ELSE 'F'
    END AS LetterGrade,
    CASE 
        WHEN Score >= 90 THEN 'Excellent'
        WHEN Score >= 80 THEN 'Good'
        WHEN Score >= 70 THEN 'Satisfactory'
        WHEN Score >= 60 THEN 'Needs Improvement'
        ELSE 'Failing'
    END AS Performance,
    CASE 
        WHEN Score >= 90 THEN 'Keep up the great work!'
        WHEN Score >= 70 THEN 'Good job, maintain your effort.'
        WHEN Score >= 60 THEN 'Please see instructor for help.'
        ELSE 'Immediate intervention required.'
    END AS Comment
FROM #StudentScores
ORDER BY Score DESC;

DROP TABLE #StudentScores;

-- Example 2.2: Performance Rating
CREATE TABLE #EmployeePerformance (
    EmployeeID INT,
    EmployeeName VARCHAR(50),
    SalesTarget DECIMAL(10,2),
    ActualSales DECIMAL(10,2)
);

INSERT INTO #EmployeePerformance VALUES
(1, 'John', 100000, 125000),
(2, 'Jane', 100000, 105000),
(3, 'Mike', 100000, 98000),
(4, 'Sara', 100000, 75000);

SELECT 
    EmployeeName,
    SalesTarget,
    ActualSales,
    ROUND((ActualSales / SalesTarget * 100), 2) AS PercentOfTarget,
    CASE 
        WHEN ActualSales >= SalesTarget * 1.2 THEN 'Outstanding - 20% Bonus'
        WHEN ActualSales >= SalesTarget * 1.1 THEN 'Exceeds - 15% Bonus'
        WHEN ActualSales >= SalesTarget THEN 'Meets - 10% Bonus'
        WHEN ActualSales >= SalesTarget * 0.9 THEN 'Below - 5% Bonus'
        ELSE 'Poor - No Bonus'
    END AS Rating
FROM #EmployeePerformance
ORDER BY PercentOfTarget DESC;

DROP TABLE #EmployeePerformance;


/*
============================================================================
PART 3: Status and Workflow Classification
============================================================================
*/

-- Example 3.1: Order Status Pipeline
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysSinceOrder,
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered ✓'
        WHEN ShipDate IS NOT NULL AND DATEDIFF(DAY, ShipDate, GETDATE()) > 5 
            THEN 'Shipped - Delayed'
        WHEN ShipDate IS NOT NULL THEN 'In Transit'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 3 THEN 'Processing - Delayed'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 1 THEN 'Processing'
        ELSE 'New Order'
    END AS Status,
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 'Complete'
        WHEN ShipDate IS NOT NULL AND DATEDIFF(DAY, ShipDate, GETDATE()) > 5 
            THEN 'Investigate Delay'
        WHEN ShipDate IS NOT NULL THEN 'Monitor'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 3 THEN 'Expedite Shipping'
        ELSE 'Normal Processing'
    END AS Action
FROM Orders
WHERE OrderID <= 30
ORDER BY 
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 3
        WHEN ShipDate IS NOT NULL THEN 2
        ELSE 1
    END,
    OrderDate;

-- Example 3.2: Inventory Management
SELECT 
    p.ProductName,
    p.UnitsInStock,
    p.ReorderLevel,
    CASE 
        WHEN p.UnitsInStock = 0 THEN 'OUT OF STOCK - URGENT'
        WHEN p.UnitsInStock <= p.ReorderLevel * 0.5 THEN 'CRITICAL - Reorder Now'
        WHEN p.UnitsInStock <= p.ReorderLevel THEN 'Low - Reorder Soon'
        WHEN p.UnitsInStock <= p.ReorderLevel * 2 THEN 'Adequate'
        ELSE 'Well Stocked'
    END AS StockStatus,
    CASE 
        WHEN p.UnitsInStock = 0 THEN 'Place emergency order'
        WHEN p.UnitsInStock <= p.ReorderLevel * 0.5 THEN 'Order immediately'
        WHEN p.UnitsInStock <= p.ReorderLevel THEN 'Schedule order this week'
        ELSE 'No action needed'
    END AS Action
FROM Products p
WHERE p.ProductID <= 20
ORDER BY 
    CASE 
        WHEN p.UnitsInStock = 0 THEN 1
        WHEN p.UnitsInStock <= p.ReorderLevel * 0.5 THEN 2
        WHEN p.UnitsInStock <= p.ReorderLevel THEN 3
        ELSE 4
    END,
    p.UnitsInStock;


/*
============================================================================
PART 4: Dynamic Sorting
============================================================================
*/

-- Example 4.1: Custom Priority Sorting
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    CustomerID,
    CASE 
        WHEN CustomerID IN (1, 2, 3) THEN 'VIP'
        WHEN TotalAmount > 1000 THEN 'High Value'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 7 THEN 'Old Order'
        ELSE 'Standard'
    END AS Priority
FROM Orders
ORDER BY 
    CASE 
        WHEN CustomerID IN (1, 2, 3) THEN 1
        WHEN TotalAmount > 1000 THEN 2
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 7 THEN 3
        ELSE 4
    END,
    OrderDate;

-- Example 4.2: Conditional Column Sorting
DECLARE @SortBy VARCHAR(20) = 'Price';
DECLARE @SortDirection VARCHAR(10) = 'DESC';

SELECT 
    ProductName,
    CategoryID,
    Price
FROM Products
ORDER BY 
    CASE 
        WHEN @SortBy = 'Name' AND @SortDirection = 'ASC' THEN ProductName
    END ASC,
    CASE 
        WHEN @SortBy = 'Name' AND @SortDirection = 'DESC' THEN ProductName
    END DESC,
    CASE 
        WHEN @SortBy = 'Price' AND @SortDirection = 'ASC' THEN Price
    END ASC,
    CASE 
        WHEN @SortBy = 'Price' AND @SortDirection = 'DESC' THEN Price
    END DESC;

-- Example 4.3: NULL Last Sorting
SELECT 
    ProductName,
    Price
FROM Products
ORDER BY 
    CASE WHEN Price IS NULL THEN 1 ELSE 0 END,  -- NULLs last
    Price;


/*
============================================================================
PART 5: Conditional Formatting
============================================================================
*/

-- Example 5.1: Traffic Light Status
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    CASE 
        WHEN TotalAmount > 1000 THEN '🟢 Green - High Value'
        WHEN TotalAmount > 500 THEN '🟡 Yellow - Medium Value'
        ELSE '🔴 Red - Low Value'
    END AS ValueIndicator,
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 7 THEN '🟢 Recent'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN '🟡 Normal'
        ELSE '🔴 Old'
    END AS RecencyIndicator
FROM Orders
WHERE OrderID <= 20;

-- Example 5.2: Currency Formatting
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'N/A'
        WHEN Price = 0 THEN 'FREE'
        WHEN Price < 10 THEN '$' + CAST(Price AS VARCHAR(10))
        WHEN Price < 100 THEN '$' + CAST(CAST(Price AS INT) AS VARCHAR(10))
        ELSE '$' + CAST(CAST(Price AS INT) AS VARCHAR(10)) + '+'
    END AS FormattedPrice
FROM Products
WHERE ProductID <= 15;

-- Example 5.3: Percentage Displays
WITH SalesData AS (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS TotalSales,
        (SELECT SUM(TotalAmount) FROM Orders) AS OverallSales
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    TotalSales,
    ROUND((TotalSales / OverallSales * 100), 2) AS PercentOfTotal,
    CASE 
        WHEN (TotalSales / OverallSales * 100) >= 10 THEN '⭐⭐⭐ Top Contributor'
        WHEN (TotalSales / OverallSales * 100) >= 5 THEN '⭐⭐ Major Contributor'
        WHEN (TotalSales / OverallSales * 100) >= 1 THEN '⭐ Contributor'
        ELSE 'Minor Contributor'
    END AS Contribution
FROM SalesData
ORDER BY PercentOfTotal DESC;


/*
============================================================================
PART 6: Complex Business Rules
============================================================================
*/

-- Example 6.1: Shipping Cost Calculation
SELECT 
    OrderID,
    TotalAmount,
    Country,
    CASE 
        WHEN Country = 'USA' AND TotalAmount >= 100 THEN 0.00
        WHEN Country = 'USA' AND TotalAmount >= 50 THEN 5.99
        WHEN Country = 'USA' THEN 9.99
        WHEN Country IN ('Canada', 'Mexico') AND TotalAmount >= 150 THEN 0.00
        WHEN Country IN ('Canada', 'Mexico') THEN 15.99
        WHEN TotalAmount >= 200 THEN 0.00
        ELSE 25.99
    END AS ShippingCost,
    CASE 
        WHEN Country = 'USA' AND TotalAmount >= 100 THEN 'Free Shipping!'
        WHEN Country = 'USA' AND TotalAmount >= 50 THEN 'Reduced Rate'
        WHEN TotalAmount >= 200 THEN 'Free International Shipping!'
        ELSE 'Standard Shipping'
    END AS ShippingMessage
FROM Orders
WHERE OrderID <= 20;

-- Example 6.2: Discount Eligibility
WITH CustomerOrderHistory AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    OrderCount,
    TotalSpent,
    LastOrderDate,
    CASE 
        -- VIP Customers: 10+ orders OR $5000+ spent
        WHEN OrderCount >= 10 OR TotalSpent >= 5000 THEN 25.0
        -- Loyal: 5+ orders AND recent activity
        WHEN OrderCount >= 5 AND DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 60 THEN 20.0
        -- Regular: 3+ orders
        WHEN OrderCount >= 3 THEN 15.0
        -- Reactivation: Inactive customers
        WHEN LastOrderDate IS NOT NULL AND DATEDIFF(DAY, LastOrderDate, GETDATE()) > 180 THEN 30.0
        -- New Customer Welcome
        WHEN OrderCount = 1 THEN 10.0
        ELSE 0.0
    END AS DiscountPercent,
    CASE 
        WHEN OrderCount >= 10 OR TotalSpent >= 5000 THEN 'VIP Discount'
        WHEN OrderCount >= 5 AND DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 60 THEN 'Loyalty Reward'
        WHEN OrderCount >= 3 THEN 'Regular Customer'
        WHEN LastOrderDate IS NOT NULL AND DATEDIFF(DAY, LastOrderDate, GETDATE()) > 180 THEN 'Welcome Back!'
        WHEN OrderCount = 1 THEN 'New Customer Welcome'
        ELSE 'Standard'
    END AS DiscountReason
FROM CustomerOrderHistory
ORDER BY DiscountPercent DESC, TotalSpent DESC;

-- Example 6.3: Credit Limit Approval
CREATE TABLE #CreditApplications (
    ApplicationID INT,
    ApplicantName VARCHAR(50),
    AnnualIncome DECIMAL(10,2),
    CreditScore INT,
    ExistingDebt DECIMAL(10,2)
);

INSERT INTO #CreditApplications VALUES
(1, 'John Doe', 75000, 750, 5000),
(2, 'Jane Smith', 45000, 680, 15000),
(3, 'Bob Johnson', 120000, 800, 2000),
(4, 'Alice Brown', 35000, 620, 25000);

SELECT 
    ApplicantName,
    AnnualIncome,
    CreditScore,
    ExistingDebt,
    ROUND((ExistingDebt / AnnualIncome * 100), 2) AS DebtToIncomeRatio,
    CASE 
        WHEN CreditScore >= 750 AND (ExistingDebt / AnnualIncome) <= 0.2 AND AnnualIncome >= 75000 
            THEN 'APPROVED - Platinum ($50,000 limit)'
        WHEN CreditScore >= 700 AND (ExistingDebt / AnnualIncome) <= 0.3 AND AnnualIncome >= 50000 
            THEN 'APPROVED - Gold ($25,000 limit)'
        WHEN CreditScore >= 650 AND (ExistingDebt / AnnualIncome) <= 0.4 AND AnnualIncome >= 35000 
            THEN 'APPROVED - Silver ($10,000 limit)'
        WHEN CreditScore >= 600 AND (ExistingDebt / AnnualIncome) <= 0.5 
            THEN 'CONDITIONAL - Review Required'
        ELSE 'DECLINED - Does not meet criteria'
    END AS Decision,
    CASE 
        WHEN CreditScore < 600 THEN 'Credit score too low'
        WHEN (ExistingDebt / AnnualIncome) > 0.5 THEN 'Debt-to-income ratio too high'
        WHEN AnnualIncome < 35000 THEN 'Income insufficient'
        ELSE 'Meets requirements'
    END AS Reason
FROM #CreditApplications
ORDER BY 
    CASE 
        WHEN CreditScore >= 750 THEN 1
        WHEN CreditScore >= 700 THEN 2
        WHEN CreditScore >= 650 THEN 3
        ELSE 4
    END;

DROP TABLE #CreditApplications;


/*
============================================================================
PART 7: Multi-Criteria Categorization
============================================================================
*/

-- Example 7.1: Product Classification Matrix
SELECT 
    ProductName,
    Price,
    UnitsInStock,
    CASE 
        WHEN Price > 200 AND UnitsInStock > 50 THEN 'Premium - Well Stocked'
        WHEN Price > 200 AND UnitsInStock > 0 THEN 'Premium - Limited Stock'
        WHEN Price > 200 THEN 'Premium - OUT OF STOCK'
        WHEN Price > 100 AND UnitsInStock > 50 THEN 'Mid-Range - Well Stocked'
        WHEN Price > 100 AND UnitsInStock > 0 THEN 'Mid-Range - Limited Stock'
        WHEN Price > 100 THEN 'Mid-Range - OUT OF STOCK'
        WHEN UnitsInStock > 50 THEN 'Budget - Well Stocked'
        WHEN UnitsInStock > 0 THEN 'Budget - Limited Stock'
        ELSE 'Budget - OUT OF STOCK'
    END AS Classification,
    CASE 
        WHEN Price > 200 AND UnitsInStock = 0 THEN 'URGENT: Restock premium item'
        WHEN Price > 100 AND UnitsInStock < 10 THEN 'WARNING: Low mid-range stock'
        WHEN UnitsInStock = 0 THEN 'Restock needed'
        WHEN UnitsInStock < 20 THEN 'Monitor stock levels'
        ELSE 'Stock OK'
    END AS StockAlert
FROM Products
WHERE ProductID <= 20
ORDER BY 
    CASE 
        WHEN Price > 200 AND UnitsInStock = 0 THEN 1
        WHEN UnitsInStock = 0 THEN 2
        WHEN UnitsInStock < 10 THEN 3
        ELSE 4
    END,
    Price DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create customer loyalty tiers based on total orders and spending
2. Calculate letter grades with +/- (A+, A, A-, B+, etc.)
3. Build order fulfillment status with timeline expectations
4. Design dynamic pricing based on customer segment and order size
5. Create product recommendation priority based on sales and stock

Solutions below ↓
*/

-- Solution 1:
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    OrderCount,
    TotalSpent,
    CASE 
        WHEN TotalSpent >= 10000 AND OrderCount >= 10 THEN 'Diamond'
        WHEN TotalSpent >= 5000 OR OrderCount >= 10 THEN 'Platinum'
        WHEN TotalSpent >= 2000 OR OrderCount >= 5 THEN 'Gold'
        WHEN TotalSpent >= 500 OR OrderCount >= 2 THEN 'Silver'
        WHEN TotalSpent > 0 THEN 'Bronze'
        ELSE 'None'
    END AS LoyaltyTier
FROM CustomerMetrics
ORDER BY TotalSpent DESC;

-- Solution 2:
CREATE TABLE #DetailedScores (StudentName VARCHAR(50), Score DECIMAL(5,2));
INSERT INTO #DetailedScores VALUES 
('Student1', 97), ('Student2', 92), ('Student3', 88), ('Student4', 85), 
('Student5', 82), ('Student6', 78), ('Student7', 75), ('Student8', 72);

SELECT 
    StudentName,
    Score,
    CASE 
        WHEN Score >= 97 THEN 'A+'
        WHEN Score >= 93 THEN 'A'
        WHEN Score >= 90 THEN 'A-'
        WHEN Score >= 87 THEN 'B+'
        WHEN Score >= 83 THEN 'B'
        WHEN Score >= 80 THEN 'B-'
        WHEN Score >= 77 THEN 'C+'
        WHEN Score >= 73 THEN 'C'
        WHEN Score >= 70 THEN 'C-'
        ELSE 'F'
    END AS Grade
FROM #DetailedScores;

DROP TABLE #DetailedScores;

-- Solution 3: (see answer in lesson)
-- Solution 4: (see answer in lesson)
-- Solution 5: (see answer in lesson)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CUSTOMER SEGMENTATION:
  • RFM analysis (Recency, Frequency, Monetary)
  • Lifetime value categorization
  • Engagement levels
  • Loyalty tiers

✓ GRADING SYSTEMS:
  • Letter grades
  • Performance ratings
  • Score categorization
  • Pass/fail determination

✓ STATUS WORKFLOWS:
  • Order processing pipelines
  • Inventory management
  • Approval workflows
  • State machines

✓ DYNAMIC SORTING:
  • Priority-based ordering
  • Custom sort sequences
  • NULL handling
  • Multi-column conditional sorting

✓ FORMATTING:
  • Traffic light indicators
  • Currency display
  • Percentage representations
  • Visual status markers

✓ BUSINESS RULES:
  • Shipping cost calculation
  • Discount eligibility
  • Credit approval
  • Complex multi-criteria logic

✓ BEST PRACTICES:
  • Order conditions by specificity
  • Include all edge cases
  • Document complex logic
  • Test thoroughly
  • Consider maintainability
  • Use meaningful categories

============================================================================
NEXT: Lesson 11.06 - Result Set Transformations
Learn to pivot data using CASE expressions.
============================================================================
*/
