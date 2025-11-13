# Lesson 4: Set Operators

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Combine query results with UNION and UNION ALL
2. Find intersections with INTERSECT and differences with EXCEPT
3. Understand column and data-type rules for set operators
4. Use ordering and pagination with set results
5. Handle duplicates and performance considerations

---

## Part 1: UNION vs UNION ALL

### UNION (distinct)

```sql
SELECT ProductName FROM Products WHERE Price < 10
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2;
```

- Removes duplicates
- Columns must match in count and compatible types

### UNION ALL (keep duplicates)

```sql
SELECT ProductName FROM Products WHERE Price < 10
UNION ALL
SELECT ProductName FROM Products WHERE CategoryID = 2;
```

- Faster than UNION (no dedupe step)
- Useful when duplicates are meaningful or already unique

---

## Part 2: INTERSECT

### Purpose

Return rows common to both queries.

```sql
-- Products that are cheap AND recently restocked (if both queries return same columns)
SELECT ProductID FROM Products WHERE Price < 20
INTERSECT
SELECT ProductID FROM Products WHERE LastRestockDate >= DATEADD(MONTH, -1, GETDATE());
```

**Behavior:** Duplicates removed (acts like set intersection)

---

## Part 3: EXCEPT (or MINUS in some DBs)

### Purpose

Return rows present in first query but not in second.

```sql
-- Products available in catalog but never ordered
SELECT ProductID FROM Products
EXCEPT
SELECT DISTINCT ProductID FROM OrderDetails;
```

**Note:** Oracle uses MINUS instead of EXCEPT.

---

## Part 4: Rules and Gotchas

- Column count and data types must match across the queries
- ORDER BY applies to the final result (only allowed at the end)
- Use parentheses to control precedence when combining multiple set operators
- Use UNION ALL where appropriate for performance
- NULLs are treated as equal for deduplication purposes

```sql
-- Correct: ORDER BY final result
SELECT Name FROM A
UNION
SELECT Name FROM B
ORDER BY Name;

-- Incorrect: ORDER BY inside a branch
(SELECT Name FROM A ORDER BY Name)  -- Error
UNION
(SELECT Name FROM B);
```

---

## Part 5: Practical Examples

### Example 1: Consolidate Emails from Multiple Sources

```sql
SELECT Email FROM Customers WHERE Email IS NOT NULL
UNION
SELECT Email FROM Subscribers WHERE Email IS NOT NULL
ORDER BY Email;
```

### Example 2: Find Overlap Between Two Campaign Lists

```sql
SELECT Email FROM CampaignA
INTERSECT
SELECT Email FROM CampaignB;
```

### Example 3: Items in Catalog but Never Sold

```sql
SELECT ProductID, ProductName FROM Products
EXCEPT
SELECT DISTINCT p.ProductID, p.ProductName
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;
```

---

## Part 6: Performance Tips

- Use UNION ALL where duplicates aren't an issue
- Avoid unnecessary sorting before union
- Use indexes on columns used in subqueries
- Break complex unions into CTEs for readability

---

## Practice Exercises

1. Combine two customer lists with UNION and remove duplicates.
2. List products that appear in both "Summer" and "Holiday" collections using INTERSECT.
3. Show emails in master list but NOT in blacklist using EXCEPT.

---

## Key Takeaways

- UNION removes duplicates; UNION ALL keeps them
- INTERSECT returns common rows
- EXCEPT returns differences (A \ B)
- Columns/types must match
- ORDER BY at the end only

---

## Next Lesson

Continue to [Lesson 5: String Functions](../05-string-functions/string-functions.md).
