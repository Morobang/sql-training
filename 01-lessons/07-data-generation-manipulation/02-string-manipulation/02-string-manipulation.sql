/*
============================================================================
Lesson 07.02 - String Manipulation
============================================================================

Description:
Learn to transform, extract, search, and modify existing string data.
These functions are essential for data cleaning, formatting, and analysis.

Topics Covered:
• UPPER, LOWER, and case manipulation
• SUBSTRING and string extraction
• LEFT, RIGHT functions
• LEN and DATALENGTH
• TRIM, LTRIM, RTRIM
• REPLACE function
• CHARINDEX and PATINDEX
• REVERSE function
• String comparison techniques

Prerequisites:
• Lesson 07.01 - String Generation
• Basic SELECT statements

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Case Manipulation (UPPER, LOWER)
============================================================================
Change the case of strings for consistency and formatting.
*/

-- Example 1.1: Convert to uppercase
SELECT 
    ProductName,
    UPPER(ProductName) AS UpperCase
FROM Products;

-- Example 1.2: Convert to lowercase
SELECT 
    ProductName,
    LOWER(ProductName) AS LowerCase
FROM Products;

-- Example 1.3: Standardize email addresses (emails should be lowercase)
SELECT 
    CustomerID,
    Email,
    LOWER(Email) AS StandardizedEmail
FROM Customers
WHERE Email IS NOT NULL;

-- Example 1.4: Title case (first letter capitalized)
-- More complex - capitalize first letter of each word
SELECT 
    ProductName,
    UPPER(LEFT(ProductName, 1)) + LOWER(SUBSTRING(ProductName, 2, LEN(ProductName))) AS TitleCase
FROM Products;

-- Example 1.5: Create case-insensitive comparisons
SELECT 
    FirstName,
    LastName
FROM Customers
WHERE UPPER(FirstName) = 'JOHN';  -- Finds 'John', 'JOHN', 'john', etc.


/*
============================================================================
PART 2: SUBSTRING - Extract Parts of Strings
============================================================================
Extract a portion of a string starting at a position for a specified length.

Syntax: SUBSTRING(string, start_position, length)
Note: Position is 1-based (first character is position 1)
*/

-- Example 2.1: Extract first 3 characters
SELECT 
    ProductName,
    SUBSTRING(ProductName, 1, 3) AS First3Chars
FROM Products;

-- Example 2.2: Extract middle portion
SELECT 
    'Hello World' AS Original,
    SUBSTRING('Hello World', 7, 5) AS Extracted;
-- Result: 'World'

-- Example 2.3: Extract area code from phone numbers
SELECT 
    Phone,
    SUBSTRING(Phone, 1, 3) AS AreaCode
FROM Customers
WHERE Phone IS NOT NULL AND LEN(Phone) >= 10;

-- Example 2.4: Extract year from date string (if stored as string)
DECLARE @DateStr VARCHAR(10) = '2025-11-08';
SELECT 
    @DateStr AS OriginalDate,
    SUBSTRING(@DateStr, 1, 4) AS Year,
    SUBSTRING(@DateStr, 6, 2) AS Month,
    SUBSTRING(@DateStr, 9, 2) AS Day;

-- Example 2.5: Get file extension from filename
SELECT 
    'report.pdf' AS FileName,
    SUBSTRING('report.pdf', CHARINDEX('.', 'report.pdf') + 1, 10) AS Extension;
-- Result: 'pdf'


/*
============================================================================
PART 3: LEFT and RIGHT Functions
============================================================================
Convenient shortcuts for extracting from start or end of string.

Syntax: 
  LEFT(string, number_of_characters)
  RIGHT(string, number_of_characters)
*/

-- Example 3.1: Get first 5 characters
SELECT 
    ProductName,
    LEFT(ProductName, 5) AS First5
FROM Products;

-- Example 3.2: Get last 3 characters
SELECT 
    ProductName,
    RIGHT(ProductName, 3) AS Last3
FROM Products;

