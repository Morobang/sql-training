/*
============================================================================
Lesson 07.01 - String Generation
============================================================================

Description:
Learn how to create and generate string data in SQL Server using built-in
functions. Strings are fundamental - you'll use them for names, emails,
addresses, messages, and much more.

Topics Covered:
• String concatenation with + operator
• CONCAT function
• REPLICATE function
• SPACE function
• CHAR function
• String literals and quotes

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
PART 1: String Concatenation with + Operator
============================================================================
The + operator joins strings together.
*/

-- Example 1.1: Basic concatenation
SELECT 'Hello' + ' ' + 'World' AS Greeting;
-- Result: Hello World

-- Example 1.2: Concatenate customer names
SELECT 
    FirstName,
    LastName,
    FirstName + ' ' + LastName AS FullName
FROM Customers;

-- Example 1.3: Build email-style usernames
SELECT 
    FirstName,
    LastName,
    FirstName + '.' + LastName + '@company.com' AS EmailSuggestion
FROM Customers;

-- Example 1.4: Add prefixes and suffixes
SELECT 
    ProductName,
    '[PRODUCT] ' + ProductName + ' - Available Now!' AS MarketingText
FROM Products;

/*
⚠️ WARNING: NULL Concatenation Issue!
If ANY value is NULL, the entire result becomes NULL!
*/

-- Example 1.5: NULL kills concatenation
SELECT 
    'Hello' + NULL + 'World' AS Result;
-- Result: NULL (not 'HelloWorld'!)

-- Solution: Use ISNULL or COALESCE
SELECT 
    'Hello' + ISNULL(NULL, '') + 'World' AS Result;
-- Result: HelloWorld ✓


/*
============================================================================
PART 2: CONCAT Function
============================================================================
CONCAT automatically converts NULLs to empty strings and handles type conversion.
Introduced in SQL Server 2012 - preferred for modern code.

Syntax: CONCAT(string1, string2, string3, ...)
*/

-- Example 2.1: CONCAT handles NULLs gracefully
SELECT CONCAT('Hello', NULL, 'World') AS Result;
-- Result: HelloWorld (NULL ignored!)

-- Example 2.2: Build full addresses
SELECT 
    FirstName,
    LastName,
    City,
    State,
    CONCAT(FirstName, ' ', LastName, ', ', City, ', ', State) AS FullAddress
FROM Customers;

-- Example 2.3: CONCAT with numbers (auto-converts)
SELECT 
    ProductName,
    Stock,
    CONCAT('Product: ', ProductName, ' - Stock: ', Stock, ' units') AS Inventory
FROM Products;

-- Example 2.4: Build formatted product codes
SELECT 
    ProductID,
    CategoryID,
    CONCAT('PRD-', CategoryID, '-', ProductID) AS ProductCode
FROM Products;


/*
============================================================================
PART 3: REPLICATE Function
============================================================================
Creates a string by repeating a character or string n times.

Syntax: REPLICATE(string_expression, integer_expression)

Use cases:
• Creating visual separators
• Masking sensitive data
• Generating test data
• Formatting output
*/

-- Example 3.1: Create separator lines
SELECT REPLICATE('=', 50) AS Separator;
-- Result: ==================================================

-- Example 3.2: Mask credit card numbers
SELECT 
    'Card ending in: ' + REPLICATE('*', 12) + '1234' AS MaskedCard;
-- Result: Card ending in: ************1234

-- Example 3.3: Create visual rating stars
SELECT 
    ProductName,
    5 AS MaxRating,
    REPLICATE('★', 5) AS RatingStars
FROM Products;

-- Example 3.4: Pad order numbers with zeros
SELECT 
    OrderID,
    CONCAT('ORD-', REPLICATE('0', 6 - LEN(CAST(OrderID AS VARCHAR))), OrderID) AS PaddedOrderID
FROM Orders;
-- Example: OrderID 5 becomes ORD-000005


/*
============================================================================
PART 4: SPACE Function
============================================================================
Generates a string of spaces. Useful for formatting and alignment.

Syntax: SPACE(integer_expression)
*/

-- Example 4.1: Basic spacing
SELECT 'Hello' + SPACE(5) + 'World' AS Spaced;
-- Result: 'Hello     World'

-- Example 4.2: Create indented categories (visual hierarchy)
SELECT 
    CategoryID,
    SPACE(CategoryID * 2) + CategoryName AS IndentedName
FROM Categories
ORDER BY CategoryID;
-- Indents based on category level

-- Example 4.3: Align text in reports
SELECT 
    ProductName + SPACE(30 - LEN(ProductName)) + '$' + CAST(Price AS VARCHAR) AS AlignedPrice
