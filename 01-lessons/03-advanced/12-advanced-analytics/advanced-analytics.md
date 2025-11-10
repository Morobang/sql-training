# Lesson 12: Advanced Analytics & AI with SQL

**Timeline:** 22:24:25 - 23:11:46  
**Duration:** ~47 minutes  
**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Integrate SQL with Python and R for analytics
2. Use SQL for machine learning workflows
3. Work with JSON and XML data in SQL
4. Implement temporal tables for time-travel queries
5. Use graph database features in SQL
6. Connect SQL to cloud analytics platforms
7. Leverage big data SQL engines (Spark SQL, Presto)

---

## Part 1: SQL + Python Integration

### Using pyodbc

```python
import pyodbc

# Connect to SQL Server
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=SalesDB;'
    'Trusted_Connection=yes;'
)

cursor = conn.cursor()

# Execute query
cursor.execute("SELECT CustomerID, TotalSpent FROM CustomerSummary")

# Fetch results
for row in cursor:
    print(f"Customer {row.CustomerID}: ${row.TotalSpent}")

conn.close()
```

### Pandas Integration

```python
import pandas as pd
import pyodbc

conn = pyodbc.connect('...')

# Read SQL query into DataFrame
query = """
SELECT 
    c.CustomerID,
    c.CustomerName,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
"""

df = pd.read_sql(query, conn)

# Analyze with pandas
print(df.describe())
print(df[df['TotalSpent'] > 1000])

# Write DataFrame back to SQL
df.to_sql('CustomerAnalysis', conn, if_exists='replace', index=False)

conn.close()
```

---

## Part 2: Machine Learning with SQL

### SQL Server Machine Learning Services

```sql
-- Enable external scripts
EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE;

-- Run Python from SQL
EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pandas as pd
from sklearn.linear_model import LinearRegression

# Input data from SQL
X = InputDataSet[["Years_Experience"]]
y = InputDataSet["Salary"]

# Train model
model = LinearRegression()
model.fit(X, y)

# Predict
predictions = model.predict(X)
OutputDataSet = pd.DataFrame({"Predicted_Salary": predictions})
',
    @input_data_1 = N'SELECT Years_Experience, Salary FROM Employees',
    @output_data_1_name = N'OutputDataSet'
WITH RESULT SETS ((Predicted_Salary FLOAT));
```

### Storing ML Models in SQL

```sql
-- Create table for models
CREATE TABLE MLModels (
    ModelID INT PRIMARY KEY IDENTITY,
    ModelName VARCHAR(100),
    ModelData VARBINARY(MAX),  -- Serialized model
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Store Python model
DECLARE @model VARBINARY(MAX);
EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pickle
from sklearn.linear_model import LinearRegression

# Train model
model = LinearRegression()
model.fit(X, y)

# Serialize
trained_model = pickle.dumps(model)
',
    @input_data_1 = N'SELECT Years_Experience, Salary FROM Employees',
    @params = N'@model VARBINARY(MAX) OUTPUT',
    @model = @model OUTPUT;

-- Save model
INSERT INTO MLModels (ModelName, ModelData) VALUES ('SalaryPredictor', @model);
```

---

## Part 3: JSON Support in SQL

### Querying JSON Data

```sql
-- Store JSON
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Attributes NVARCHAR(MAX)  -- JSON data
);

INSERT INTO Products VALUES 
(1, 'Laptop', '{"brand": "Dell", "ram": 16, "ssd": 512}'),
(2, 'Mouse', '{"brand": "Logitech", "wireless": true, "dpi": 1600}');

-- Extract JSON values
SELECT 
    ProductID,
    ProductName,
    JSON_VALUE(Attributes, '$.brand') AS Brand,
    JSON_VALUE(Attributes, '$.ram') AS RAM
FROM Products;

-- Query JSON arrays
SELECT 
    CustomerID,
    JSON_VALUE(OrderHistory, '$[0].OrderDate') AS FirstOrderDate,
    JSON_VALUE(OrderHistory, '$[0].Total') AS FirstOrderTotal
FROM Customers;
```

### Modifying JSON

```sql
-- Update JSON property
UPDATE Products
SET Attributes = JSON_MODIFY(Attributes, '$.ram', 32)
WHERE ProductID = 1;

-- Add new property
UPDATE Products
SET Attributes = JSON_MODIFY(Attributes, '$.warranty', '3 years')
WHERE ProductID = 1;
```

