# Chapter 15: Metadata - Practice Questions

## Overview
Master INFORMATION_SCHEMA, system catalogs, database introspection, dynamic SQL generation, and metadata-driven applications.

---

## INFORMATION_SCHEMA Basics

### Question 1: Exploring Database Structure (Easy)
Use INFORMATION_SCHEMA to list all tables, columns, and constraints in a database.

<details>
<summary>Click to see answer</summary>

**Answer:**

**List all tables:**
```sql
SELECT 
    TABLE_SCHEMA AS database_name,
    TABLE_NAME AS table_name,
    ENGINE,
    TABLE_ROWS AS estimated_rows,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS size_mb,
    TABLE_COLLATION,
    CREATE_TIME,
    UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY size_mb DESC;
```

---

**List all columns for a table:**
```sql
SELECT 
    COLUMN_NAME AS column_name,
    ORDINAL_POSITION AS position,
    DATA_TYPE AS data_type,
    COLUMN_TYPE AS full_type,
    IS_NULLABLE AS nullable,
    COLUMN_DEFAULT AS default_value,
    COLUMN_KEY AS key_type,        -- PRI, UNI, MUL
    EXTRA                           -- auto_increment, etc.
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = 'customers'
ORDER BY ORDINAL_POSITION;
```

---

**List all indexes:**
```sql
SELECT 
    TABLE_NAME AS table_name,
    INDEX_NAME AS index_name,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns,
    INDEX_TYPE,
    NON_UNIQUE,
    CARDINALITY
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'your_database'
GROUP BY TABLE_NAME, INDEX_NAME, INDEX_TYPE, NON_UNIQUE, CARDINALITY
ORDER BY TABLE_NAME, INDEX_NAME;
```

---

**List all foreign keys:**
```sql
SELECT 
    TABLE_NAME AS from_table,
    COLUMN_NAME AS from_column,
    REFERENCED_TABLE_NAME AS to_table,
    REFERENCED_COLUMN_NAME AS to_column,
    CONSTRAINT_NAME AS fk_name
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'your_database'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;
```

---

**List all constraints:**
```sql
-- PRIMARY KEY, UNIQUE, FOREIGN KEY
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'your_database'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- CHECK constraints (MySQL 8.0.16+)
SELECT 
    CONSTRAINT_SCHEMA,
    CONSTRAINT_NAME,
    CHECK_CLAUSE
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'your_database';
```

---

**Complete table documentation:**
```sql
-- Generate table documentation
SELECT 
    CONCAT('## Table: ', t.TABLE_NAME) AS markdown_header,
    CONCAT('- **Engine**: ', t.ENGINE) AS engine_info,
    CONCAT('- **Rows**: ~', FORMAT(t.TABLE_ROWS, 0)) AS row_count,
    CONCAT('- **Size**: ', ROUND((t.DATA_LENGTH + t.INDEX_LENGTH)/1024/1024, 2), ' MB') AS size_info,
    CONCAT('- **Created**: ', t.CREATE_TIME) AS created_at,
    '',
    '### Columns',
    GROUP_CONCAT(
        CONCAT('- `', c.COLUMN_NAME, '` (', c.COLUMN_TYPE, ')',
               IF(c.IS_NULLABLE='NO', ' **NOT NULL**', ''),
               IF(c.COLUMN_KEY='PRI', ' **PRIMARY KEY**', ''),
               IF(c.COLUMN_KEY='UNI', ' **UNIQUE**', ''),
               IF(c.EXTRA='auto_increment', ' **AUTO_INCREMENT**', ''))
        ORDER BY c.ORDINAL_POSITION
        SEPARATOR '\n'
    ) AS columns_list
FROM INFORMATION_SCHEMA.TABLES t
JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA 
    AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'your_database'
  AND t.TABLE_NAME = 'customers'
GROUP BY t.TABLE_NAME;
```

</details>

---

## Metadata Queries

### Question 2: Find Large Tables and Missing Indexes (Medium)
Identify optimization opportunities using metadata.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Find largest tables:**
```sql
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS data_mb,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS index_mb,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS total_mb,
    ROUND(INDEX_LENGTH / DATA_LENGTH * 100, 2) AS index_ratio_pct
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC
LIMIT 20;
```

---

**Find tables without primary keys:**
```sql
SELECT 
    t.TABLE_NAME,
    t.TABLE_ROWS,
    ROUND((t.DATA_LENGTH + t.INDEX_LENGTH) / 1024 / 1024, 2) AS size_mb
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
    ON t.TABLE_SCHEMA = tc.TABLE_SCHEMA 
    AND t.TABLE_NAME = tc.TABLE_NAME 
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
WHERE t.TABLE_SCHEMA = 'your_database'
  AND t.TABLE_TYPE = 'BASE TABLE'
  AND tc.CONSTRAINT_NAME IS NULL
ORDER BY t.TABLE_ROWS DESC;

-- ⚠️ Every table should have a PRIMARY KEY!
```