-- Example 3.3: Create initials from name
SELECT 
    FirstName,
    LastName,
    LEFT(FirstName, 1) + LEFT(LastName, 1) AS Initials
FROM Customers;

-- Example 3.4: Extract last 4 digits of phone
SELECT 
    Phone,
    RIGHT(Phone, 4) AS Last4Digits
FROM Customers
WHERE Phone IS NOT NULL;

-- Example 3.5: Mask credit card (show last 4 only)
DECLARE @CreditCard VARCHAR(16) = '1234567890123456';
SELECT 
    @CreditCard AS OriginalCard,
    REPLICATE('*', 12) + RIGHT(@CreditCard, 4) AS MaskedCard;
-- Result: ************3456


/*
============================================================================
PART 4: LEN and DATALENGTH
============================================================================
Measure string lengths.

LEN() - Returns number of characters (excludes trailing spaces)
DATALENGTH() - Returns number of bytes used
*/

-- Example 4.1: Get string length
SELECT 
    ProductName,
    LEN(ProductName) AS Length
FROM Products;

-- Example 4.2: Find products with long names
SELECT 
    ProductName,
    LEN(ProductName) AS NameLength
FROM Products
WHERE LEN(ProductName) > 20
ORDER BY LEN(ProductName) DESC;

-- Example 4.3: LEN vs DATALENGTH
SELECT 
    'Hello   ' AS TextWithSpaces,
    LEN('Hello   ') AS LenResult,           -- Result: 5 (ignores trailing spaces)
    DATALENGTH('Hello   ') AS DataLength;   -- Result: 8 (counts all)

-- Example 4.4: Validate input length
SELECT 
    CustomerID,
    Phone,
    LEN(Phone) AS PhoneLength,
    CASE 
        WHEN LEN(Phone) = 10 THEN 'Valid'
        WHEN Phone IS NULL THEN 'Missing'
        ELSE 'Invalid Length'
    END AS ValidationStatus
FROM Customers;

-- Example 4.5: Check for empty strings vs NULL
SELECT 
    'NULL' AS Type, NULL AS Value, LEN(NULL) AS Length
UNION ALL
SELECT 
    'Empty String', '', LEN('')
UNION ALL
SELECT 
    'Space', ' ', LEN(' ')
UNION ALL
SELECT 
    'Text', 'Hello', LEN('Hello');


/*
============================================================================
PART 5: TRIM, LTRIM, RTRIM - Remove Whitespace
============================================================================
Clean up extra spaces from strings.

LTRIM() - Remove leading (left) spaces
RTRIM() - Remove trailing (right) spaces
TRIM()  - Remove both (SQL Server 2017+)
*/

-- Example 5.1: Remove leading spaces
SELECT 
    '   Hello' AS Original,
    LTRIM('   Hello') AS LeftTrimmed;
-- Result: 'Hello'

-- Example 5.2: Remove trailing spaces
SELECT 
    'Hello   ' AS Original,
    RTRIM('Hello   ') AS RightTrimmed;
-- Result: 'Hello'

-- Example 5.3: Remove both (SQL Server 2017+)
SELECT 
    '   Hello   ' AS Original,
    TRIM('   Hello   ') AS BothTrimmed;
-- Result: 'Hello'

-- Example 5.4: For older SQL Server, combine LTRIM and RTRIM
SELECT 
    '   Hello   ' AS Original,
    LTRIM(RTRIM('   Hello   ')) AS BothTrimmed;
-- Result: 'Hello'

-- Example 5.5: Clean user input
SELECT 
    CustomerID,
    Email,
    LTRIM(RTRIM(Email)) AS CleanedEmail
FROM Customers
WHERE Email IS NOT NULL;

-- Example 5.6: Remove specific characters (SQL Server 2017+)
SELECT 
    TRIM('.' FROM '...Hello...') AS TrimmedDots;
-- Result: 'Hello'


