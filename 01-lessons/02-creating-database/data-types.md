# SQL Data Types Guide

This guide explains the data types used in the RetailStore database.

## Character/Text Types

| Type | Description | When to Use | Example |
|------|-------------|-------------|---------|
| `VARCHAR(n)` | Variable-length text (ASCII) | Emails, phone numbers, codes | `VARCHAR(100)` for email |
| `NVARCHAR(n)` | Variable-length text (Unicode) | Names, addresses (supports all languages) | `NVARCHAR(200)` for name |
| `CHAR(n)` | Fixed-length text | Country codes, state codes | `CHAR(2)` for US state |

**Rule of Thumb**: Use `VARCHAR` for English-only data. Use `NVARCHAR` for names and international text.

## Numeric Types

| Type | Description | Range | When to Use |
|------|-------------|-------|-------------|
| `INT` | Whole numbers | -2.1 billion to 2.1 billion | IDs, quantities, counts |
| `DECIMAL(p,s)` | Exact decimal | Based on precision | Prices, percentages |
| `MONEY` | Currency | ±922 trillion | Salaries, large amounts |
| `BIT` | True/False | 0 or 1 | Flags (IsActive, Discontinued) |

**Examples**:
- `DECIMAL(10,2)` = 10 total digits, 2 after decimal → `12345678.90`
- `DECIMAL(5,2)` = 5 total digits, 2 after decimal → `999.99`

## Date/Time Types

| Type | Description | Storage | When to Use |
|------|-------------|---------|-------------|
| `DATE` | Date only | 3 bytes | Birthdays, hire dates |
| `DATETIME2` | Date + time | 6-8 bytes | Orders, timestamps |
| `TIME` | Time only | 3-5 bytes | Schedules, durations |

**Recommendation**: Use `DATETIME2` instead of the older `DATETIME` type.

## Common Patterns in RetailStore

```sql
-- Auto-incrementing ID
ProductID INT PRIMARY KEY IDENTITY(1,1)

-- Required text field
ProductName NVARCHAR(200) NOT NULL

-- Optional text field
Description NVARCHAR(500)  -- NULL allowed

-- Price with validation
Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0)

-- Boolean flag with default
IsActive BIT DEFAULT 1

-- Auto-set timestamp
DateJoined DATETIME2 DEFAULT SYSDATETIME()
```

## Choosing the Right Data Type

1. **For IDs**: Always use `INT IDENTITY(1,1)`
2. **For names**: Use `NVARCHAR(100)` or `NVARCHAR(200)`
3. **For prices**: Use `DECIMAL(10,2)`
4. **For yes/no**: Use `BIT`
5. **For dates**: Use `DATE` or `DATETIME2`

## Next Steps

See the table creation file (`02-table-creation-basics.sql`) for real examples of these types in action.
