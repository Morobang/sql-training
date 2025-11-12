# Basic SELECT Queries

The `SELECT` statement is the most fundamental and frequently used SQL command. It retrieves data from one or more tables.

## Basic Syntax

```sql
SELECT column1, column2, column3
FROM TableName;
```

To select all columns:

```sql
SELECT * FROM TableName;
```

## Selecting Specific Columns

Instead of retrieving all data, specify only the columns you need:

```sql
SELECT ProductName, Price
FROM Products;
```

**Benefits:**
- Faster queries (less data transferred)
- Easier to read results
- Better performance on large tables

## Column Aliases

Rename columns in the output using `AS`:

```sql
SELECT 
    ProductName AS Name,
    Price AS Cost,
    Category AS Type
FROM Products;
```

You can omit `AS`:

```sql
SELECT 
    ProductName Name,
    Price Cost
FROM Products;
```

## SELECT * - Use with Caution

`SELECT *` retrieves all columns, which can be:

- **Slow** on tables with many columns
- **Wasteful** if you don't need all data
- **Risky** if table structure changes

**Best Practice:** Always specify columns in production code.

## Best Practices

- Select only the columns you need
- Use aliases for clarity, especially with calculations
- Format your SQL for readability (one column per line for long queries)
- Avoid `SELECT *` in production code

## Next Steps

Practice SELECT statements:

- `02-select-all.sql` - Select all columns and rows
- `03-select-specific-columns.sql` - Choose specific columns
- `04-select-with-alias.sql` - Use column aliases