/*
============================================================================
PART 6: REPLACE Function
============================================================================
Replace all occurrences of a substring with another substring.

Syntax: REPLACE(string, old_substring, new_substring)
Case-sensitive!
*/

-- Example 6.1: Basic replacement
SELECT 
    REPLACE('Hello World', 'World', 'SQL Server') AS Result;
-- Result: 'Hello SQL Server'

-- Example 6.2: Remove characters (replace with empty string)
SELECT 
    Phone,
    REPLACE(REPLACE(REPLACE(Phone, '-', ''), '(', ''), ')', '') AS CleanPhone
FROM Customers
WHERE Phone LIKE '%-%';

-- Example 6.3: Standardize product names
SELECT 
    ProductName,
    REPLACE(ProductName, '&', 'and') AS StandardizedName
FROM Products;

-- Example 6.4: Fix data entry errors
SELECT 
    Email,
    REPLACE(Email, '@@', '@') AS FixedEmail  -- Fix double @ signs
FROM Customers
WHERE Email LIKE '%@@%';

-- Example 6.5: Clean up extra spaces
SELECT 
    ProductName,
    REPLACE(REPLACE(REPLACE(ProductName, '  ', ' '), '  ', ' '), '  ', ' ') AS Cleaned
FROM Products;
-- Note: Run REPLACE multiple times to catch multiple spaces

-- Example 6.6: URL encoding simulation
SELECT 
    'Hello World! How are you?' AS Original,
    REPLACE(REPLACE('Hello World! How are you?', ' ', '%20'), '!', '%21') AS URLEncoded;
-- Result: 'Hello%20World%21%20How%20are%20you%3F'


/*
============================================================================
PART 7: CHARINDEX - Find Position of Substring
============================================================================
Returns the starting position of a substring within a string.

Syntax: CHARINDEX(substring, string, [start_position])
Returns 0 if not found (NOT -1 or NULL!)
*/

-- Example 7.1: Find position of substring
SELECT 
    CHARINDEX('World', 'Hello World') AS Position;
-- Result: 7

-- Example 7.2: Check if string contains substring
SELECT 
    ProductName,
    CASE 
        WHEN CHARINDEX('Pro', ProductName) > 0 THEN 'Contains Pro'
        ELSE 'Does not contain Pro'
    END AS ContainsPro
FROM Products;

-- Example 7.3: Extract domain from email
SELECT 
    Email,
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS Domain
FROM Customers
WHERE Email IS NOT NULL;

-- Example 7.4: Find first space in a string
SELECT 
    ProductName,
    CHARINDEX(' ', ProductName) AS FirstSpacePosition
FROM Products;

-- Example 7.5: Split first and last name (assuming space separator)
SELECT 
    FirstName + ' ' + LastName AS FullName,
    LEFT(FirstName + ' ' + LastName, CHARINDEX(' ', FirstName + ' ' + LastName) - 1) AS First,
    SUBSTRING(FirstName + ' ' + LastName, CHARINDEX(' ', FirstName + ' ' + LastName) + 1, 100) AS Last
FROM Customers
WHERE CustomerID = 1;

-- Example 7.6: Using start position parameter
SELECT 
    'abcabcabc' AS Original,
    CHARINDEX('abc', 'abcabcabc') AS FirstOccurrence,     -- Result: 1
    CHARINDEX('abc', 'abcabcabc', 2) AS SecondOccurrence, -- Result: 4
    CHARINDEX('abc', 'abcabcabc', 5) AS ThirdOccurrence;  -- Result: 7


/*
============================================================================
PART 8: REVERSE Function
============================================================================
Reverses a string.

Useful for:
• Finding last occurrence of a character
• Palindrome checking
• Special formatting
*/

-- Example 8.1: Basic reversal
SELECT 
    'Hello' AS Original,
    REVERSE('Hello') AS Reversed;
-- Result: 'olleH'

-- Example 8.2: Check for palindromes
SELECT 
    'racecar' AS Word,
    CASE 
        WHEN 'racecar' = REVERSE('racecar') THEN 'Palindrome'
        ELSE 'Not Palindrome'
    END AS Result;

