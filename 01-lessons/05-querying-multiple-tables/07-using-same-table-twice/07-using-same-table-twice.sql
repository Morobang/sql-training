/*============================================
   LESSON 07: USING THE SAME TABLE TWICE
   Multiple references with table aliases
   
   Estimated Time: 15 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHY USE THE SAME TABLE TWICE?
   Common scenarios
--------------------------------------------*/

/*
   Reasons to reference the same table multiple times:
   
   1. Compare rows within the same table
   2. Self-joins (covered in Lesson 08)
   3. Multiple foreign keys to the same table
   4. Complex business logic
   5. Hierarchical relationships
*/

/*--------------------------------------------
   PART 2: THE PROBLEM WITHOUT ALIASES
   Can't distinguish between references
--------------------------------------------*/

-- ❌ This doesn't work:
-- SELECT Products.ProductName, Products.Price
-- FROM Products, Products
-- WHERE Products.ProductID = 1 AND Products.ProductID = 2;

-- Which "Products" are we talking about?
-- SQL Server doesn't know!

/*--------------------------------------------
   PART 3: SOLUTION: TABLE ALIASES
   Give each reference a unique name
--------------------------------------------*/

-- Compare two specific products
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    p2.Price - p1.Price AS PriceDifference
FROM Inventory.Products p1, Inventory.Products p2
WHERE p1.ProductID = 1 
  AND p2.ProductID = 2;

-- p1 and p2 are DIFFERENT aliases for the SAME table

/*--------------------------------------------
   PART 4: COMPARING PRODUCTS
   Find products cheaper than another product
--------------------------------------------*/

-- Find all products cheaper than product ID 1
SELECT 
    reference.ProductName AS ReferenceProduct,
    reference.Price AS ReferencePrice,
    cheaper.ProductName AS CheaperProduct,
    cheaper.Price AS CheaperPrice
FROM Inventory.Products reference
CROSS JOIN Inventory.Products cheaper
WHERE reference.ProductID = 1
  AND cheaper.Price < reference.Price
ORDER BY cheaper.Price DESC;

/*--------------------------------------------
   PART 5: PRICE COMPARISON MATRIX
   Compare all products to each other
--------------------------------------------*/

-- Create a price comparison (limited for readability)
SELECT TOP 20
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    CASE 
        WHEN p1.Price > p2.Price THEN 'Product1 More Expensive'
        WHEN p1.Price < p2.Price THEN 'Product2 More Expensive'
        ELSE 'Same Price'
    END AS Comparison
FROM Inventory.Products p1
CROSS JOIN Inventory.Products p2
WHERE p1.ProductID <> p2.ProductID  -- Don't compare product to itself
  AND p1.ProductID <= 5             -- Limit to first 5 products
  AND p2.ProductID <= 5;

/*--------------------------------------------
   PART 6: FINDING PRODUCT PAIRS
   Products in same category
--------------------------------------------*/

-- Find pairs of products in the same category
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    c.CategoryName,
    ABS(p1.Price - p2.Price) AS PriceDifference
FROM Inventory.Products p1
INNER JOIN Inventory.Products p2 ON p1.CategoryID = p2.CategoryID
INNER JOIN Inventory.Categories c ON p1.CategoryID = c.CategoryID
WHERE p1.ProductID < p2.ProductID  -- Avoid duplicates (A,B) and (B,A)
  AND ABS(p1.Price - p2.Price) < 50  -- Similar prices
ORDER BY c.CategoryName, PriceDifference;

/*--------------------------------------------
   PART 7: MULTIPLE FOREIGN KEYS TO SAME TABLE
   Real-world scenario
--------------------------------------------*/

-- If we had a ShipmentTracking table with both OriginCity and DestinationCity
-- referencing the same Cities table:

/*
CREATE TABLE Locations (
    LocationID INT PRIMARY KEY,
    CityName VARCHAR(100)
);

CREATE TABLE Shipments (
    ShipmentID INT PRIMARY KEY,
    OriginLocationID INT,
    DestinationLocationID INT
);

-- Query with same table twice:
SELECT 
    s.ShipmentID,
    origin.CityName AS OriginCity,
    destination.CityName AS DestinationCity
FROM Shipments s
INNER JOIN Locations origin ON s.OriginLocationID = origin.LocationID
INNER JOIN Locations destination ON s.DestinationLocationID = destination.LocationID;
*/

/*--------------------------------------------
   PART 8: COMPARING ORDER DETAILS
   Products bought together
--------------------------------------------*/