---

**Find tables with no indexes at all:**
```sql
SELECT 
    t.TABLE_NAME,
    t.TABLE_ROWS,
    ROUND(t.DATA_LENGTH / 1024 / 1024, 2) AS data_mb
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.STATISTICS s 
    ON t.TABLE_SCHEMA = s.TABLE_SCHEMA 
    AND t.TABLE_NAME = s.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'your_database'
  AND t.TABLE_TYPE = 'BASE TABLE'
  AND s.INDEX_NAME IS NULL
ORDER BY t.TABLE_ROWS DESC;
```

---

**Find foreign keys without supporting indexes:**
```sql
-- Foreign key columns should be indexed
SELECT 
    kcu.TABLE_NAME,
    kcu.COLUMN_NAME,
    kcu.REFERENCED_TABLE_NAME,
    kcu.REFERENCED_COLUMN_NAME,
    'Missing index on FK column' AS issue
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
LEFT JOIN INFORMATION_SCHEMA.STATISTICS s 
    ON kcu.TABLE_SCHEMA = s.TABLE_SCHEMA 
    AND kcu.TABLE_NAME = s.TABLE_NAME 
    AND kcu.COLUMN_NAME = s.COLUMN_NAME
WHERE kcu.TABLE_SCHEMA = 'your_database'
  AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
  AND s.INDEX_NAME IS NULL;

-- These FKs will cause slow JOINs!
```

---

**Find duplicate/redundant indexes:**
```sql
-- Indexes with same columns in same order
SELECT 
    s1.TABLE_NAME,
    s1.INDEX_NAME AS index_1,
    s2.INDEX_NAME AS index_2,
    GROUP_CONCAT(s1.COLUMN_NAME ORDER BY s1.SEQ_IN_INDEX) AS columns
FROM INFORMATION_SCHEMA.STATISTICS s1
JOIN INFORMATION_SCHEMA.STATISTICS s2 
    ON s1.TABLE_SCHEMA = s2.TABLE_SCHEMA
    AND s1.TABLE_NAME = s2.TABLE_NAME
    AND s1.COLUMN_NAME = s2.COLUMN_NAME
    AND s1.SEQ_IN_INDEX = s2.SEQ_IN_INDEX
    AND s1.INDEX_NAME < s2.INDEX_NAME  -- Avoid duplicates
WHERE s1.TABLE_SCHEMA = 'your_database'
GROUP BY s1.TABLE_NAME, s1.INDEX_NAME, s2.INDEX_NAME
HAVING COUNT(DISTINCT s1.COLUMN_NAME) = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = s1.TABLE_SCHEMA 
    AND TABLE_NAME = s1.TABLE_NAME 
    AND INDEX_NAME = s1.INDEX_NAME
);

-- Consider dropping redundant indexes
```

---

**Find unused indexes (requires sys schema):**
```sql
-- MySQL 5.7+ with performance_schema enabled
SELECT 
    s.TABLE_SCHEMA,
    s.TABLE_NAME,
    s.INDEX_NAME,
    s.CARDINALITY,
    IFNULL(t.rows_selected, 0) AS rows_selected
FROM INFORMATION_SCHEMA.STATISTICS s
LEFT JOIN sys.schema_index_statistics t 
    ON s.TABLE_SCHEMA = t.table_schema
    AND s.TABLE_NAME = t.table_name
    AND s.INDEX_NAME = t.index_name
WHERE s.TABLE_SCHEMA = 'your_database'
  AND s.INDEX_NAME != 'PRIMARY'
  AND (t.rows_selected IS NULL OR t.rows_selected = 0)
ORDER BY s.TABLE_NAME, s.INDEX_NAME;

-- Indexes never used (candidates for removal)
```

---

**Index size analysis:**
```sql
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS index_size_mb
FROM mysql.innodb_index_stats
WHERE DATABASE_NAME = 'your_database'
  AND STAT_NAME = 'size'
ORDER BY STAT_VALUE DESC
LIMIT 20;

-- Find bloated indexes
```

</details>

---

## Dynamic SQL Generation

