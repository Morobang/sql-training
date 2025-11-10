/*
============================================================================
Lesson 11.07 - Checking for Existence
============================================================================

Description:
Master using CASE expressions with EXISTS and NOT EXISTS subqueries to
create conditional flags, indicators, and classifications based on the
presence or absence of related data.

Topics Covered:
• CASE with EXISTS subqueries
• NOT EXISTS for negative conditions
• Multiple existence checks
• Existence-based flags and indicators
• Performance considerations
• Complex existence patterns
• Correlated existence checks

Prerequisites:
• Lessons 11.01-11.06
• Lesson 09 (Subqueries)

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic CASE with EXISTS
============================================================================
*/

-- Example 1.1: Customer Activity Flag
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o 
            WHERE o.CustomerID = c.CustomerID
        ) THEN 'Active'
        ELSE 'Inactive'
    END AS Status
FROM Customers c
ORDER BY CustomerID;

/*
Execution Flow:
1. For each customer row
2. Execute EXISTS subquery (correlated)
3. If any orders exist, EXISTS returns TRUE
4. CASE returns 'Active', otherwise 'Inactive'

Performance Note:
EXISTS stops as soon as it finds first match (short-circuit evaluation)
*/

-- Example 1.2: Product Purchase Status
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN 'Has Been Ordered'
        ELSE 'Never Ordered'
    END AS PurchaseStatus,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID 
            AND od.OrderID IN (
                SELECT OrderID 
                FROM Orders 
                WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())
            )
        ) THEN 'Recent Sales'
        ELSE 'No Recent Sales'
    END AS RecentActivity
FROM Products p
WHERE p.ProductID <= 20
ORDER BY p.ProductID;

-- Example 1.3: Count vs EXISTS
-- INEFFICIENT: Using COUNT
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) > 0 
            THEN 'Has Orders'
        ELSE 'No Orders'
    END AS Status
FROM Customers c;

-- EFFICIENT: Using EXISTS
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) 
            THEN 'Has Orders'
        ELSE 'No Orders'
    END AS Status
FROM Customers c;

/*
Why EXISTS is better:
• COUNT(*) scans all matching rows
• EXISTS stops at first match
• EXISTS is faster for existence checks
• EXISTS clearer intent
*/


/*
============================================================================
PART 2: NOT EXISTS Conditions
============================================================================
*/

-- Example 2.1: Find Customers Who Never Ordered
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 
            FROM Orders o 
            WHERE o.CustomerID = c.CustomerID
        ) THEN 'Never Purchased - Send Welcome Offer'
        ELSE 'Existing Customer'
    END AS Marketing_Action
FROM Customers c
ORDER BY 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) 
            THEN 0 
        ELSE 1 
    END;

-- Example 2.2: Products Never Sold
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.UnitsInStock,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 
            FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN 'Never Sold - Consider Discount'
        WHEN NOT EXISTS (
            SELECT 1 
            FROM OrderDetails od 
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(MONTH, -3, GETDATE())
        ) THEN 'No Sales Last 3 Months - Review Pricing'
        ELSE 'Active Product'
    END AS ProductStatus
FROM Products p
WHERE p.ProductID <= 25
ORDER BY 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID) 
            THEN 1
        ELSE 2
    END;

-- Example 2.3: Customers Without Recent Activity
SELECT 
    c.CustomerID,
    c.CustomerName,
    MAX(o.OrderDate) AS Last_Order_Date,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 
            FROM Orders o2 
            WHERE o2.CustomerID = c.CustomerID 
            AND o2.OrderDate >= DATEADD(DAY, -90, GETDATE())
        ) THEN 'Inactive - Re-engagement Needed'
        ELSE 'Recently Active'
    END AS Engagement_Status
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY Last_Order_Date;


/*
============================================================================
PART 3: Multiple Existence Checks
============================================================================
*/

