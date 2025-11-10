# Lesson 5: String Functions

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you will be able to:
1. Use common string functions: UPPER, LOWER, TRIM, LEN, SUBSTRING, CONCAT, REPLACE
2. Normalize text for comparisons
3. Search and extract parts of strings
4. Perform safe concatenation and handle NULLs

---

## Part 1: Case Conversion

```sql
SELECT UPPER(FirstName) AS UpperName, LOWER(LastName) AS LowerLast
FROM Customers;
```

**Use case:** Case-insensitive search or display.

---

## Part 2: Trimming and Length

```sql
SELECT TRIM(FullName) AS Name, LEN(TRIM(FullName)) AS NameLen
FROM Customers;
```

---

## Part 3: SUBSTRING and LEFT/RIGHT

```sql
-- Get first 3 characters
SELECT SUBSTRING(ProductCode, 1, 3) AS Prefix FROM Products;

-- Left/Right (some DBs)
SELECT LEFT(ProductCode, 3) AS Prefix, RIGHT(ProductCode, 4) AS Suffix FROM Products;
```

---

## Part 4: CONCAT and Handling NULL

```sql
-- Safe concatenation (NULL-safe)
SELECT CONCAT(FirstName, ' ', LastName) AS FullName FROM Customers;

-- Using + (SQL Server) is NULL-sensitive
SELECT FirstName + ' ' + LastName AS FullName FROM Customers; -- NULL in either makes whole NULL
```

---

## Part 5: REPLACE and CHARINDEX

```sql
-- Replace dashes in phone numbers
SELECT REPLACE(Phone, '-', '') AS PhoneNormalized FROM Customers;

-- Find position
SELECT CHARINDEX('@', Email) AS AtPos FROM Customers;
```

---

## Part 6: Pattern Extraction Examples

```sql
-- Extract domain from email (SQL Server example)
SELECT SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS Domain
FROM Customers
WHERE Email LIKE '%@%';
```

---

## Part 7: Performance Tips

- Avoid functions on columns in WHERE if you want to use indexes (use computed columns/indexes instead)
- Use COLLATE when needing case-sensitive matching

---

## Practice Exercises

1. Normalize email addresses to lowercase and trim whitespace.
2. Extract area code from phone numbers formatted like '(416) 555-1234'.
3. Concatenate address fields into a single mailing_address column handling NULL parts.

---

## Key Takeaways

- Use CONCAT for NULL-safe concatenation
- TRIM and REPLACE help normalize data
- SUBSTRING + CHARINDEX extract parts of strings
- Avoid functions on filter columns when possible

---

## Next Lesson

Continue to [Lesson 6: Numeric Functions](../06-numeric-functions/06-numeric-functions.md).