-- Find products frequently purchased together
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    COUNT(DISTINCT od1.OrderID) AS TimesPurchasedTogether
FROM Sales.OrderDetails od1
INNER JOIN Sales.OrderDetails od2 ON od1.OrderID = od2.OrderID
INNER JOIN Inventory.Products p1 ON od1.ProductID = p1.ProductID
INNER JOIN Inventory.Products p2 ON od2.ProductID = p2.ProductID
WHERE od1.ProductID < od2.ProductID  -- Avoid duplicates
GROUP BY p1.ProductID, p1.ProductName, p2.ProductID, p2.ProductName
HAVING COUNT(DISTINCT od1.OrderID) >= 2
ORDER BY TimesPurchasedTogether DESC;

/*--------------------------------------------
   PART 9: CUSTOMER COMPARISON
   Find customers in same city
--------------------------------------------*/

-- Find pairs of customers in the same city
SELECT 
    c1.FirstName + ' ' + c1.LastName AS Customer1,
    c2.FirstName + ' ' + c2.LastName AS Customer2,
    c1.City
FROM Sales.Customers c1
INNER JOIN Sales.Customers c2 ON c1.City = c2.City
WHERE c1.CustomerID < c2.CustomerID  -- Avoid duplicates and self-comparison
ORDER BY c1.City, c1.LastName;

/*--------------------------------------------
   PART 10: FINDING GAPS
   Products with no peers in price range
--------------------------------------------*/

-- Find products with no other products in similar price range (+/- $10)
SELECT 
    p1.ProductName,
    p1.Price,
    COUNT(p2.ProductID) AS SimilarPricedProducts
FROM Inventory.Products p1
LEFT JOIN Inventory.Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID <> p2.ProductID
    AND p2.Price BETWEEN p1.Price - 10 AND p1.Price + 10
GROUP BY p1.ProductID, p1.ProductName, p1.Price
HAVING COUNT(p2.ProductID) = 0
ORDER BY p1.Price;

/*--------------------------------------------
   PART 11: ADVANCED: THREE REFERENCES
   Same table used three times
--------------------------------------------*/

-- Compare three products at once (demo concept)
SELECT TOP 10
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    p3.ProductName AS Product3,
    p3.Price AS Price3
FROM Inventory.Products p1
CROSS JOIN Inventory.Products p2
CROSS JOIN Inventory.Products p3
WHERE p1.ProductID = 1
  AND p2.ProductID = 2
  AND p3.ProductID = 3;

/*--------------------------------------------
   PART 12: PRACTICAL EXAMPLE: SUBSTITUTES
   Find alternative products
--------------------------------------------*/

-- Find alternative products (same category, similar price)
SELECT 
    original.ProductName AS OriginalProduct,
    original.Price AS OriginalPrice,
    alternative.ProductName AS Alternative,
    alternative.Price AS AlternativePrice,
    ABS(original.Price - alternative.Price) AS PriceDiff,
    c.CategoryName
FROM Inventory.Products original
INNER JOIN Inventory.Products alternative 
    ON original.CategoryID = alternative.CategoryID
    AND original.ProductID <> alternative.ProductID
    AND alternative.Price BETWEEN original.Price * 0.8 AND original.Price * 1.2
INNER JOIN Inventory.Categories c ON original.CategoryID = c.CategoryID
WHERE original.ProductID = 1  -- Find alternatives for specific product
ORDER BY PriceDiff;

/*--------------------------------------------
   PART 13: BEST PRACTICES
--------------------------------------------*/

/*
   ✅ DO:
   • Use clear, meaningful alias names (p1, p2 OR original, alternative)
   • Avoid comparing a row to itself (p1.ID <> p2.ID)
   • Use p1.ID < p2.ID to avoid duplicate pairs
   • Comment which table reference serves what purpose
   • Test with LIMIT/TOP to avoid huge result sets
   
   ❌ DON'T:
   • Use confusing alias names (a, b, x, y)
   • Forget to exclude self-comparisons
   • Create unnecessary Cartesian products
   • Mix up which alias represents what
*/

/*--------------------------------------------
   PART 14: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. Find all products with a price difference less than $20

-- 2. List products that are more expensive than product ID 5

-- 3. Find customers who live in the same city

-- 4. Show products in the same category with different suppliers

-- 5. Create a price tier comparison (budget vs premium from same table)

/*============================================
   KEY CONCEPTS
============================================*/

/*
   Using Same Table Multiple Times:
   
   1. Each reference needs a unique alias
   2. Common pattern: Compare rows within same table
   3. Avoid self-comparisons (p1.ID <> p2.ID)
   4. Prevent duplicate pairs (p1.ID < p2.ID)
   5. Use meaningful alias names
   
   Syntax Pattern:
   SELECT ...
   FROM TableName alias1
   JOIN TableName alias2 ON condition
   WHERE alias1.ID <> alias2.ID
*/

/*============================================
   NEXT: Lesson 08 - Self Joins
   (Special case: joining table to itself)
============================================*/
