# Inserting Data into Tables

Once you have created a table, the next step is to populate it with data. The `INSERT` statement is used to add new rows to a table.

## Basic INSERT Syntax

### Single Row Insert

```sql
INSERT INTO TableName (Column1, Column2, Column3)
VALUES (Value1, Value2, Value3);
```

### Multiple Rows Insert

```sql
INSERT INTO TableName (Column1, Column2, Column3)
VALUES 
    (Value1, Value2, Value3),
    (Value4, Value5, Value6),
    (Value7, Value8, Value9);
```

## Important Points

- **Column Order**: List columns in any order, but values must match that order
- **Text Values**: Enclose text in single quotes: `'Hello World'`
- **Numbers**: Don't use quotes: `42`, `99.99`
- **Dates**: Enclose in single quotes: `'2024-01-15'`
- **NULL Values**: Use `NULL` without quotes for missing data

## Omitting Column Names

If you provide values for ALL columns in the correct order, you can omit column names:

```sql
INSERT INTO TableName
VALUES (Value1, Value2, Value3);
```

**Warning**: This is risky because if the table structure changes, your INSERT will break.

## Verifying Your Data

After inserting data, verify it was added correctly:

```sql
SELECT * FROM TableName;
```

## Common Errors

- Missing quotes around text/dates
- Wrong number of values (must match column count)
- Data type mismatch (e.g., text in a number column)
- Violating constraints (e.g., duplicate primary keys)

## Best Practices

- Always specify column names explicitly
- Insert multiple rows in a single statement for better performance
- Verify data after insertion
- Use transactions for multiple related inserts

## Next Steps

Practice inserting data:

- `02-insert-single-row.sql` - Insert one row at a time
- `03-insert-multiple-rows.sql` - Insert many rows efficiently
- `04-verify-inserts.sql` - Check your inserted data