### Creating JSON Output

```sql
-- Generate JSON from query results
SELECT 
    CustomerID,
    CustomerName,
    (SELECT OrderID, OrderDate, TotalAmount
     FROM Orders o
     WHERE o.CustomerID = c.CustomerID
     FOR JSON PATH) AS Orders
FROM Customers c
FOR JSON PATH;
```

---

## Part 4: XML Support in SQL

### Querying XML

```sql
-- Store XML
DECLARE @xml XML = '
<Customers>
    <Customer ID="1">
        <Name>John Doe</Name>
        <Email>john@example.com</Email>
    </Customer>
    <Customer ID="2">
        <Name>Jane Smith</Name>
        <Email>jane@example.com</Email>
    </Customer>
</Customers>';

-- Query XML using XQuery
SELECT 
    Customer.value('(@ID)[1]', 'INT') AS CustomerID,
    Customer.value('(Name)[1]', 'VARCHAR(100)') AS Name,
    Customer.value('(Email)[1]', 'VARCHAR(100)') AS Email
FROM @xml.nodes('/Customers/Customer') AS T(Customer);
```

### Creating XML Output

```sql
SELECT 
    CustomerID,
    CustomerName,
    Email
FROM Customers
FOR XML PATH('Customer'), ROOT('Customers');
```

---

## Part 5: Temporal Tables (Time-Travel Queries)

Track complete history of data changes automatically.

```sql
-- Create temporal table
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    Name VARCHAR(100),
    Salary DECIMAL(10,2),
    Department VARCHAR(50),
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Employees_History));

-- Make changes
INSERT INTO Employees (EmployeeID, Name, Salary, Department)
VALUES (1, 'Alice', 50000, 'IT');

UPDATE Employees SET Salary = 60000 WHERE EmployeeID = 1;
UPDATE Employees SET Salary = 70000 WHERE EmployeeID = 1;

-- Query current data
SELECT * FROM Employees;

-- Query historical data
SELECT * FROM Employees FOR SYSTEM_TIME ALL WHERE EmployeeID = 1;

-- Query as of specific date
SELECT * FROM Employees 
FOR SYSTEM_TIME AS OF '2024-01-01' 
WHERE EmployeeID = 1;

-- Query between dates
SELECT * FROM Employees 
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE EmployeeID = 1;
```

---

## Part 6: Graph Database Features

Model relationships as graphs (nodes and edges).

```sql
-- Create node tables
CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    Name VARCHAR(100),
    Age INT
) AS NODE;

CREATE TABLE City (
    CityID INT PRIMARY KEY,
    CityName VARCHAR(100)
) AS NODE;

-- Create edge table
CREATE TABLE LivesIn AS EDGE;

-- Insert nodes
INSERT INTO Person VALUES (1, 'Alice', 30);
INSERT INTO Person VALUES (2, 'Bob', 25);
INSERT INTO City VALUES (1, 'New York');
INSERT INTO City VALUES (2, 'San Francisco');

-- Insert edges
INSERT INTO LivesIn ($from_id, $to_id)
VALUES 
((SELECT $node_id FROM Person WHERE PersonID = 1),
 (SELECT $node_id FROM City WHERE CityID = 1));

-- Query graph
SELECT 
    p.Name AS PersonName,
    c.CityName
FROM Person p, LivesIn, City c
WHERE MATCH(p-(LivesIn)->c);
```

### Finding Shortest Path

```sql
-- Multi-hop query
SELECT 
    p1.Name AS Person1,
    p2.Name AS Person2
FROM Person p1, Knows k1, Person p2, Knows k2, Person p3
WHERE MATCH(p1-(k1)->p2-(k2)->p3);
```

---

## Part 7: Cloud Analytics Integration

### Azure Synapse Analytics

```sql
-- External table in Synapse (query data lake)
CREATE EXTERNAL DATA SOURCE AzureDataLake
WITH (
    TYPE = HADOOP,
    LOCATION = 'wasbs://data@mystorageaccount.blob.core.windows.net'
);

CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (FORMAT_TYPE = PARQUET);

CREATE EXTERNAL TABLE SalesData (
    OrderID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
)
WITH (
    LOCATION = '/sales/',
    DATA_SOURCE = AzureDataLake,
    FILE_FORMAT = ParquetFormat
);

-- Query data lake as if it were a table
SELECT * FROM SalesData WHERE OrderDate >= '2024-01-01';
```