-- Example 3.1: Customer Segmentation with Multiple Checks
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.TotalAmount > 1000
        ) AND EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) THEN 'VIP - High Value & Active'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.TotalAmount > 1000
        ) THEN 'High Value - Not Recent'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) THEN 'Active - Lower Value'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID
        ) THEN 'Dormant - Re-engage'
        
        ELSE 'Never Purchased'
    END AS Customer_Segment
FROM Customers c
ORDER BY Customer_Segment;

-- Example 3.2: Product Category Analysis
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID 
            HAVING COUNT(*) >= 10
        ) THEN 'Best Seller'
        
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID 
            HAVING COUNT(*) >= 5
        ) THEN 'Popular'
        
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN 'Sold Occasionally'
        
        ELSE 'Never Sold'
    END AS Sales_Performance,
    
    CASE 
        WHEN p.UnitsInStock = 0 AND EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN 'Out of Stock - Reorder Urgent'
        
        WHEN p.UnitsInStock < p.ReorderLevel AND NOT EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN 'Low Stock - Never Sold - Clearance'
        
        ELSE 'Stock OK'
    END AS Inventory_Action
FROM Products p
WHERE p.ProductID <= 20
ORDER BY p.ProductID;

-- Example 3.3: Order Fulfillment Status
SELECT 
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Orders o2 
            WHERE o2.OrderID = o.OrderID 
            AND o2.DeliveryDate IS NOT NULL
        ) THEN '✓ Delivered'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o2 
            WHERE o2.OrderID = o.OrderID 
            AND o2.ShipDate IS NOT NULL
        ) THEN '→ In Transit'
        
        WHEN NOT EXISTS (
            SELECT 1 FROM Orders o2 
            WHERE o2.OrderID = o.OrderID 
            AND o2.ShipDate IS NOT NULL
        ) AND DATEDIFF(DAY, o.OrderDate, GETDATE()) > 3 
            THEN '⚠ Delayed Processing'
        
        ELSE '• Processing'
    END AS Fulfillment_Status
FROM Orders o
WHERE o.OrderID <= 30
ORDER BY o.OrderID;


/*
============================================================================
PART 4: Existence-Based Flags and Indicators
============================================================================
*/

-- Example 4.1: Binary Flags
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) 
        THEN 1 ELSE 0 END AS Has_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.TotalAmount > 500) 
        THEN 1 ELSE 0 END AS Has_Large_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND YEAR(o.OrderDate) = 2024) 
        THEN 1 ELSE 0 END AS Ordered_This_Year,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())) 
        THEN 1 ELSE 0 END AS Active_Last_30_Days
FROM Customers c
WHERE c.CustomerID <= 15
ORDER BY c.CustomerID;

-- Example 4.2: Multi-Level Indicators
SELECT 
    p.ProductID,
    p.ProductName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(DAY, -7, GETDATE())
        ) THEN '🔥 Hot'
        
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) THEN '📈 Trending'
        
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            WHERE od.ProductID = p.ProductID
        ) THEN '📊 Steady'
        
        ELSE '❄ Cold'
    END AS Product_Temperature
FROM Products p
WHERE p.ProductID <= 20
ORDER BY 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(DAY, -7, GETDATE())
        ) THEN 1
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od 
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) THEN 2
        ELSE 3
    END;

-- Example 4.3: Composite Status Indicators
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID)
            THEN '✓' ELSE '✗' 
    END + ' Orders | ' +
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.TotalAmount > 500)
            THEN '✓' ELSE '✗' 
    END + ' High Value | ' +
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -60, GETDATE()))
            THEN '✓' ELSE '✗' 
    END + ' Recent' AS Status_Indicators
FROM Customers c
WHERE c.CustomerID <= 10
ORDER BY c.CustomerID;


/*
============================================================================
PART 5: Performance Considerations
============================================================================
*/

-- Example 5.1: Avoiding Repeated Subqueries
-- INEFFICIENT: Multiple identical subqueries
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) THEN 'Yes' ELSE 'No' END AS Has_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) THEN 'Active' ELSE 'Inactive' END AS Status
FROM Customers c;

