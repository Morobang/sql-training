# Creating Your First Tables

Tables are the fundamental building blocks of any database. They store data in rows and columns, similar to a spreadsheet.

## What is a Table?

A **table** is a collection of related data organized in rows (records) and columns (fields). Each column has a specific data type that defines what kind of data it can store.

## Basic Table Structure

```sql
CREATE TABLE TableName (
    ColumnName1 DataType,
    ColumnName2 DataType,
    ColumnName3 DataType
);
```

## Common Data Types

- `INT` - Whole numbers (e.g., 1, 42, -5)
- `VARCHAR(n)` - Variable-length text (e.g., names, descriptions)
- `DECIMAL(p,s)` - Decimal numbers (e.g., prices, percentages)
- `DATE` - Date values (e.g., 2024-01-15)
- `BIT` - Boolean values (0 or 1, True or False)

## Viewing Tables

To see all tables in your database:

```sql
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';
```

To see the structure of a specific table:

```sql
EXEC sp_help 'TableName';
```

Or:

```sql
SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'YourTableName';
```

## Best Practices

- Use singular table names (e.g., `Product` not `Products`)
- Choose descriptive column names (e.g., `CustomerName` not `CN`)
- Select appropriate data types to save space and ensure data integrity
- Plan your table structure before creating it

## Next Steps

Practice creating and exploring tables:

- `02-create-simple-table.sql` - Create your first table
- `03-see-tables.sql` - View all tables in database
- `04-table-structure.sql` - Examine table structure