FROM Products
WHERE Price < 100;

-- Example 4.4: Format customer list with spacing
SELECT 
    FirstName + SPACE(15 - LEN(FirstName)) + LastName AS FormattedName
FROM Customers;


/*
============================================================================
PART 5: CHAR Function
============================================================================
Returns a character from an ASCII code.

Syntax: CHAR(integer_expression)

Common ASCII codes:
  32  = Space
  10  = Line feed (newline)
  13  = Carriage return
  9   = Tab
  65-90 = A-Z
  97-122 = a-z
*/

-- Example 5.1: Generate specific characters
SELECT CHAR(65) AS LetterA;        -- Result: A
SELECT CHAR(90) AS LetterZ;        -- Result: Z
SELECT CHAR(49) AS Number1;        -- Result: 1

-- Example 5.2: Add line breaks (use CHAR(13) + CHAR(10) for Windows)
SELECT 
    'Line 1' + CHAR(13) + CHAR(10) + 'Line 2' AS MultiLine;

-- Example 5.3: Add tab characters
SELECT 
    ProductName + CHAR(9) + CAST(Price AS VARCHAR) AS TabbedOutput
FROM Products;

-- Example 5.4: Build formatted address with newlines
SELECT 
    CONCAT(
        FirstName, ' ', LastName, CHAR(13), CHAR(10),
        City, ', ', State, CHAR(13), CHAR(10)
    ) AS FormattedAddress
FROM Customers
WHERE CustomerID = 1;


/*
============================================================================
PART 6: Combining String Functions
============================================================================
Real-world scenarios often require multiple functions together.
*/

-- Example 6.1: Create professional product labels
SELECT 
    ProductName,
    CONCAT(
        REPLICATE('=', 50), CHAR(13), CHAR(10),
        'PRODUCT: ', UPPER(ProductName), CHAR(13), CHAR(10),
        'PRICE: $', Price, CHAR(13), CHAR(10),
        'IN STOCK: ', Stock, ' units', CHAR(13), CHAR(10),
        REPLICATE('=', 50)
    ) AS ProductLabel
FROM Products
WHERE ProductID <= 3;

-- Example 6.2: Generate SKU codes with pattern
SELECT 
    ProductID,
    CategoryID,
    CONCAT(
        'SKU-',
        REPLICATE('0', 3 - LEN(CAST(CategoryID AS VARCHAR))), 
        CategoryID,
        '-',
        REPLICATE('0', 5 - LEN(CAST(ProductID AS VARCHAR))), 
        ProductID
    ) AS SKU
FROM Products;
-- Example: Category 1, Product 5 → SKU-001-00005

-- Example 6.3: Create formatted customer directory
SELECT 
    CONCAT(
        UPPER(LastName), ', ', FirstName,
        SPACE(30 - LEN(LastName + ', ' + FirstName)),
        '|', SPACE(2),
        ISNULL(Email, 'No email on file'),
        SPACE(2), '|', SPACE(2),
        City
    ) AS DirectoryEntry
FROM Customers
ORDER BY LastName;

-- Example 6.4: Build test data patterns
SELECT 
    CONCAT('User', REPLICATE('0', 4 - LEN(CAST(CustomerID AS VARCHAR))), CustomerID) AS Username,
    CONCAT('user', CustomerID, '@test.com') AS TestEmail,
    CONCAT('Test', SPACE(1), 'User', SPACE(1), CustomerID) AS FullName
FROM Customers
WHERE CustomerID <= 10;


/*
============================================================================
PART 7: Practical Applications
============================================================================
*/

-- Application 7.1: Email template generation
SELECT 
    CustomerID,
    CONCAT(
        'Dear ', FirstName, ',', CHAR(13), CHAR(10),
        CHAR(13), CHAR(10),
        'Thank you for your recent order!', CHAR(13), CHAR(10),
        CHAR(13), CHAR(10),
        'We hope you enjoy your purchase.', CHAR(13), CHAR(10),
        CHAR(13), CHAR(10),
        'Best regards,', CHAR(13), CHAR(10),
        'The RetailStore Team'
    ) AS EmailTemplate
FROM Customers
WHERE CustomerID IN (1, 2, 3);

-- Application 7.2: Product barcode generation (fake example)
SELECT 
    ProductID,
    ProductName,
    CONCAT(
        REPLICATE('|', 1), SPACE(1),
        REPLICATE('|', 2), SPACE(1),
        REPLICATE('|', 1), SPACE(1),
        CAST(ProductID AS VARCHAR),
        SPACE(1),
        REPLICATE('|', 2)
    ) AS Barcode
FROM Products;

