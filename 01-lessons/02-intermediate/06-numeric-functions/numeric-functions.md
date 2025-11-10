# Lesson 6: Numeric Functions

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this short lesson you'll be able to:
1. Use common numeric functions: ROUND, CEILING, FLOOR, ABS, POWER
2. Perform safe arithmetic in SELECT and WHERE
3. Understand numeric rounding behaviors

---

## Common Numeric Functions

```sql
SELECT 
    Price,
    ROUND(Price, 2) AS RoundedPrice,
    CEILING(Price) AS CeilingPrice,
    FLOOR(Price) AS FloorPrice,
    ABS(Price) AS AbsolutePrice,
    POWER(Price, 2) AS PriceSquared
FROM Products;
```

### Rounding

- ROUND(value, decimals) → Standard rounding
- CEILING → Smallest integer >= value
- FLOOR → Largest integer <= value

### Absolute and Power

- ABS → Absolute value
- POWER(x,y) → x raised to y

---

## Practical Examples

```sql
-- Calculate discounted price and round to 2 decimals
SELECT Price, ROUND(Price * 0.9, 2) AS Discounted
FROM Products;

-- Find products with price squared > 10000
SELECT ProductID, Price
FROM Products
WHERE POWER(Price, 2) > 10000;
```

---

## Performance Tips

- Avoid unnecessary casts between numeric types
- Use appropriate numeric types (DECIMAL for money)

---

## Next Lesson

Continue to [Lesson 7: Date & Time Functions](../07-date-time-functions/07-date-time-functions.md).