### Question 3: Generate SQL from Metadata (Hard)
Write queries that generate CREATE TABLE, INSERT, and UPDATE statements.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Generate CREATE TABLE statement:**
```sql
SELECT 
    CONCAT(
        'CREATE TABLE ', TABLE_NAME, ' (\n',
        GROUP_CONCAT(
            CONCAT(
                '  ', COLUMN_NAME, ' ', COLUMN_TYPE,
                IF(IS_NULLABLE = 'NO', ' NOT NULL', ''),
                IF(COLUMN_DEFAULT IS NOT NULL, CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT)), ''),
                IF(EXTRA != '', CONCAT(' ', EXTRA), '')
            )
            ORDER BY ORDINAL_POSITION
            SEPARATOR ',\n'
        ),
        '\n);'
    ) AS create_statement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = 'customers'
GROUP BY TABLE_NAME;

-- Output:
-- CREATE TABLE customers (
--   customer_id INT NOT NULL AUTO_INCREMENT,
--   name VARCHAR(100) NOT NULL,
--   email VARCHAR(255),
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
```

---

**Generate INSERT statements (with data):**
```sql
-- Prepare INSERT for copying data
SET @table = 'customers';
SET @database = 'your_database';

-- Get column list
SET @columns = (
    SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @database AND TABLE_NAME = @table
);

-- Generate INSERT template
SET @insert_template = CONCAT(
    'INSERT INTO ', @table, ' (', @columns, ') VALUES '
);

-- Generate actual INSERT with data (executed separately)
SET @sql = CONCAT(
    'SELECT CONCAT(''',
    @insert_template,
    ''', ',
    'GROUP_CONCAT(',
    '  CONCAT(''('', ',
    (SELECT GROUP_CONCAT(
        CONCAT('QUOTE(', COLUMN_NAME, ')')
        ORDER BY ORDINAL_POSITION
        SEPARATOR ', '', '', '
    ) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @database AND TABLE_NAME = @table),
    ', '')'') SEPARATOR '', ''',
    '), '';'',
    ') FROM ', @table
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Output:
-- INSERT INTO customers (customer_id, name, email) VALUES 
-- (1, 'John Doe', 'john@example.com'),
-- (2, 'Jane Smith', 'jane@example.com');
```

---

**Generate UPDATE statements:**
```sql
-- Generate UPDATE to sync tables
SELECT 
    CONCAT(
        'UPDATE target_table t\n',
        'JOIN source_table s ON t.', 
        (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
         WHERE TABLE_SCHEMA = 'your_database' AND TABLE_NAME = 'target_table' 
         AND COLUMN_KEY = 'PRI' LIMIT 1),
        ' = s.',
        (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
         WHERE TABLE_SCHEMA = 'your_database' AND TABLE_NAME = 'source_table' 
         AND COLUMN_KEY = 'PRI' LIMIT 1),
        '\nSET\n',
        GROUP_CONCAT(
            CONCAT('  t.', COLUMN_NAME, ' = s.', COLUMN_NAME)
            SEPARATOR ',\n'
        ),
        '\nWHERE t.updated_at < s.updated_at;'
    ) AS update_statement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = 'target_table'
  AND COLUMN_KEY != 'PRI';

-- Output:
-- UPDATE target_table t
-- JOIN source_table s ON t.id = s.id
-- SET
--   t.name = s.name,
--   t.email = s.email,
--   t.updated_at = s.updated_at
-- WHERE t.updated_at < s.updated_at;
```

---

**Generate TRUNCATE for all tables (with FK handling):**
```sql
-- Disable FK checks, truncate all, re-enable
SELECT CONCAT(
    'SET FOREIGN_KEY_CHECKS = 0;\n',
    GROUP_CONCAT(CONCAT('TRUNCATE TABLE ', TABLE_NAME, ';') SEPARATOR '\n'),
    '\nSET FOREIGN_KEY_CHECKS = 1;'
) AS truncate_all
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_TYPE = 'BASE TABLE';
```

---

**Generate SELECT with all columns:**
```sql
-- Generate SELECT statement for a table
SET @table = 'customers';

SELECT CONCAT(
    'SELECT\n',
    GROUP_CONCAT(
        CONCAT('  ', COLUMN_NAME)
        ORDER BY ORDINAL_POSITION
        SEPARATOR ',\n'
    ),
    '\nFROM ', @table, ';'
) AS select_statement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = @table;

-- Output:
-- SELECT
--   customer_id,
--   name,
--   email,
--   created_at
-- FROM customers;
```

---

**Generate DROP statements (dangerous!):**
```sql
-- Generate DROP TABLE for all tables (in correct FK order)
SELECT CONCAT('DROP TABLE IF EXISTS ', TABLE_NAME, ';') AS drop_statement
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Better: Disable FK checks first
SELECT CONCAT(
    'SET FOREIGN_KEY_CHECKS = 0;\n',
    GROUP_CONCAT(CONCAT('DROP TABLE IF EXISTS ', TABLE_NAME, ';') SEPARATOR '\n'),
    '\nSET FOREIGN_KEY_CHECKS = 1;'
) AS drop_all
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_TYPE = 'BASE TABLE';
```