-- BETTER: Use CTE or derived table
WITH CustomerOrders AS (
    SELECT DISTINCT CustomerID
    FROM Orders
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE WHEN co.CustomerID IS NOT NULL THEN 'Yes' ELSE 'No' END AS Has_Orders,
    CASE WHEN co.CustomerID IS NOT NULL THEN 'Active' ELSE 'Inactive' END AS Status
FROM Customers c
LEFT JOIN CustomerOrders co ON c.CustomerID = co.CustomerID;

-- Example 5.2: EXISTS vs IN for Existence Checks
-- EXISTS (preferred for existence)
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) 
            THEN 'Has Orders'
        ELSE 'No Orders'
    END AS Status
FROM Customers c;

-- IN (less efficient for simple existence)
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN c.CustomerID IN (SELECT CustomerID FROM Orders) 
            THEN 'Has Orders'
        ELSE 'No Orders'
    END AS Status
FROM Customers c;

/*
EXISTS vs IN:
• EXISTS: stops at first match, better for existence
• IN: builds list of all values, better for small static lists
• For correlated subqueries, EXISTS is almost always faster
*/

-- Example 5.3: Proper Indexing for EXISTS
-- Ensure foreign key columns are indexed
-- Good: Orders table has index on CustomerID
-- Good: OrderDetails has index on ProductID

-- Check execution plan for these queries
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID) 
        THEN 'Active' ELSE 'Inactive' END AS Status
FROM Customers c;

/*
Performance Tips:
1. Use SELECT 1 or SELECT * in EXISTS (doesn't matter)
2. Ensure correlated columns are indexed
3. EXISTS short-circuits (stops at first match)
4. Avoid SELECT COUNT(*) > 0, use EXISTS instead
5. Consider materialized views for complex existence checks
*/


/*
============================================================================
PART 6: Complex Existence Patterns
============================================================================
*/

-- Example 6.1: Existence with Aggregation
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            GROUP BY o.CustomerID 
            HAVING COUNT(*) >= 5
        ) THEN 'Frequent Buyer (5+ orders)'
        
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            GROUP BY o.CustomerID 
            HAVING SUM(o.TotalAmount) >= 2000
        ) THEN 'High Value (>$2000 total)'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID
        ) THEN 'Regular Customer'
        
        ELSE 'New Customer'
    END AS Customer_Type
FROM Customers c
ORDER BY Customer_Type;

-- Example 6.2: Existence Across Multiple Tables
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o 
            INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
            INNER JOIN Products p ON od.ProductID = p.ProductID
            WHERE o.CustomerID = c.CustomerID 
            AND p.CategoryID = 1
        ) THEN 'Purchased Category 1'
        ELSE 'Never Purchased Category 1'
    END AS Category1_Status,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o 
            INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
            INNER JOIN Products p ON od.ProductID = p.ProductID
            WHERE o.CustomerID = c.CustomerID 
            AND p.CategoryID = 2
        ) THEN 'Purchased Category 2'
        ELSE 'Never Purchased Category 2'
    END AS Category2_Status
FROM Customers c
WHERE c.CustomerID <= 10
ORDER BY c.CustomerID;

-- Example 6.3: Temporal Existence Patterns
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) AND EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate BETWEEN DATEADD(DAY, -60, GETDATE()) AND DATEADD(DAY, -30, GETDATE())
        ) THEN 'Consistently Active'
        
        WHEN EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
        ) AND NOT EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate BETWEEN DATEADD(DAY, -60, GETDATE()) AND DATEADD(DAY, -30, GETDATE())
        ) THEN 'Recently Reactivated'
        
        WHEN NOT EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID 
            AND o.OrderDate >= DATEADD(DAY, -90, GETDATE())
        ) AND EXISTS (
            SELECT 1 FROM Orders o 
            WHERE o.CustomerID = c.CustomerID
        ) THEN 'Churned - Win Back'
        
        ELSE 'Other'
    END AS Activity_Pattern
