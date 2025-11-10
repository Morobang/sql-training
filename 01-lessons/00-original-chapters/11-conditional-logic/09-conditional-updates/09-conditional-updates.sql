/*
============================================================================
Lesson 11.09 - Conditional Updates
============================================================================

Description:
Master using CASE expressions in UPDATE statements to conditionally modify
data based on complex business rules. Learn UPDATE with CASE, conditional
column updates, bulk modifications, and MERGE operations.

Topics Covered:
• UPDATE with CASE expressions
• Conditional column updates
• Multiple column updates
• Complex update conditions
• UPDATE with subqueries
• MERGE with CASE
• Audit and tracking updates
• Performance considerations

Prerequisites:
• Lessons 11.01-11.08
• Lesson 02.10 (Updating Data)

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic UPDATE with CASE
============================================================================
*/

-- Example 1.1: Simple Conditional Update
-- Create test table
CREATE TABLE #ProductPricing (
    ProductID INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2),
    CategoryID INT
);

INSERT INTO #ProductPricing 
SELECT ProductID, ProductName, Price, CategoryID 
FROM Products 
WHERE ProductID <= 20;

-- View before update
SELECT * FROM #ProductPricing;

-- Update: Apply 10% discount to expensive products
UPDATE #ProductPricing
SET Price = CASE 
    WHEN Price > 200 THEN Price * 0.90
    WHEN Price > 100 THEN Price * 0.95
    ELSE Price
END;

-- View after update
SELECT * FROM #ProductPricing;

/*
Execution Flow:
1. For each row in table
2. Evaluate CASE expression
3. Return new value based on condition
4. Update Price column with new value

Note: CASE can reference the column being updated
*/

-- Example 1.2: Categorization Update
ALTER TABLE #ProductPricing ADD PriceCategory VARCHAR(20);

UPDATE #ProductPricing
SET PriceCategory = CASE 
    WHEN Price >= 200 THEN 'Premium'
    WHEN Price >= 100 THEN 'Standard'
    ELSE 'Budget'
END;

SELECT ProductName, Price, PriceCategory FROM #ProductPricing;

-- Example 1.3: Conditional Update with WHERE
-- Only update specific rows
UPDATE #ProductPricing
SET Price = CASE 
    WHEN CategoryID = 1 THEN Price * 1.10
    WHEN CategoryID = 2 THEN Price * 1.05
    ELSE Price
END
WHERE Price < 150;  -- Only update products under $150

SELECT ProductName, Price, CategoryID FROM #ProductPricing;

DROP TABLE #ProductPricing;


/*
============================================================================
PART 2: Multiple Column Updates
============================================================================
*/

-- Example 2.1: Update Multiple Columns Conditionally
CREATE TABLE #InventoryUpdate (
    ProductID INT,
    ProductName VARCHAR(50),
    UnitsInStock INT,
    ReorderLevel INT,
    Status VARCHAR(20),
    ActionNeeded VARCHAR(50)
);

INSERT INTO #InventoryUpdate
SELECT 
    ProductID, 
    ProductName, 
    UnitsInStock, 
    ReorderLevel,
    NULL AS Status,
    NULL AS ActionNeeded
FROM Products 
WHERE ProductID <= 15;

-- Update both Status and ActionNeeded
UPDATE #InventoryUpdate
SET 
    Status = CASE 
        WHEN UnitsInStock = 0 THEN 'OUT OF STOCK'
        WHEN UnitsInStock <= ReorderLevel THEN 'LOW'
        WHEN UnitsInStock <= ReorderLevel * 2 THEN 'NORMAL'
        ELSE 'HIGH'
    END,
    ActionNeeded = CASE 
        WHEN UnitsInStock = 0 THEN 'URGENT: Emergency reorder'
        WHEN UnitsInStock <= ReorderLevel * 0.5 THEN 'Place order today'
        WHEN UnitsInStock <= ReorderLevel THEN 'Schedule order this week'
        ELSE 'No action required'
    END;

SELECT ProductName, UnitsInStock, ReorderLevel, Status, ActionNeeded 
FROM #InventoryUpdate;