---

**Practical use case: Generate ETL script:**
```sql
-- Generate full data migration script
DELIMITER $$
CREATE PROCEDURE sp_generate_migration_script(
    IN p_source_db VARCHAR(64),
    IN p_target_db VARCHAR(64)
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_table VARCHAR(64);
    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = p_source_db 
        AND TABLE_TYPE = 'BASE TABLE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Disable FK checks
    SELECT 'SET FOREIGN_KEY_CHECKS = 0;' AS migration_sql;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_table;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Generate INSERT...SELECT for each table
        SET @sql = CONCAT(
            'SELECT CONCAT(',
            '''INSERT INTO ', p_target_db, '.', v_table, ' SELECT * FROM ', p_source_db, '.', v_table, ';''',
            ') AS migration_sql'
        );
        
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    
    CLOSE cur;
    
    -- Re-enable FK checks
    SELECT 'SET FOREIGN_KEY_CHECKS = 1;' AS migration_sql;
END$$
DELIMITER ;

CALL sp_generate_migration_script('prod_db', 'dev_db');
```

</details>

---

## Real-World Applications

### Question 4: Data Dictionary Report (Expert)
Create a comprehensive data dictionary for documentation.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Complete data dictionary with relationships
WITH table_info AS (
    SELECT 
        t.TABLE_SCHEMA AS db_name,
        t.TABLE_NAME AS table_name,
        t.TABLE_COMMENT AS table_description,
        t.TABLE_ROWS AS row_count,
        ROUND((t.DATA_LENGTH + t.INDEX_LENGTH) / 1024 / 1024, 2) AS size_mb,
        t.CREATE_TIME,
        t.UPDATE_TIME
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_SCHEMA = 'your_database'
      AND t.TABLE_TYPE = 'BASE TABLE'
),
column_info AS (
    SELECT 
        c.TABLE_NAME,
        c.COLUMN_NAME,
        c.ORDINAL_POSITION AS position,
        c.DATA_TYPE,
        c.COLUMN_TYPE,
        c.IS_NULLABLE,
        c.COLUMN_DEFAULT,
        c.COLUMN_KEY,
        c.EXTRA,
        c.COLUMN_COMMENT AS column_description
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = 'your_database'
),
fk_info AS (
    SELECT 
        kcu.TABLE_NAME,
        kcu.COLUMN_NAME,
        kcu.REFERENCED_TABLE_NAME,
        kcu.REFERENCED_COLUMN_NAME,
        kcu.CONSTRAINT_NAME,
        rc.UPDATE_RULE,
        rc.DELETE_RULE
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc 
        ON kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
        AND kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
    WHERE kcu.TABLE_SCHEMA = 'your_database'
      AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
),
index_info AS (
    SELECT 
        TABLE_NAME,
        INDEX_NAME,
        GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns,
        INDEX_TYPE,
        CASE WHEN NON_UNIQUE = 0 THEN 'UNIQUE' ELSE 'NON-UNIQUE' END AS uniqueness
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = 'your_database'
    GROUP BY TABLE_NAME, INDEX_NAME, INDEX_TYPE, NON_UNIQUE
)
SELECT 
    -- Table section
    CONCAT('# Table: `', ti.table_name, '`') AS section,
    '',
    CONCAT('**Description:** ', COALESCE(ti.table_description, '_No description_')) AS description,
    CONCAT('**Rows:** ~', FORMAT(ti.row_count, 0)) AS rows,
    CONCAT('**Size:** ', ti.size_mb, ' MB') AS size,
    CONCAT('**Created:** ', ti.CREATE_TIME) AS created,
    CONCAT('**Last Modified:** ', COALESCE(ti.UPDATE_TIME, 'Never')) AS modified,
    '',
    '## Columns',
    '',
    '| Column | Type | Nullable | Default | Key | Extra | Description |',
    '|--------|------|----------|---------|-----|-------|-------------|',
    GROUP_CONCAT(
        CONCAT(
            '| `', ci.COLUMN_NAME, '` ',
            '| ', ci.COLUMN_TYPE, ' ',
            '| ', ci.IS_NULLABLE, ' ',
            '| ', COALESCE(ci.COLUMN_DEFAULT, '_NULL_'), ' ',
            '| ', COALESCE(ci.COLUMN_KEY, ''), ' ',
            '| ', COALESCE(ci.EXTRA, ''), ' ',
            '| ', COALESCE(ci.column_description, ''), ' |'
        )
        ORDER BY ci.position
        SEPARATOR '\n'
    ) AS columns_table,
    '',
    '## Foreign Keys',
    '',
    COALESCE(
        (SELECT GROUP_CONCAT(
            CONCAT(
                '- `', fk.COLUMN_NAME, '` → `', 
                fk.REFERENCED_TABLE_NAME, '.', fk.REFERENCED_COLUMN_NAME, '`',
                ' (ON UPDATE ', fk.UPDATE_RULE, ', ON DELETE ', fk.DELETE_RULE, ')'
            )
            SEPARATOR '\n'
        )
        FROM fk_info fk
        WHERE fk.TABLE_NAME = ti.table_name),
        '_No foreign keys_'
    ) AS foreign_keys,
    '',
    '## Indexes',
    '',
    COALESCE(
        (SELECT GROUP_CONCAT(
            CONCAT(
                '- **', idx.INDEX_NAME, '** (',
                idx.uniqueness, ', ', idx.INDEX_TYPE, '): `',
                idx.index_columns, '`'
            )
            ORDER BY idx.INDEX_NAME
            SEPARATOR '\n'
        )
        FROM index_info idx
        WHERE idx.TABLE_NAME = ti.table_name),
        '_No indexes_'
    ) AS indexes,
    '',
    '---',
    ''