FROM Customers c
ORDER BY Activity_Pattern;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create flags for customers who ordered in each quarter of the year
2. Build product recommendations based on what customers haven't purchased
3. Identify orders that contain products from multiple categories
4. Find customers who purchased high-value items but not recently
5. Create a dashboard with multiple existence-based KPIs

Solutions below ↓
*/

-- Solution 1: Quarterly Order Flags
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND DATEPART(QUARTER, o.OrderDate) = 1) 
        THEN 1 ELSE 0 END AS Q1_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND DATEPART(QUARTER, o.OrderDate) = 2) 
        THEN 1 ELSE 0 END AS Q2_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND DATEPART(QUARTER, o.OrderDate) = 3) 
        THEN 1 ELSE 0 END AS Q3_Orders,
    CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND DATEPART(QUARTER, o.OrderDate) = 4) 
        THEN 1 ELSE 0 END AS Q4_Orders
FROM Customers c
WHERE c.CustomerID <= 10
ORDER BY c.CustomerID;

-- Solution 2: Product Recommendations
SELECT 
    c.CustomerID,
    c.CustomerName,
    p.ProductID,
    p.ProductName,
    'Recommended - You haven''t tried this yet!' AS Recommendation
FROM Customers c
CROSS JOIN Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID 
    AND od.ProductID = p.ProductID
)
AND EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
)
AND c.CustomerID <= 5
AND p.ProductID <= 10
ORDER BY c.CustomerID, p.ProductID;

-- Solution 3: Multi-Category Orders
SELECT 
    o.OrderID,
    o.CustomerID,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM OrderDetails od 
            INNER JOIN Products p ON od.ProductID = p.ProductID
            WHERE od.OrderID = o.OrderID 
            GROUP BY od.OrderID 
            HAVING COUNT(DISTINCT p.CategoryID) > 1
        ) THEN 'Multi-Category Order'
        ELSE 'Single Category'
    END AS Order_Type
FROM Orders o
WHERE o.OrderID <= 20
ORDER BY o.OrderID;

-- Solution 4: (see lesson content)
-- Solution 5: (see lesson content)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CASE WITH EXISTS:
  • Perfect for creating conditional flags
  • EXISTS returns TRUE/FALSE for CASE evaluation
  • Short-circuit evaluation (stops at first match)
  • More efficient than COUNT(*) > 0

✓ NOT EXISTS:
  • Check for absence of data
  • Find gaps in relationships
  • Identify incomplete records
  • Marketing opportunities (never purchased, inactive, etc.)

✓ MULTIPLE EXISTS:
  • Combine with AND/OR for complex logic
  • Create sophisticated segmentation
  • Build multi-dimensional classifications
  • Order conditions by specificity

✓ PERFORMANCE:
  • EXISTS is faster than IN for correlated subqueries
  • Use SELECT 1 (convention, not requirement)
  • Ensure foreign keys are indexed
  • Avoid repeated identical subqueries (use CTEs)
  • EXISTS stops at first match (efficient)

✓ COMMON PATTERNS:
  • Activity flags: Has_Orders, Is_Active
  • Status indicators: Never Purchased, Churned, VIP
  • Recommendations: Products not yet purchased
  • Temporal patterns: Recent activity, consistency
  • Multi-table existence: Category purchases, related data

✓ BEST PRACTICES:
  • Use EXISTS for simple existence checks
  • Use CTEs to avoid repeated subqueries
  • Order CASE conditions by likelihood
  • Document complex existence logic
  • Test edge cases (no data, NULL values)
  • Consider materialized views for complex checks

✓ ALTERNATIVES:
  • LEFT JOIN with IS NULL (for NOT EXISTS)
  • CTEs with binary flags
  • Window functions with COUNT OVER
  • Choose based on readability and performance

============================================================================
NEXT: Lesson 11.08 - Division by Zero Errors
Learn to prevent arithmetic errors using CASE expressions.
============================================================================
*/