DROP TABLE #InventoryUpdate;

-- Example 2.2: Coordinated Multi-Column Update
CREATE TABLE #EmployeeAdjustments (
    EmployeeID INT,
    EmployeeName VARCHAR(50),
    CurrentSalary DECIMAL(10,2),
    PerformanceRating INT,
    NewSalary DECIMAL(10,2),
    BonusPercent DECIMAL(5,2)
);

INSERT INTO #EmployeeAdjustments VALUES
(1, 'Alice', 50000, 5, NULL, NULL),
(2, 'Bob', 60000, 4, NULL, NULL),
(3, 'Charlie', 55000, 3, NULL, NULL),
(4, 'David', 45000, 2, NULL, NULL);

-- Update salary and bonus based on performance
UPDATE #EmployeeAdjustments
SET 
    NewSalary = CASE 
        WHEN PerformanceRating >= 5 THEN CurrentSalary * 1.15
        WHEN PerformanceRating >= 4 THEN CurrentSalary * 1.10
        WHEN PerformanceRating >= 3 THEN CurrentSalary * 1.05
        ELSE CurrentSalary
    END,
    BonusPercent = CASE 
        WHEN PerformanceRating >= 5 THEN 20.0
        WHEN PerformanceRating >= 4 THEN 15.0
        WHEN PerformanceRating >= 3 THEN 10.0
        ELSE 0.0
    END;

SELECT * FROM #EmployeeAdjustments;

DROP TABLE #EmployeeAdjustments;


/*
============================================================================
PART 3: Complex Update Conditions
============================================================================
*/

-- Example 3.1: UPDATE with Subquery in CASE
CREATE TABLE #CustomerStatus (
    CustomerID INT,
    CustomerName VARCHAR(100),
    Tier VARCHAR(20),
    DiscountPercent DECIMAL(5,2)
);

INSERT INTO #CustomerStatus
SELECT CustomerID, CustomerName, NULL, NULL
FROM Customers
WHERE CustomerID <= 20;

-- Update tier based on order history
UPDATE cs
SET 
    Tier = CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 10 
            THEN 'Platinum'
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 5 
            THEN 'Gold'
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 2 
            THEN 'Silver'
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = cs.CustomerID) 
            THEN 'Bronze'
        ELSE 'None'
    END,
    DiscountPercent = CASE 
        WHEN (SELECT SUM(TotalAmount) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 5000 
            THEN 25.0
        WHEN (SELECT SUM(TotalAmount) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 2000 
            THEN 15.0
        WHEN (SELECT SUM(TotalAmount) FROM Orders o WHERE o.CustomerID = cs.CustomerID) >= 500 
            THEN 10.0
        ELSE 0.0
    END
FROM #CustomerStatus cs;

SELECT * FROM #CustomerStatus ORDER BY Tier DESC;

DROP TABLE #CustomerStatus;

-- Example 3.2: UPDATE with JOIN
CREATE TABLE #ProductReview (
    ProductID INT,
    ProductName VARCHAR(50),
    SalesCategory VARCHAR(20)
);

INSERT INTO #ProductReview
SELECT ProductID, ProductName, NULL
FROM Products
WHERE ProductID <= 20;

-- Categorize based on sales volume
UPDATE pr
SET SalesCategory = CASE 
    WHEN COALESCE(od.TotalQuantity, 0) >= 100 THEN 'Best Seller'
    WHEN COALESCE(od.TotalQuantity, 0) >= 50 THEN 'Popular'
    WHEN COALESCE(od.TotalQuantity, 0) >= 10 THEN 'Regular'
    WHEN COALESCE(od.TotalQuantity, 0) > 0 THEN 'Slow Moving'
    ELSE 'Never Sold'
END
FROM #ProductReview pr
LEFT JOIN (
    SELECT ProductID, SUM(Quantity) AS TotalQuantity
    FROM OrderDetails
    GROUP BY ProductID
) od ON pr.ProductID = od.ProductID;

SELECT * FROM #ProductReview ORDER BY SalesCategory;

DROP TABLE #ProductReview;


/*
============================================================================
PART 4: Conditional INSERT with CASE
============================================================================
*/

-- Example 4.1: INSERT with CASE
CREATE TABLE #PriceHistory (
    ProductID INT,
    ProductName VARCHAR(50),
    CurrentPrice DECIMAL(10,2),
    PriceCategory VARCHAR(20),
    RecommendedAction VARCHAR(50)
);