FROM table_info ti
LEFT JOIN column_info ci ON ti.table_name = ci.TABLE_NAME
GROUP BY ti.table_name
ORDER BY ti.table_name;
```

**Output (Markdown format):**
```
# Table: `customers`

**Description:** Stores customer information
**Rows:** ~150,000
**Size:** 25.5 MB
**Created:** 2024-01-15 10:30:00
**Last Modified:** 2024-03-20 15:45:00

## Columns

| Column | Type | Nullable | Default | Key | Extra | Description |
|--------|------|----------|---------|-----|-------|-------------|
| `customer_id` | INT | NO | _NULL_ | PRI | auto_increment | Unique customer identifier |
| `name` | VARCHAR(100) | NO | _NULL_ |  |  | Full customer name |
| `email` | VARCHAR(255) | YES | _NULL_ | UNI |  | Email address |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP |  |  | Registration date |

## Foreign Keys

_No foreign keys_

## Indexes

- **PRIMARY** (UNIQUE, BTREE): `customer_id`
- **idx_email** (UNIQUE, BTREE): `email`
- **idx_created** (NON-UNIQUE, BTREE): `created_at`

---
```

---

**Export to CSV for Excel:**
```sql
SELECT 
    t.TABLE_NAME AS 'Table Name',
    c.COLUMN_NAME AS 'Column Name',
    c.DATA_TYPE AS 'Data Type',
    c.CHARACTER_MAXIMUM_LENGTH AS 'Max Length',
    c.IS_NULLABLE AS 'Nullable',
    c.COLUMN_KEY AS 'Key',
    c.COLUMN_DEFAULT AS 'Default',
    c.EXTRA AS 'Extra',
    c.COLUMN_COMMENT AS 'Description'
FROM INFORMATION_SCHEMA.TABLES t
JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA 
    AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'your_database'
  AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION
INTO OUTFILE '/tmp/data_dictionary.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---

**Entity Relationship Diagram (ERD) data:**
```sql
-- Generate DOT format for GraphViz
SELECT CONCAT(
    'digraph ERD {\n',
    '  node [shape=box];\n',
    GROUP_CONCAT(
        CONCAT(
            '  "', kcu.TABLE_NAME, '" -> "', 
            kcu.REFERENCED_TABLE_NAME, 
            '" [label="', kcu.COLUMN_NAME, '"];'
        )
        SEPARATOR '\n'
    ),
    '\n}'
) AS erd_dot
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
WHERE kcu.TABLE_SCHEMA = 'your_database'
  AND kcu.REFERENCED_TABLE_NAME IS NOT NULL;

-- Output can be visualized with GraphViz: dot -Tpng erd.dot -o erd.png
```

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 1 question
- Hard: 1 question
- Expert: 1 question

**Topics Covered:**
- ✅ INFORMATION_SCHEMA tables
- ✅ Finding missing indexes and PKs
- ✅ Dynamic SQL generation
- ✅ Data dictionary creation

**Key Takeaways:**
- INFORMATION_SCHEMA is the database about the database
- Use metadata to find optimization opportunities
- Generate SQL dynamically for migrations
- Create automated documentation

**Next Steps:**
- Chapter 16: Window Functions
- Build metadata-driven tools
