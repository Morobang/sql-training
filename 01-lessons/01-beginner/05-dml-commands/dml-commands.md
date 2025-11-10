# Lesson 5: DML Commands

**Level:** 🟢 Beginner

## Learning Objectives

By the end of this lesson, you will be able to:
1. Insert data into tables with INSERT
2. Update existing records with UPDATE
3. Delete records with DELETE
4. Understand transaction basics (COMMIT/ROLLBACK)
5. Use safe practices to avoid data loss
6. Handle common errors

## What is DML?

**DML = Data Manipulation Language**

DML statements **work with data** (not structure like DDL).

**DML Commands:**
```
INSERT  → Add new rows
UPDATE  → Modify existing rows
DELETE  → Remove rows
SELECT  → Retrieve rows (covered in Lesson 3)
```

**DDL vs DML:**
```
DDL (Lesson 4): CREATE TABLE, ALTER TABLE, DROP TABLE
DML (This lesson): INSERT, UPDATE, DELETE
```

---

## Part 1: INSERT - Adding Data

### Basic INSERT

```sql
-- Insert one row
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@email.com');
```

**Structure:**
```sql
INSERT INTO TableName (column1, column2, column3)
VALUES (value1, value2, value3);
```

### Insert Multiple Rows

```sql
-- Insert multiple rows at once (faster!)
INSERT INTO Customers (FirstName, LastName, Email)
VALUES 
    ('Jane', 'Smith', 'jane@email.com'),
    ('Bob', 'Johnson', 'bob@email.com'),
    ('Alice', 'Williams', 'alice@email.com');
```

**Result:**
```
3 rows inserted with one command!
Much faster than 3 separate INSERTs.
```

### Insert with Auto-Increment

```sql
-- When table has IDENTITY column, don't specify it
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,  -- Auto-generated
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2)
);

-- Don't specify ProductID - it's automatic!
INSERT INTO Products (ProductName, Price)
VALUES ('Laptop', 999.99);

-- ProductID will be 1 automatically
```

### Insert with Defaults

```sql
-- Table with default values
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE DEFAULT GETDATE(),  -- Defaults to today
    Status NVARCHAR(20) DEFAULT 'Pending'
);

-- Option 1: Let defaults work
INSERT INTO Orders (CustomerID)
VALUES (1);
-- OrderDate = today, Status = 'Pending'

-- Option 2: Override defaults
INSERT INTO Orders (CustomerID, OrderDate, Status)
VALUES (2, '2024-01-15', 'Shipped');
```

### Insert All Columns

```sql
-- If inserting ALL columns in order, can skip column names
INSERT INTO Customers
VALUES ('Sarah', 'Davis', 'sarah@email.com');

-- ⚠️ Not recommended! Better to be explicit:
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('Sarah', 'Davis', 'sarah@email.com');
```

---

## Part 2: UPDATE - Modifying Data

### Basic UPDATE

```sql
-- Update one customer's email
UPDATE Customers
SET Email = 'newemail@email.com'
WHERE CustomerID = 1;
```

**⚠️ CRITICAL: Always use WHERE or you'll update EVERYTHING!**

### Update Multiple Columns

```sql
-- Update multiple fields at once
UPDATE Customers
SET 
    FirstName = 'Johnny',
    Email = 'johnny@email.com'
WHERE CustomerID = 1;
```

### Update with Calculation

```sql
-- Increase all prices by 10%
UPDATE Products
SET Price = Price * 1.10
WHERE CategoryID = 1;

-- Add 100 to stock quantity
UPDATE Products
SET StockQuantity = StockQuantity + 100
WHERE StockQuantity < 10;
```

### Update with String Functions

```sql
-- Convert all emails to lowercase
UPDATE Customers
SET Email = LOWER(Email);

-- Add prefix to product names
UPDATE Products
SET ProductName = 'NEW - ' + ProductName
WHERE CreatedDate >= '2024-01-01';
```

### Conditional UPDATE

```sql
-- Update based on condition
UPDATE Orders
SET Status = CASE
    WHEN TotalAmount > 1000 THEN 'VIP'
    WHEN TotalAmount > 500 THEN 'Premium'
    ELSE 'Standard'
END;
```

---

## Part 3: DELETE - Removing Data

### Basic DELETE

```sql
-- Delete one customer
DELETE FROM Customers
WHERE CustomerID = 5;
```