-- Insert with categorization
INSERT INTO #PriceHistory (ProductID, ProductName, CurrentPrice, PriceCategory, RecommendedAction)
SELECT 
    ProductID,
    ProductName,
    Price,
    CASE 
        WHEN Price > 200 THEN 'Premium'
        WHEN Price > 100 THEN 'Mid-Range'
        ELSE 'Budget'
    END,
    CASE 
        WHEN Price > 200 AND UnitsInStock < ReorderLevel THEN 'Restock Premium Item'
        WHEN Price < 50 AND UnitsInStock > 100 THEN 'Clearance Sale'
        WHEN UnitsInStock = 0 THEN 'Emergency Reorder'
        ELSE 'No Action'
    END
FROM Products
WHERE ProductID <= 15;

SELECT * FROM #PriceHistory;

DROP TABLE #PriceHistory;

-- Example 4.2: INSERT from Conditional SELECT
CREATE TABLE #CustomerSegments (
    CustomerID INT,
    Segment VARCHAR(50),
    Priority INT
);

INSERT INTO #CustomerSegments (CustomerID, Segment, Priority)
SELECT 
    c.CustomerID,
    CASE 
        WHEN COUNT(o.OrderID) >= 10 AND SUM(o.TotalAmount) >= 5000 THEN 'VIP'
        WHEN COUNT(o.OrderID) >= 5 THEN 'Loyal'
        WHEN COUNT(o.OrderID) >= 2 THEN 'Regular'
        WHEN COUNT(o.OrderID) = 1 THEN 'New'
        ELSE 'Inactive'
    END,
    CASE 
        WHEN COUNT(o.OrderID) >= 10 AND SUM(o.TotalAmount) >= 5000 THEN 1
        WHEN COUNT(o.OrderID) >= 5 THEN 2
        WHEN COUNT(o.OrderID) >= 2 THEN 3
        WHEN COUNT(o.OrderID) = 1 THEN 4
        ELSE 5
    END
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 20
GROUP BY c.CustomerID;

SELECT * FROM #CustomerSegments ORDER BY Priority;

DROP TABLE #CustomerSegments;


/*
============================================================================
PART 5: MERGE with CASE
============================================================================
*/

-- Example 5.1: Basic MERGE with CASE
CREATE TABLE #TargetPrices (
    ProductID INT PRIMARY KEY,
    CurrentPrice DECIMAL(10,2)
);

INSERT INTO #TargetPrices 
SELECT ProductID, Price 
FROM Products 
WHERE ProductID BETWEEN 1 AND 10;

-- Source: new pricing rules
CREATE TABLE #NewPricing (
    ProductID INT,
    NewPrice DECIMAL(10,2),
    ChangeType VARCHAR(20)
);

INSERT INTO #NewPricing VALUES
(5, 120.00, 'Increase'),
(8, 85.00, 'Decrease'),
(12, 95.00, 'New'),
(15, 200.00, 'New');

-- MERGE with CASE logic
MERGE #TargetPrices AS target
USING #NewPricing AS source
ON target.ProductID = source.ProductID
WHEN MATCHED THEN
    UPDATE SET CurrentPrice = CASE 
        WHEN source.ChangeType = 'Increase' AND source.NewPrice > target.CurrentPrice 
            THEN source.NewPrice
        WHEN source.ChangeType = 'Decrease' AND source.NewPrice < target.CurrentPrice 
            THEN source.NewPrice
        ELSE target.CurrentPrice  -- No change if conditions not met
    END
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, CurrentPrice)
    VALUES (source.ProductID, source.NewPrice);

SELECT * FROM #TargetPrices ORDER BY ProductID;

DROP TABLE #TargetPrices;
DROP TABLE #NewPricing;