-- Example 8.3: Find last occurrence of character (reverse, find, calculate)
DECLARE @FilePath VARCHAR(100) = 'C:\Users\Documents\file.txt';
SELECT 
    @FilePath AS FilePath,
    LEN(@FilePath) - CHARINDEX('\', REVERSE(@FilePath)) + 1 AS LastBackslashPosition,
    SUBSTRING(@FilePath, 
        LEN(@FilePath) - CHARINDEX('\', REVERSE(@FilePath)) + 2, 
        100) AS FileName;
-- Result: file.txt

-- Example 8.4: Reverse customer names (just for fun)
SELECT 
    FirstName,
    REVERSE(FirstName) AS ReversedFirst,
    LastName,
    REVERSE(LastName) AS ReversedLast
FROM Customers;


/*
============================================================================
PART 9: Combining Multiple Functions
============================================================================
Real-world scenarios often require multiple string functions together.
*/

-- Example 9.1: Clean and standardize email addresses
SELECT 
    Email,
    LOWER(LTRIM(RTRIM(Email))) AS CleanEmail
FROM Customers
WHERE Email IS NOT NULL;

-- Example 9.2: Extract and format phone area code
SELECT 
    Phone,
    '(' + SUBSTRING(Phone, 1, 3) + ') ' + 
    SUBSTRING(Phone, 4, 3) + '-' + 
    SUBSTRING(Phone, 7, 4) AS FormattedPhone
FROM Customers
WHERE Phone IS NOT NULL AND LEN(Phone) = 10;

-- Example 9.3: Create username from email (part before @)
SELECT 
    Email,
    LOWER(LEFT(Email, CHARINDEX('@', Email) - 1)) AS Username
FROM Customers
WHERE Email IS NOT NULL AND CHARINDEX('@', Email) > 0;

-- Example 9.4: Capitalize first letter of each word
SELECT 
    ProductName,
    UPPER(LEFT(ProductName, 1)) + 
    LOWER(SUBSTRING(ProductName, 2, 
        CASE WHEN CHARINDEX(' ', ProductName) > 0 
             THEN CHARINDEX(' ', ProductName) - 2 
             ELSE LEN(ProductName) END)) +
    CASE 
        WHEN CHARINDEX(' ', ProductName) > 0 THEN 
            ' ' + UPPER(SUBSTRING(ProductName, CHARINDEX(' ', ProductName) + 1, 1)) + 
            LOWER(SUBSTRING(ProductName, CHARINDEX(' ', ProductName) + 2, 100))
        ELSE ''
    END AS TitleCase
FROM Products;

-- Example 9.5: Mask email (show first 2 chars and domain)
SELECT 
    Email,
    LEFT(Email, 2) + 
    REPLICATE('*', CHARINDEX('@', Email) - 3) + 
    SUBSTRING(Email, CHARINDEX('@', Email), LEN(Email)) AS MaskedEmail
FROM Customers
WHERE Email IS NOT NULL AND CHARINDEX('@', Email) > 2;


/*
============================================================================
PART 10: Practical Applications
============================================================================
*/

-- Application 10.1: Data cleaning - Remove extra spaces and standardize
SELECT 
    ProductName,
    LTRIM(RTRIM(REPLACE(REPLACE(ProductName, '  ', ' '), '  ', ' '))) AS CleanedName
FROM Products;

-- Application 10.2: Validate email format (basic check)
SELECT 
    CustomerID,
    Email,
    CASE 
        WHEN Email IS NULL THEN 'Missing'
        WHEN CHARINDEX('@', Email) = 0 THEN 'Invalid - No @'
        WHEN CHARINDEX('.', Email) = 0 THEN 'Invalid - No domain'
        WHEN CHARINDEX('@', Email) = 1 THEN 'Invalid - Starts with @'
        WHEN CHARINDEX('@', Email) = LEN(Email) THEN 'Invalid - Ends with @'
        ELSE 'Valid Format'
    END AS EmailValidation
FROM Customers;

-- Application 10.3: Redact sensitive information
SELECT 
    CustomerID,
    LEFT(FirstName, 1) + REPLICATE('*', LEN(FirstName) - 1) AS RedactedFirst,
    LEFT(LastName, 1) + REPLICATE('*', LEN(LastName) - 1) AS RedactedLast,
    LEFT(Email, 2) + REPLICATE('*', CHARINDEX('@', Email) - 3) + 
        SUBSTRING(Email, CHARINDEX('@', Email), 100) AS RedactedEmail
FROM Customers
WHERE Email IS NOT NULL;

-- Application 10.4: Search products (case-insensitive)
DECLARE @SearchTerm VARCHAR(50) = 'laptop';

SELECT 
    ProductID,
    ProductName,
    Price
FROM Products
WHERE CHARINDEX(LOWER(@SearchTerm), LOWER(ProductName)) > 0;

-- Application 10.5: Generate display names with length limits
SELECT 
    ProductName,
    CASE 
        WHEN LEN(ProductName) <= 30 THEN ProductName
        ELSE LEFT(ProductName, 27) + '...'
    END AS DisplayName
FROM Products;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions below:

1. Convert all customer emails to lowercase
2. Extract the first word from product names
3. Find all products with names longer than 15 characters
4. Remove all dashes and spaces from phone numbers
5. Check if product names contain the word "Premium" (case-insensitive)

Solutions below ↓
*/

-- Solution 1: Lowercase emails
SELECT 
    CustomerID,
    LOWER(Email) AS LowercaseEmail
FROM Customers
WHERE Email IS NOT NULL;

-- Solution 2: Extract first word
SELECT 
    ProductName,
    CASE 
        WHEN CHARINDEX(' ', ProductName) > 0 
        THEN LEFT(ProductName, CHARINDEX(' ', ProductName) - 1)
        ELSE ProductName
    END AS FirstWord
FROM Products;

-- Solution 3: Long product names
SELECT 
    ProductID,
    ProductName,
    LEN(ProductName) AS NameLength
FROM Products
WHERE LEN(ProductName) > 15
ORDER BY LEN(ProductName) DESC;

-- Solution 4: Clean phone numbers
SELECT 
    CustomerID,
    Phone,
    REPLACE(REPLACE(Phone, '-', ''), ' ', '') AS CleanPhone
FROM Customers
WHERE Phone IS NOT NULL;

-- Solution 5: Search for "Premium"
SELECT 
    ProductID,
    ProductName,
    CASE 
        WHEN CHARINDEX('PREMIUM', UPPER(ProductName)) > 0 THEN 'Yes'
        ELSE 'No'
    END AS IsPremium
FROM Products;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CASE MANIPULATION:
  • UPPER() - Convert to uppercase
  • LOWER() - Convert to lowercase
  • Use for standardization and case-insensitive comparisons

✓ EXTRACTION:
  • SUBSTRING(string, start, length) - Extract portion
  • LEFT(string, n) - First n characters
  • RIGHT(string, n) - Last n characters
  • Position is 1-based!

✓ MEASUREMENT:
  • LEN() - Character count (ignores trailing spaces)
  • DATALENGTH() - Byte count

✓ CLEANING:
  • TRIM/LTRIM/RTRIM - Remove spaces
  • REPLACE(string, old, new) - Substitute text

✓ SEARCHING:
  • CHARINDEX(find, string) - Find position
  • Returns 0 if not found (not -1 or NULL!)
  • Use for validation and parsing

✓ BEST PRACTICES:
  • Clean input data (trim, lowercase)
  • Validate before processing
  • Handle NULL values
  • Consider performance with large datasets
  • Test edge cases (empty strings, special chars)

============================================================================
NEXT: Lesson 07.03 - Arithmetic Functions
Learn to perform calculations and work with numeric data.
============================================================================
*/