**⚠️ CRITICAL: Always use WHERE or you'll delete EVERYTHING!**

### Delete with Conditions

```sql
-- Delete old orders
DELETE FROM Orders
WHERE OrderDate < '2020-01-01';

-- Delete inactive customers
DELETE FROM Customers
WHERE IsActive = 0;

-- Delete products with no stock
DELETE FROM Products
WHERE StockQuantity = 0 AND Discontinued = 1;
```

### Delete with Subquery

```sql
-- Delete customers who never ordered
DELETE FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID FROM Orders
);
```

---

## Part 4: Transactions - Safety First!

### What is a Transaction?

**Transaction = Group of SQL statements that succeed or fail together**

```
Without Transaction:
UPDATE Account SET Balance = Balance - 100 WHERE ID = 1;  ✓
-- Crash here! 😱
UPDATE Account SET Balance = Balance + 100 WHERE ID = 2;  ✗

Result: $100 disappeared!
```

```
With Transaction:
BEGIN TRANSACTION;
    UPDATE Account SET Balance = Balance - 100 WHERE ID = 1;
    UPDATE Account SET Balance = Balance + 100 WHERE ID = 2;
COMMIT;

Result: Both happen or neither happens ✓
```

### BEGIN TRANSACTION

```sql
-- Start a transaction
BEGIN TRANSACTION;
    -- Your SQL statements here
    -- Nothing is saved yet!
COMMIT;  -- Save all changes
```

### COMMIT - Save Changes

```sql
BEGIN TRANSACTION;
    INSERT INTO Customers (FirstName, LastName, Email)
    VALUES ('Test', 'User', 'test@email.com');
    
    -- Verify it looks good
    SELECT * FROM Customers WHERE Email = 'test@email.com';
    
COMMIT;  -- Make it permanent
```

### ROLLBACK - Undo Changes

```sql
BEGIN TRANSACTION;
    DELETE FROM Products WHERE Price < 10;
    
    -- Check how many were deleted
    -- Oh no! Too many!
    
ROLLBACK;  -- Undo the delete
```

### Safe UPDATE Pattern

```sql
-- ALWAYS use this pattern for important updates!

BEGIN TRANSACTION;
    -- 1. See what will be updated
    SELECT * FROM Products WHERE Price < 100;
    
    -- 2. Do the update
    UPDATE Products SET Price = Price * 1.10 WHERE Price < 100;
    
    -- 3. Verify the update
    SELECT * FROM Products WHERE Price < 110;
    
    -- 4. If good, commit. If bad, rollback.
COMMIT;  -- or ROLLBACK;
```

### Safe DELETE Pattern

```sql
BEGIN TRANSACTION;
    -- 1. See what will be deleted
    SELECT * FROM Orders WHERE OrderDate < '2020-01-01';
    
    -- 2. Do the delete
    DELETE FROM Orders WHERE OrderDate < '2020-01-01';
    
    -- 3. Check how many deleted
    PRINT @@ROWCOUNT;  -- Number of rows affected
    
    -- 4. Decide: COMMIT or ROLLBACK
COMMIT;
```

---

## Part 5: Common Patterns

### Pattern 1: Insert and Get ID

```sql
-- Insert a row and get its auto-generated ID
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('New', 'Customer', 'new@email.com');

-- Get the ID that was just created
SELECT SCOPE_IDENTITY() AS NewCustomerID;
```

**Use case:** Create customer, then immediately create order for that customer.

### Pattern 2: Bulk Insert

```sql
-- Insert many rows efficiently
INSERT INTO Products (ProductName, Price, CategoryID)
VALUES 
    ('Product 1', 10.00, 1),
    ('Product 2', 20.00, 1),
    ('Product 3', 30.00, 2),
    ('Product 4', 40.00, 2),
    ('Product 5', 50.00, 3);
```

### Pattern 3: Insert from SELECT

```sql
-- Copy data from one table to another
INSERT INTO CustomersArchive (CustomerID, FirstName, LastName, Email)
SELECT CustomerID, FirstName, LastName, Email
FROM Customers
WHERE LastOrderDate < '2020-01-01';
```

### Pattern 4: Conditional Update

```sql
-- Update only if condition met
UPDATE Products
SET Price = Price * 0.90  -- 10% discount
WHERE CategoryID = 1 
  AND StockQuantity > 100
  AND Price > 50;
```