### AWS Athena (Presto SQL)

```sql
-- Create table from S3 data
CREATE EXTERNAL TABLE sales (
    order_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
)
PARTITIONED BY (year INT, month INT)
STORED AS PARQUET
LOCATION 's3://my-bucket/sales/';

-- Query S3 data
SELECT SUM(total_amount) FROM sales WHERE year = 2024;
```

---

## Part 8: Big Data SQL Engines

### Spark SQL

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("SalesAnalysis").getOrCreate()

# Read from database
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://localhost;databaseName=SalesDB") \
    .option("dbtable", "Orders") \
    .option("user", "username") \
    .option("password", "password") \
    .load()

# SQL queries on big data
df.createOrReplaceTempView("orders")
result = spark.sql("""
    SELECT CustomerID, SUM(TotalAmount) AS Total
    FROM orders
    WHERE OrderDate >= '2024-01-01'
    GROUP BY CustomerID
    ORDER BY Total DESC
    LIMIT 10
""")

result.show()
```

### Presto (Distributed SQL)

```sql
-- Query across multiple data sources
SELECT 
    o.OrderID,
    c.CustomerName,
    p.ProductName
FROM mysql.sales.orders o
INNER JOIN postgres.crm.customers c ON o.CustomerID = c.CustomerID
INNER JOIN hive.warehouse.products p ON o.ProductID = p.ProductID;
```

---

## Part 9: Advanced Analytics Functions

### Approximate Count Distinct

```sql
-- Exact (slow on billions of rows)
SELECT COUNT(DISTINCT CustomerID) FROM Orders;

-- Approximate (fast, ~2% error)
SELECT APPROX_COUNT_DISTINCT(CustomerID) FROM Orders;
```

### Statistical Functions

```sql
SELECT 
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Salary) AS MedianSalary,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Salary) AS P90Salary,
    STDEV(Salary) AS StdDeviation,
    VAR(Salary) AS Variance
FROM Employees;
```

### Pivot Tables

```sql
SELECT *
FROM (
    SELECT Year, Quarter, TotalSales
    FROM Sales
) AS SourceTable
PIVOT (
    SUM(TotalSales)
    FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS PivotTable;
```

---

## Part 10: Real-Time Analytics

### Change Data Capture (CDC)

```sql
-- Enable CDC on database
USE SalesDB;
EXEC sys.sp_cdc_enable_db;

-- Enable CDC on table
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name = 'Orders',
    @role_name = NULL;

-- Query changes
SELECT * FROM cdc.dbo_Orders_CT;
```

### Streaming Data with Apache Kafka + SQL

```python
# Consume Kafka stream, process with SQL
from kafka import KafkaConsumer
import json
import pyodbc

consumer = KafkaConsumer('orders', bootstrap_servers=['localhost:9092'])
conn = pyodbc.connect('...')

for message in consumer:
    order = json.loads(message.value)
    
    # Insert into SQL for analytics
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO OrderStream (OrderID, CustomerID, TotalAmount, Timestamp)
        VALUES (?, ?, ?, ?)
    """, order['id'], order['customer'], order['total'], order['timestamp'])
    conn.commit()
```

---

## Practice Exercises

1. Use pandas to read SQL data and perform statistical analysis.
2. Create a temporal table and query historical changes.
3. Store and query JSON product attributes.
4. Build a graph database for social network relationships.
5. Create an external table to query cloud storage (Azure/AWS).

---

## Key Takeaways

- SQL integrates with Python/R for advanced analytics
- JSON and XML support enables semi-structured data handling
- Temporal tables provide automatic change tracking
- Graph features model complex relationships
- Cloud platforms extend SQL to data lakes
- Big data engines (Spark, Presto) use SQL syntax at scale
- Modern SQL supports ML workflows and real-time streaming

---

## 🎉 Congratulations!

You've completed the **Advanced SQL** level! You now have professional-level skills in:
- Subqueries, CTEs, and advanced joins
- Database objects (views, procedures, functions, triggers)
- Performance optimization and execution plans
- Transactions and concurrency control
- Partitioning strategies
- Modern analytics and AI integration

Continue practicing and explore the projects in the `04-projects/` folder!