-- Application 7.3: Create invoice line items
SELECT 
    o.OrderID,
    CONCAT(
        SPACE(2), od.Quantity, 'x ', p.ProductName,
        SPACE(40 - LEN(CAST(od.Quantity AS VARCHAR) + 'x ' + p.ProductName)),
        '$', od.UnitPrice
    ) AS LineItem
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderID = 1;

-- Application 7.4: Format phone numbers (assuming 10-digit format)
-- Note: This is a simplified example
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Phone,
    CONCAT(
        '(', SUBSTRING(Phone, 1, 3), ') ',
        SUBSTRING(Phone, 4, 3), '-',
        SUBSTRING(Phone, 7, 4)
    ) AS FormattedPhone
FROM Customers
WHERE Phone IS NOT NULL AND LEN(Phone) = 10;


/*
============================================================================
PART 8: Best Practices
============================================================================
*/

-- Best Practice 8.1: Use CONCAT instead of + for NULL safety
-- ❌ BAD (breaks with NULL):
SELECT FirstName + ' ' + MiddleName + ' ' + LastName FROM Customers;

-- ✅ GOOD (handles NULL):
SELECT CONCAT(FirstName, ' ', MiddleName, ' ', LastName) FROM Customers;


-- Best Practice 8.2: Avoid excessive concatenation in WHERE clause (performance)
-- ❌ SLOW (can't use index):
SELECT * FROM Customers
WHERE FirstName + ' ' + LastName = 'John Smith';

-- ✅ FASTER (can use indexes):
SELECT * FROM Customers
WHERE FirstName = 'John' AND LastName = 'Smith';


-- Best Practice 8.3: Use meaningful variable names for complex strings
DECLARE @Separator VARCHAR(50) = REPLICATE('-', 50);
DECLARE @NewLine VARCHAR(2) = CHAR(13) + CHAR(10);

SELECT 
    CONCAT(
        @Separator, @NewLine,
        'Customer: ', FirstName, ' ', LastName, @NewLine,
        @Separator
    ) AS FormattedCustomer
FROM Customers
WHERE CustomerID = 1;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions below:

1. Create a full name in format: "LASTNAME, Firstname"
2. Generate employee ID codes: "EMP-00001", "EMP-00002", etc.
3. Build a product tag: "*** PRODUCT NAME *** - $PRICE"
4. Create a simple ASCII box around customer names
5. Format order summary with proper spacing

Solutions below ↓
*/

-- Solution 1: Full name format
SELECT 
    CONCAT(UPPER(LastName), ', ', FirstName) AS FormattedName
FROM Customers;

-- Solution 2: Employee ID codes
SELECT 
    EmployeeID,
    CONCAT('EMP-', REPLICATE('0', 5 - LEN(CAST(EmployeeID AS VARCHAR))), EmployeeID) AS EmployeeCode
FROM Employees;

-- Solution 3: Product tag
SELECT 
    CONCAT('*** ', UPPER(ProductName), ' *** - $', Price) AS ProductTag
FROM Products;

-- Solution 4: ASCII box around names
SELECT 
    CONCAT(
        '+', REPLICATE('-', 30), '+', CHAR(13), CHAR(10),
        '| ', FirstName, ' ', LastName, 
        SPACE(28 - LEN(FirstName + ' ' + LastName)), '|', CHAR(13), CHAR(10),
        '+', REPLICATE('-', 30), '+'
    ) AS BoxedName
FROM Customers
WHERE CustomerID = 1;

-- Solution 5: Order summary with spacing
SELECT 
    OrderID,
    CONCAT(
        'Order #', OrderID,
        SPACE(10),
        'Total: $', TotalAmount,
        SPACE(10),
        'Date: ', CAST(OrderDate AS VARCHAR)
    ) AS OrderSummary
FROM Orders
WHERE OrderID <= 5;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ STRING CONCATENATION:
  • + operator: Fast but breaks with NULL
  • CONCAT(): Handles NULL, converts types automatically
  • Always consider NULL values

✓ STRING GENERATION:
  • REPLICATE(): Repeat characters/strings
  • SPACE(): Generate spaces
  • CHAR(): Insert special characters (tabs, newlines)

✓ BEST PRACTICES:
  • Prefer CONCAT over + for reliability
  • Avoid functions in WHERE on indexed columns
  • Use variables for complex repeated patterns
  • Test with NULL values

✓ COMMON USES:
  • Formatting names and addresses
  • Creating codes and IDs
  • Building email templates
  • Generating reports
  • Masking sensitive data

============================================================================
NEXT: Lesson 07.02 - String Manipulation
Learn to transform, extract, and modify existing strings.
============================================================================
*/