-- Example 5.2: Complex MERGE with Multiple Conditions
CREATE TABLE #InventoryMaster (
    ProductID INT PRIMARY KEY,
    StockLevel INT,
    Status VARCHAR(20),
    LastUpdated DATETIME
);

INSERT INTO #InventoryMaster
SELECT ProductID, UnitsInStock, 'ACTIVE', GETDATE()
FROM Products
WHERE ProductID <= 10;

CREATE TABLE #InventoryChanges (
    ProductID INT,
    QuantityChange INT,
    ChangeReason VARCHAR(50)
);

INSERT INTO #InventoryChanges VALUES
(1, -5, 'Sale'),
(3, 50, 'Restock'),
(5, -100, 'Sale'),
(12, 25, 'New Product');

MERGE #InventoryMaster AS target
USING #InventoryChanges AS source
ON target.ProductID = source.ProductID
WHEN MATCHED THEN
    UPDATE SET 
        StockLevel = target.StockLevel + source.QuantityChange,
        Status = CASE 
            WHEN target.StockLevel + source.QuantityChange = 0 THEN 'OUT_OF_STOCK'
            WHEN target.StockLevel + source.QuantityChange < 10 THEN 'LOW_STOCK'
            WHEN target.StockLevel + source.QuantityChange > 100 THEN 'OVERSTOCKED'
            ELSE 'NORMAL'
        END,
        LastUpdated = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, StockLevel, Status, LastUpdated)
    VALUES (
        source.ProductID, 
        source.QuantityChange,
        CASE 
            WHEN source.QuantityChange = 0 THEN 'OUT_OF_STOCK'
            WHEN source.QuantityChange < 10 THEN 'LOW_STOCK'
            ELSE 'NORMAL'
        END,
        GETDATE()
    );

SELECT * FROM #InventoryMaster ORDER BY ProductID;

DROP TABLE #InventoryMaster;
DROP TABLE #InventoryChanges;


/*
============================================================================
PART 6: Audit and Tracking Updates
============================================================================
*/

-- Example 6.1: Audit Trail with Conditional Updates
CREATE TABLE #OrderTracking (
    OrderID INT,
    CurrentStatus VARCHAR(20),
    PreviousStatus VARCHAR(20),
    StatusChangedDate DATETIME,
    DaysInCurrentStatus INT
);

INSERT INTO #OrderTracking
SELECT 
    OrderID,
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered'
        WHEN ShipDate IS NOT NULL THEN 'Shipped'
        ELSE 'Processing'
    END,
    NULL,
    GETDATE(),
    0
FROM Orders
WHERE OrderID <= 20;

-- Simulate status update
UPDATE #OrderTracking
SET 
    PreviousStatus = CurrentStatus,
    CurrentStatus = CASE 
        WHEN CurrentStatus = 'Processing' AND RAND() > 0.5 THEN 'Shipped'
        WHEN CurrentStatus = 'Shipped' AND RAND() > 0.7 THEN 'Delivered'
        ELSE CurrentStatus
    END,
    StatusChangedDate = CASE 
        WHEN CurrentStatus <> CASE 
            WHEN CurrentStatus = 'Processing' AND RAND() > 0.5 THEN 'Shipped'
            WHEN CurrentStatus = 'Shipped' AND RAND() > 0.7 THEN 'Delivered'
            ELSE CurrentStatus
        END THEN GETDATE()
        ELSE StatusChangedDate
    END;

SELECT * FROM #OrderTracking;

DROP TABLE #OrderTracking;

-- Example 6.2: Conditional Version Tracking
CREATE TABLE #ProductVersions (
    ProductID INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2),
    PriceVersion INT,
    LastPriceChange DATETIME
);

INSERT INTO #ProductVersions
SELECT ProductID, ProductName, Price, 1, GETDATE()
FROM Products
WHERE ProductID <= 10;

-- Update with version increment
UPDATE #ProductVersions
SET 
    Price = CASE 
        WHEN ProductID <= 5 THEN Price * 1.10
        ELSE Price
    END,
    PriceVersion = CASE 
        WHEN ProductID <= 5 THEN PriceVersion + 1
        ELSE PriceVersion
    END,
    LastPriceChange = CASE 
        WHEN ProductID <= 5 THEN GETDATE()
        ELSE LastPriceChange
    END;