---

## Part 6: Real-World Examples

### Example 1: Customer Registration

```sql
BEGIN TRANSACTION;
    -- Create customer
    INSERT INTO Customers (FirstName, LastName, Email, SignupDate)
    VALUES ('Alice', 'Brown', 'alice@email.com', GETDATE());
    
    DECLARE @CustomerID INT = SCOPE_IDENTITY();
    
    -- Create initial preferences
    INSERT INTO CustomerPreferences (CustomerID, Newsletter, SMSAlerts)
    VALUES (@CustomerID, 1, 0);
    
    -- Give welcome bonus points
    INSERT INTO LoyaltyPoints (CustomerID, Points, Description)
    VALUES (@CustomerID, 100, 'Welcome Bonus');
    
COMMIT;
```

### Example 2: Order Processing

```sql
BEGIN TRANSACTION;
    -- Update order status
    UPDATE Orders
    SET Status = 'Shipped',
        ShippedDate = GETDATE()
    WHERE OrderID = 12345;
    
    -- Reduce inventory
    UPDATE Products
    SET StockQuantity = StockQuantity - oi.Quantity
    FROM Products p
    INNER JOIN OrderItems oi ON p.ProductID = oi.ProductID
    WHERE oi.OrderID = 12345;
    
    -- Add to shipment log
    INSERT INTO ShipmentLog (OrderID, ShippedDate, Carrier)
    VALUES (12345, GETDATE(), 'FedEx');
    
COMMIT;
```

### Example 3: Data Cleanup

```sql
BEGIN TRANSACTION;
    -- Delete old test data
    DELETE FROM OrderItems
    WHERE OrderID IN (
        SELECT OrderID FROM Orders WHERE CustomerID = 999
    );
    
    DELETE FROM Orders WHERE CustomerID = 999;
    DELETE FROM Customers WHERE CustomerID = 999;
    
    PRINT 'Test customer 999 and all related data removed';
COMMIT;
```

---

## Part 7: Common Mistakes

### Mistake 1: Forgetting WHERE

```sql
-- ❌ DISASTER! Updates ALL customers
UPDATE Customers
SET Email = 'admin@company.com';

-- ✅ CORRECT: Updates one customer
UPDATE Customers
SET Email = 'admin@company.com'
WHERE CustomerID = 1;
```

### Mistake 2: Wrong DELETE Order

```sql
-- ❌ FAILS: Can't delete parent (foreign key violation)
DELETE FROM Customers WHERE CustomerID = 1;
-- Error: Orders still reference this customer!

-- ✅ CORRECT: Delete children first
DELETE FROM OrderItems WHERE OrderID IN (
    SELECT OrderID FROM Orders WHERE CustomerID = 1
);
DELETE FROM Orders WHERE CustomerID = 1;
DELETE FROM Customers WHERE CustomerID = 1;
```

### Mistake 3: No Transaction

```sql
-- ❌ RISKY: No way to undo
UPDATE Products SET Price = Price * 2;  -- Oh no! Wrong calculation!

-- ✅ SAFE: Can rollback
BEGIN TRANSACTION;
    UPDATE Products SET Price = Price * 2;
    -- Check results...
    -- If wrong: ROLLBACK;
    -- If right: COMMIT;
ROLLBACK;  -- Whew! Undone.
```

### Mistake 4: Inserting Duplicates

```sql
-- ❌ FAILS: Email is UNIQUE
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@email.com');  -- First time: OK

INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('Jane', 'Doe', 'john@email.com');  -- Same email: ERROR!

-- ✅ HANDLE IT:
IF NOT EXISTS (SELECT 1 FROM Customers WHERE Email = 'john@email.com')
BEGIN
    INSERT INTO Customers (FirstName, LastName, Email)
    VALUES ('John', 'Doe', 'john@email.com');
END
```

---

## Part 8: Best Practices

### 1. Always Use WHERE with UPDATE/DELETE

```sql
-- ✅ GOOD
UPDATE Products SET Price = 100 WHERE ProductID = 5;
DELETE FROM Orders WHERE OrderID = 123;

-- ❌ BAD (updates/deletes everything!)
UPDATE Products SET Price = 100;
DELETE FROM Orders;
```

### 2. Test SELECT Before DELETE

