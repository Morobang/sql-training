# Database Creation

A **database** is a structured collection of data organized for easy access, management, and updating. In SQL Server, creating a database is your first step in building any application.

## Why Create a Database?

- **Organization**: Separate different projects or applications
- **Security**: Control access at the database level
- **Management**: Easier backups, restores, and maintenance
- **Isolation**: Keep development, testing, and production data separate

## Basic Syntax

```sql
CREATE DATABASE DatabaseName;
```

## Using a Database

After creating a database, you need to tell SQL Server which database to use:

```sql
USE DatabaseName;
```

## Viewing Databases

To see all databases on your server:

```sql
SELECT name FROM sys.databases;
```

Or use the system stored procedure:

```sql
EXEC sp_databases;
```

## Best Practices

- Use meaningful database names (e.g., `TechStore`, `EmployeePortal`)
- Avoid special characters and spaces in names
- Use consistent naming conventions (PascalCase or snake_case)
- Document the purpose of each database

## Next Steps

Practice creating databases with the SQL files in this folder:
- `02-create-database.sql` - Create your first database
- `03-see-databases.sql` - View all databases
- `04-use-database.sql` - Switch between databases