SELECT * FROM #ProductVersions;

DROP TABLE #ProductVersions;


/*
============================================================================
PART 7: Performance Considerations
============================================================================
*/

-- Example 7.1: Efficient UPDATE Pattern
-- INEFFICIENT: Multiple updates
-- UPDATE Products SET Status = 'Low' WHERE UnitsInStock < 10;
-- UPDATE Products SET Status = 'Medium' WHERE UnitsInStock BETWEEN 10 AND 50;
-- UPDATE Products SET Status = 'High' WHERE UnitsInStock > 50;

-- EFFICIENT: Single UPDATE with CASE
CREATE TABLE #ProductStock (
    ProductID INT,
    UnitsInStock INT,
    Status VARCHAR(20)
);

INSERT INTO #ProductStock
SELECT ProductID, UnitsInStock, NULL
FROM Products
WHERE ProductID <= 20;

UPDATE #ProductStock
SET Status = CASE 
    WHEN UnitsInStock < 10 THEN 'Low'
    WHEN UnitsInStock <= 50 THEN 'Medium'
    ELSE 'High'
END;

SELECT * FROM #ProductStock;

DROP TABLE #ProductStock;

-- Example 7.2: Avoiding Unnecessary Updates
-- INEFFICIENT: Updates all rows even if value doesn't change
UPDATE Products
SET Price = CASE 
    WHEN CategoryID = 1 THEN Price * 1.10
    ELSE Price  -- Unnecessary update!
END;

-- EFFICIENT: Only update when necessary
UPDATE Products
SET Price = Price * 1.10
WHERE CategoryID = 1;

/*
Performance Tips:
1. Use single UPDATE with CASE instead of multiple UPDATEs
2. Use WHERE to limit rows updated
3. Avoid "ELSE same_value" that updates unnecessarily
4. Index columns used in CASE conditions
5. Use batch updates for large tables
6. Consider partitioning for very large updates
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Update customer loyalty status based on purchase history
2. Adjust product prices based on sales performance and stock levels
3. Update order priorities based on customer tier and order value
4. Create a MERGE to sync product prices with conditional logic
5. Build an audit system that tracks all status changes

Solutions below ↓
*/

-- Solution 1: Customer Loyalty Update
CREATE TABLE #CustomerLoyalty (
    CustomerID INT,
    CustomerName VARCHAR(100),
    LoyaltyStatus VARCHAR(20),
    DiscountPercent DECIMAL(5,2)
);

INSERT INTO #CustomerLoyalty
SELECT CustomerID, CustomerName, NULL, NULL
FROM Customers
WHERE CustomerID <= 15;

UPDATE cl
SET 
    LoyaltyStatus = CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 10 
            THEN 'Diamond'
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 5 
            THEN 'Gold'
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 2 
            THEN 'Silver'
        ELSE 'Standard'
    END,
    DiscountPercent = CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 10 
            THEN 20.0
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 5 
            THEN 15.0
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = cl.CustomerID) >= 2 
            THEN 10.0
        ELSE 5.0
    END
FROM #CustomerLoyalty cl;

SELECT * FROM #CustomerLoyalty;

DROP TABLE #CustomerLoyalty;

-- Solution 2: Dynamic Pricing
CREATE TABLE #DynamicPricing (
    ProductID INT,
    ProductName VARCHAR(50),
    CurrentPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2)
);

INSERT INTO #DynamicPricing
SELECT ProductID, ProductName, Price, Price
FROM Products
WHERE ProductID <= 15;

UPDATE dp
SET NewPrice = CASE 
    -- High sales, low stock: increase price
    WHEN od.TotalSold >= 50 AND p.UnitsInStock < p.ReorderLevel 
        THEN dp.CurrentPrice * 1.15
    -- Low sales, high stock: decrease price
    WHEN COALESCE(od.TotalSold, 0) < 10 AND p.UnitsInStock > p.ReorderLevel * 2 
        THEN dp.CurrentPrice * 0.85
    -- Normal sales: small increase
    WHEN od.TotalSold >= 20 
        THEN dp.CurrentPrice * 1.05
    ELSE dp.CurrentPrice