```sql
-- Step 1: See what will be deleted
SELECT * FROM Customers WHERE LastOrderDate < '2020-01-01';

-- Step 2: If it looks right, delete
DELETE FROM Customers WHERE LastOrderDate < '2020-01-01';
```

### 3. Use Transactions for Important Changes

```sql
BEGIN TRANSACTION;
    -- Your changes
COMMIT;  -- or ROLLBACK if something went wrong
```

### 4. Check @@ROWCOUNT

```sql
UPDATE Customers SET Email = 'new@email.com' WHERE CustomerID = 999;

IF @@ROWCOUNT = 0
    PRINT 'No customer found with ID 999';
ELSE
    PRINT 'Customer updated successfully';
```

### 5. Use Explicit Column Lists

```sql
-- ✅ GOOD: Clear what's being inserted
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@email.com');

-- ❌ BAD: Breaks if table structure changes
INSERT INTO Customers VALUES ('John', 'Doe', 'john@email.com');
```

---

## Practice Exercises

### Exercise 1: INSERT
```sql
-- Create a Products table and insert 5 products with these fields:
-- ProductID (auto-increment), ProductName, Price, StockQuantity
-- Include products with prices ranging from $10 to $500

-- Write your solution:
```

### Exercise 2: UPDATE
```sql
-- Using the Products table:
-- 1. Increase prices by 15% for products under $50
-- 2. Set StockQuantity to 0 for products over $400
-- 3. Use a transaction and verify before committing

-- Write your solution:
```

### Exercise 3: DELETE
```sql
-- Using the Products table:
-- 1. Delete products with 0 stock and price under $20
-- 2. Use a transaction
-- 3. Check how many will be deleted before committing

-- Write your solution:
```

---

## Key Takeaways

### DML Commands
```
INSERT → Add new rows
UPDATE → Modify existing rows
DELETE → Remove rows
SELECT → Retrieve rows (Lesson 3)
```

### Essential Patterns
```sql
-- INSERT
INSERT INTO Table (columns) VALUES (values);

-- UPDATE (always with WHERE!)
UPDATE Table SET column = value WHERE condition;

-- DELETE (always with WHERE!)
DELETE FROM Table WHERE condition;

-- TRANSACTION
BEGIN TRANSACTION;
    -- statements
COMMIT;  -- or ROLLBACK;
```

### Safety Rules
```
✓ Always use WHERE with UPDATE and DELETE
✓ Use transactions for important changes
✓ Test SELECT before DELETE
✓ Check @@ROWCOUNT after modifications
✓ Use explicit column lists in INSERT
✗ Never UPDATE/DELETE without WHERE
✗ Never skip transactions for critical data
```

---

## Quick Reference

```sql
-- INSERT
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@email.com');

-- INSERT multiple
INSERT INTO Customers (FirstName, LastName, Email)
VALUES 
    ('Jane', 'Smith', 'jane@email.com'),
    ('Bob', 'Jones', 'bob@email.com');

-- UPDATE
UPDATE Customers
SET Email = 'new@email.com'
WHERE CustomerID = 1;

-- DELETE
DELETE FROM Customers
WHERE CustomerID = 5;

-- TRANSACTION
BEGIN TRANSACTION;
    -- Your statements
    SELECT * FROM Table;  -- Verify
COMMIT;  -- or ROLLBACK;

-- Get last inserted ID
SELECT SCOPE_IDENTITY();

-- Check rows affected
SELECT @@ROWCOUNT;
```

---

## Next Steps

**🎉 Congratulations! You've completed the Beginner level!**

You now know:
- ✓ What SQL is and why it matters
- ✓ How to set up your environment
- ✓ How to query data (SELECT)
- ✓ How to create structures (DDL)
- ✓ How to manipulate data (DML)

**Continue to [Intermediate Level](../../02-intermediate/)**  
Learn advanced querying, joins, functions, and window functions!

---

## Additional Resources

- **INSERT:** https://docs.microsoft.com/sql/t-sql/statements/insert
- **UPDATE:** https://docs.microsoft.com/sql/t-sql/queries/update
- **DELETE:** https://docs.microsoft.com/sql/t-sql/statements/delete
- **Transactions:** https://docs.microsoft.com/sql/t-sql/language-elements/transactions

**Excellent work! You've mastered the fundamentals of SQL! 🚀**