END
FROM #DynamicPricing dp
INNER JOIN Products p ON dp.ProductID = p.ProductID
LEFT JOIN (
    SELECT ProductID, SUM(Quantity) AS TotalSold
    FROM OrderDetails
    GROUP BY ProductID
) od ON dp.ProductID = od.ProductID;

SELECT ProductName, CurrentPrice, NewPrice, 
    ROUND((NewPrice - CurrentPrice) / CurrentPrice * 100, 2) AS ChangePercent
FROM #DynamicPricing;

DROP TABLE #DynamicPricing;

-- Solution 3: Order Priority
CREATE TABLE #OrderPriority (
    OrderID INT,
    CustomerID INT,
    TotalAmount DECIMAL(10,2),
    Priority VARCHAR(20)
);

INSERT INTO #OrderPriority
SELECT OrderID, CustomerID, TotalAmount, NULL
FROM Orders
WHERE OrderID <= 20;

UPDATE op
SET Priority = CASE 
    WHEN cs.OrderCount >= 10 AND op.TotalAmount > 1000 THEN 'VIP_URGENT'
    WHEN cs.OrderCount >= 10 THEN 'VIP_NORMAL'
    WHEN op.TotalAmount > 1000 THEN 'HIGH_VALUE'
    WHEN cs.OrderCount >= 5 THEN 'LOYAL_CUSTOMER'
    ELSE 'STANDARD'
END
FROM #OrderPriority op
INNER JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) cs ON op.CustomerID = cs.CustomerID;

SELECT * FROM #OrderPriority ORDER BY Priority;

DROP TABLE #OrderPriority;

-- Solution 4: (see MERGE examples in lesson)
-- Solution 5: (see audit examples in lesson)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ UPDATE WITH CASE:
  • SET column = CASE WHEN ... THEN ... END
  • Can reference same column being updated
  • Evaluates for each row
  • More efficient than multiple UPDATEs

✓ MULTIPLE COLUMNS:
  • Update multiple columns in single statement
  • Each can have independent CASE logic
  • Can coordinate related updates
  • Use aliases for readability

✓ COMPLEX CONDITIONS:
  • Use subqueries in CASE WHEN
  • JOIN with UPDATE for related table data
  • EXISTS for existence checks
  • Aggregate functions in conditions

✓ INSERT WITH CASE:
  • Set values conditionally during INSERT
  • Calculate derived columns
  • Categorize during data loading
  • Transform source data

✓ MERGE OPERATIONS:
  • Combine INSERT/UPDATE/DELETE
  • Use CASE in WHEN MATCHED
  • Conditional logic for each action
  • Complex business rules

✓ AUDIT TRACKING:
  • Track previous values
  • Record change timestamps
  • Version incrementing
  • Status history

✓ PERFORMANCE:
  • Single UPDATE > multiple UPDATEs
  • Use WHERE to limit scope
  • Avoid unnecessary updates (ELSE same_value)
  • Index condition columns
  • Batch large updates

✓ BEST PRACTICES:
  • Test on sample data first
  • Use transactions for critical updates
  • Document complex CASE logic
  • Validate after update (check results)
  • Consider triggers for audit
  • Use MERGE for upsert patterns
  • Keep conditions mutually exclusive

✓ COMMON PATTERNS:
  • Categorization: Assign tiers, statuses
  • Pricing: Dynamic adjustments
  • Inventory: Stock level management
  • Status tracking: Workflow updates
  • Data cleanup: Standardization
  • Bulk modifications: Mass updates

✓ TESTING:
  • SELECT with CASE before UPDATE
  • Test on copy of table
  • Use BEGIN TRAN / ROLLBACK
  • Verify affected row count (@@ROWCOUNT)
  • Check edge cases

============================================================================
NEXT: Lesson 11.10 - Handling NULL Values
Learn advanced NULL handling with CASE, COALESCE, and ISNULL.
============================================================================
*/
