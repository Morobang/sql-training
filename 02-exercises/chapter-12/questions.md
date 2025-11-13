# Chapter 12: Transactions - Practice Questions

## Overview
Master transaction control, ACID properties, isolation levels, deadlock handling, savepoints, and concurrent access patterns.

---

## Transaction Basics

### Question 1: ACID Properties (Easy)
Explain each ACID property with a real-world banking example.

<details>
<summary>Click to see answer</summary>

**Answer:**

**ACID = Atomicity, Consistency, Isolation, Durability**

**Example: Bank transfer of $500 from Account A to Account B**

**Atomicity** - All or nothing
```sql
START TRANSACTION;

-- Both must succeed or both must fail
UPDATE accounts SET balance = balance - 500 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 500 WHERE account_id = 'B';

-- If ANY statement fails, ROLLBACK entire transaction
COMMIT;
```

**Result**: Either both updates happen or neither happens. No half-completed transfers.

---

**Consistency** - Database moves from one valid state to another
```sql
-- Constraint: Balance cannot go negative
ALTER TABLE accounts ADD CONSTRAINT chk_balance CHECK (balance >= 0);

START TRANSACTION;
UPDATE accounts SET balance = balance - 500 WHERE account_id = 'A';
-- If Account A has $300, this violates constraint → ROLLBACK
COMMIT;
```

**Result**: Database rules (constraints, triggers) are always enforced.

---

**Isolation** - Concurrent transactions don't interfere
```sql
-- Transaction 1
START TRANSACTION;
SELECT balance FROM accounts WHERE account_id = 'A';  -- Reads $1000
-- ... some processing ...
UPDATE accounts SET balance = balance - 500 WHERE account_id = 'A';
COMMIT;

-- Transaction 2 (running simultaneously)
START TRANSACTION;
SELECT balance FROM accounts WHERE account_id = 'A';  -- What does it read?
UPDATE accounts SET balance = balance - 300 WHERE account_id = 'A';
COMMIT;
```

**Result**: Isolation level determines what Transaction 2 sees (dirty read, phantom read, etc.)

---

**Durability** - Committed changes survive crashes
```sql
START TRANSACTION;
INSERT INTO transactions (account_id, amount, type) 
VALUES ('A', 500, 'deposit');
UPDATE accounts SET balance = balance + 500 WHERE account_id = 'A';
COMMIT;

-- Even if server crashes immediately after COMMIT,
-- the deposit is permanently saved
```

**Result**: Once COMMIT succeeds, changes are permanent (written to disk).

---

**Summary Table:**

| Property | Meaning | Example Violation |
|----------|---------|-------------------|
| **Atomicity** | All or nothing | Half-completed transfer |
| **Consistency** | Rules maintained | Negative balance |
| **Isolation** | No interference | Lost update problem |
| **Durability** | Changes persist | Data loss after commit |

</details>

---

### Question 2: Transaction Control Statements (Easy)
What's the difference between COMMIT, ROLLBACK, and SAVEPOINT?

<details>
<summary>Click to see answer</summary>

**Answer:**

**COMMIT** - Make all changes permanent
```sql
START TRANSACTION;

INSERT INTO orders (customer_id, total) VALUES (123, 99.99);
INSERT INTO order_items (order_id, product_id, qty) VALUES (LAST_INSERT_ID(), 456, 2);
UPDATE inventory SET stock = stock - 2 WHERE product_id = 456;

COMMIT;  -- All changes saved permanently
```

---

**ROLLBACK** - Undo all changes since transaction started
```sql
START TRANSACTION;

UPDATE accounts SET balance = balance - 1000 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 'B';

-- Oops, wrong amount!
ROLLBACK;  -- Both updates discarded, database unchanged
```

---

**SAVEPOINT** - Create a rollback point within a transaction
```sql
START TRANSACTION;

-- Step 1: Insert order
INSERT INTO orders (customer_id, total) VALUES (123, 99.99);
SAVEPOINT order_created;

-- Step 2: Add items
INSERT INTO order_items (order_id, product_id, qty) VALUES (LAST_INSERT_ID(), 456, 2);
INSERT INTO order_items (order_id, product_id, qty) VALUES (LAST_INSERT_ID(), 789, 1);
SAVEPOINT items_added;

-- Step 3: Update inventory
UPDATE inventory SET stock = stock - 2 WHERE product_id = 456;
UPDATE inventory SET stock = stock - 1 WHERE product_id = 789;  -- Error: out of stock

-- Rollback only Step 3, keep Steps 1 & 2
ROLLBACK TO SAVEPOINT items_added;

-- Try different items
INSERT INTO order_items (order_id, product_id, qty) VALUES (LAST_INSERT_ID(), 999, 1);
UPDATE inventory SET stock = stock - 1 WHERE product_id = 999;

COMMIT;  -- Order and modified items saved
```

**Comparison:**

| Command | Action | Scope |
|---------|--------|-------|
| COMMIT | Save changes | Entire transaction |
| ROLLBACK | Undo changes | Entire transaction |
| ROLLBACK TO SAVEPOINT | Undo to point | Partial transaction |
| RELEASE SAVEPOINT | Remove savepoint | N/A |

**Best practices:**
- Use SAVEPOINTs for complex multi-step operations
- Always handle errors with ROLLBACK
- COMMITs are permanent - verify before committing
</details>

---

## Isolation Levels

### Question 3: Isolation Level Problems (Medium)
Demonstrate dirty reads, non-repeatable reads, and phantom reads.

<details>
<summary>Click to see answer</summary>

**Answer:**

**1. Dirty Read** - Reading uncommitted changes

```sql
-- Session 1 (READ UNCOMMITTED)
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;

SELECT balance FROM accounts WHERE account_id = 'A';  
-- Reads $500 (uncommitted change from Session 2)

-- Session 2
START TRANSACTION;
UPDATE accounts SET balance = 500 WHERE account_id = 'A';  -- Not committed yet!
-- ... crash or rollback ...
ROLLBACK;

-- Session 1 read data that never actually existed!
```

---

**2. Non-Repeatable Read** - Same query, different results

```sql
-- Session 1 (READ COMMITTED)
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;

SELECT balance FROM accounts WHERE account_id = 'A';  
-- Returns $1000

-- (Session 2 commits a change here)

SELECT balance FROM accounts WHERE account_id = 'A';  
-- Returns $500 (different from first read!)

COMMIT;

-- Session 2
START TRANSACTION;
UPDATE accounts SET balance = 500 WHERE account_id = 'A';
COMMIT;  -- Session 1 now sees this change
```

---

**3. Phantom Read** - New rows appear in query results

```sql
-- Session 1 (REPEATABLE READ)
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;

SELECT COUNT(*) FROM orders WHERE customer_id = 123;  
-- Returns 5 orders

-- (Session 2 inserts a new order)

SELECT COUNT(*) FROM orders WHERE customer_id = 123;  
-- Returns 6 orders (phantom row appeared!)

COMMIT;

-- Session 2
START TRANSACTION;
INSERT INTO orders (customer_id, total) VALUES (123, 99.99);
COMMIT;
```

---

**Isolation Level Comparison:**

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance |
|-------|------------|---------------------|--------------|-------------|
| **READ UNCOMMITTED** | ✅ Possible | ✅ Possible | ✅ Possible | Fastest |
| **READ COMMITTED** | ❌ Prevented | ✅ Possible | ✅ Possible | Fast |
| **REPEATABLE READ** | ❌ Prevented | ❌ Prevented | ✅ Possible (MySQL prevents) | Slower |
| **SERIALIZABLE** | ❌ Prevented | ❌ Prevented | ❌ Prevented | Slowest |

**Setting isolation level:**
```sql
-- For session
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- For single transaction
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
-- ... queries ...
COMMIT;

-- Check current level
SELECT @@transaction_isolation;  -- MySQL 8.0+
SELECT @@tx_isolation;           -- MySQL 5.7
```

**When to use:**
- **READ UNCOMMITTED**: Reporting where 100% accuracy not critical
- **READ COMMITTED**: Default for most applications
- **REPEATABLE READ**: Financial calculations, critical reports
- **SERIALIZABLE**: High-value transactions, compliance requirements
</details>

---

### Question 4: Deadlock Scenario (Hard)
Create and resolve a deadlock between two transactions.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Classic deadlock scenario:**

```sql
-- Transaction 1
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';  -- Locks row A
-- ... some processing ...
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';  -- Waits for lock on B
COMMIT;

-- Transaction 2 (running simultaneously)
START TRANSACTION;
UPDATE accounts SET balance = balance - 50 WHERE account_id = 'B';   -- Locks row B
-- ... some processing ...
UPDATE accounts SET balance = balance + 50 WHERE account_id = 'A';   -- Waits for lock on A
COMMIT;

-- DEADLOCK! 
-- T1 holds A, wants B
-- T2 holds B, wants A
-- MySQL automatically rolls back one transaction
```

**Error message:**
```
ERROR 1213 (40001): Deadlock found when trying to get lock; 
try restarting transaction
```

---

**Solution 1: Consistent Lock Ordering**
```sql
-- Always lock accounts in ID order

-- Transaction 1
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';  -- Lock A first
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';  -- Then B
COMMIT;

-- Transaction 2
START TRANSACTION;
UPDATE accounts SET balance = balance + 50 WHERE account_id = 'A';   -- Lock A first
UPDATE accounts SET balance = balance - 50 WHERE account_id = 'B';   -- Then B
COMMIT;

-- No deadlock! Both follow same lock order
```

---

**Solution 2: Lock All Resources Upfront**
```sql
START TRANSACTION;

-- Lock all needed rows immediately with FOR UPDATE
SELECT * FROM accounts 
WHERE account_id IN ('A', 'B')
ORDER BY account_id  -- Consistent ordering
FOR UPDATE;

-- Now perform updates safely
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';

COMMIT;
```

---

**Solution 3: Retry Logic in Application**
```python
import mysql.connector
from mysql.connector import errorcode

def transfer_money(from_account, to_account, amount, max_retries=3):
    for attempt in range(max_retries):
        try:
            conn = mysql.connector.connect(...)
            cursor = conn.cursor()
            
            cursor.execute("START TRANSACTION")
            
            # Perform transfer
            cursor.execute(
                "UPDATE accounts SET balance = balance - %s WHERE account_id = %s",
                (amount, from_account)
            )
            cursor.execute(
                "UPDATE accounts SET balance = balance + %s WHERE account_id = %s",
                (amount, to_account)
            )
            
            conn.commit()
            return True  # Success
            
        except mysql.connector.Error as err:
            if err.errno == errorcode.ER_LOCK_DEADLOCK:
                conn.rollback()
                if attempt < max_retries - 1:
                    continue  # Retry
                else:
                    raise  # Max retries exceeded
            else:
                conn.rollback()
                raise
        finally:
            cursor.close()
            conn.close()
    
    return False
```

---

**Solution 4: Reduce Transaction Scope**
```sql
-- Bad: Long-running transaction holds locks
START TRANSACTION;
SELECT * FROM accounts WHERE account_id = 'A' FOR UPDATE;
-- ... 5 seconds of application processing ...
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
COMMIT;

-- Good: Short transaction, release locks quickly
-- Do processing outside transaction
-- ... 5 seconds of application processing ...
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
COMMIT;
```

---

**Detecting deadlocks:**
```sql
-- MySQL
SHOW ENGINE INNODB STATUS;
-- Look for "LATEST DETECTED DEADLOCK" section

-- SQL Server
SELECT * FROM sys.dm_tran_locks;
SELECT * FROM sys.dm_os_waiting_tasks;
```

**Best practices:**
1. Keep transactions short
2. Lock resources in consistent order
3. Use appropriate isolation levels
4. Implement retry logic
5. Monitor deadlock frequency
</details>

---

## Advanced Transaction Patterns

### Question 5: Long-Running Transactions (Medium)
What problems do long transactions cause? How to handle them?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Problems with long transactions:**

1. **Lock Contention** - Blocks other queries
```sql
-- Bad: Holds locks for minutes
START TRANSACTION;
UPDATE orders SET status = 'processing' WHERE order_date = CURDATE();
-- ... send emails, call APIs, process payments (2 minutes) ...
UPDATE orders SET status = 'completed' WHERE order_date = CURDATE();
COMMIT;

-- Meanwhile: All queries on orders table are blocked!
```

2. **Transaction Log Growth** - Fills up disk
```sql
-- Bad: Millions of rows in one transaction
START TRANSACTION;
DELETE FROM old_orders WHERE order_date < '2020-01-01';  -- 10 million rows
COMMIT;

-- Transaction log must keep all deleted rows until COMMIT
-- Can fill disk and crash database
```

3. **Rollback Segment Bloat** - Memory issues
4. **Deadlock Risk** - More likely with longer transactions
5. **Snapshot Isolation Issues** - Old consistent read views

---

**Solution 1: Batch Processing**
```sql
-- Good: Process in chunks
DELIMITER $$
CREATE PROCEDURE delete_old_orders()
BEGIN
    DECLARE rows_deleted INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    
    REPEAT
        START TRANSACTION;
        
        DELETE FROM old_orders 
        WHERE order_date < '2020-01-01'
        LIMIT batch_size;
        
        SET rows_deleted = ROW_COUNT();
        
        COMMIT;
        
        -- Give other transactions a chance
        SELECT SLEEP(0.1);
        
    UNTIL rows_deleted < batch_size END REPEAT;
END$$
DELIMITER ;

CALL delete_old_orders();
```

---

**Solution 2: Minimize Lock Duration**
```sql
-- Bad: Lock entire processing
START TRANSACTION;
SELECT * FROM orders WHERE status = 'pending' FOR UPDATE;
-- ... process in application (30 seconds) ...
UPDATE orders SET status = 'completed' WHERE status = 'pending';
COMMIT;

-- Good: Lock only for updates
SELECT * FROM orders WHERE status = 'pending';  -- No lock
-- ... process in application (30 seconds) ...
START TRANSACTION;
UPDATE orders SET status = 'completed' 
WHERE status = 'pending' AND updated_at = @original_timestamp;  -- Optimistic lock
COMMIT;
```

---

**Solution 3: Optimistic Locking**
```sql
-- Add version column
ALTER TABLE accounts ADD COLUMN version INT DEFAULT 1;

-- Read without locking
SELECT balance, version FROM accounts WHERE account_id = 'A';
-- balance=1000, version=5

-- ... do processing ...

-- Update with version check
START TRANSACTION;
UPDATE accounts 
SET balance = balance - 100,
    version = version + 1
WHERE account_id = 'A' AND version = 5;

IF ROW_COUNT() = 0 THEN
    -- Someone else modified it, retry
    ROLLBACK;
ELSE
    COMMIT;
END IF;
```

---

**Solution 4: Queue Pattern**
```sql
-- Instead of long transaction, use queue
START TRANSACTION;
INSERT INTO payment_queue (order_id, amount, status)
VALUES (12345, 99.99, 'pending');
UPDATE orders SET status = 'queued_for_payment' WHERE order_id = 12345;
COMMIT;

-- Separate worker process payments asynchronously
-- No long locks on orders table
```

---

**Solution 5: Read-Only Transactions**
```sql
-- For reports, use read-only (allows better optimization)
SET TRANSACTION READ ONLY;
START TRANSACTION;

SELECT 
    product_id,
    SUM(quantity) as total_sold,
    SUM(revenue) as total_revenue
FROM sales
WHERE sale_date >= '2024-01-01'
GROUP BY product_id;

COMMIT;
```

**Best practices:**
- Keep transactions < 1 second when possible
- Batch large operations (1000-10000 rows per transaction)
- Use optimistic locking for long user interactions
- Never call external APIs inside transactions
- Use queues for async processing
- Monitor transaction duration metrics
</details>

---

## Real-World Scenarios

### Question 6: E-Commerce Order Processing (Expert)
Implement a complete order processing transaction with inventory management.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
DELIMITER $$

CREATE PROCEDURE process_order(
    IN p_customer_id INT,
    IN p_items JSON,  -- [{"product_id": 123, "quantity": 2}, ...]
    OUT p_order_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_available_stock INT;
    DECLARE v_order_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_item_count INT;
    DECLARE v_idx INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_error_message = 'Transaction failed - order rolled back';
        SET p_order_id = NULL;
    END;
    
    START TRANSACTION;
    
    -- Savepoint after order creation
    INSERT INTO orders (customer_id, order_date, status, total_amount)
    VALUES (p_customer_id, NOW(), 'processing', 0);
    
    SET p_order_id = LAST_INSERT_ID();
    SAVEPOINT order_created;
    
    -- Get item count
    SET v_item_count = JSON_LENGTH(p_items);
    
    -- Process each item
    WHILE v_idx < v_item_count DO
        -- Extract item details
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_idx, '].product_id')));
        SET v_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_idx, '].quantity')));
        
        -- Lock product row and get details
        SELECT price, stock_quantity
        INTO v_price, v_available_stock
        FROM products
        WHERE product_id = v_product_id
        FOR UPDATE;
        
        -- Check stock availability
        IF v_available_stock < v_quantity THEN
            SET p_error_message = CONCAT('Insufficient stock for product ', v_product_id);
            ROLLBACK TO SAVEPOINT order_created;
            DELETE FROM orders WHERE order_id = p_order_id;
            ROLLBACK;
            LEAVE;  -- Exit procedure
        END IF;
        
        -- Add order item
        INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
        VALUES (p_order_id, v_product_id, v_quantity, v_price, v_price * v_quantity);
        
        -- Update inventory
        UPDATE products
        SET stock_quantity = stock_quantity - v_quantity,
            last_sold = NOW()
        WHERE product_id = v_product_id;
        
        -- Track total
        SET v_order_total = v_order_total + (v_price * v_quantity);
        
        -- Log inventory movement
        INSERT INTO inventory_log (product_id, order_id, quantity_change, reason)
        VALUES (v_product_id, p_order_id, -v_quantity, 'order_placed');
        
        SET v_idx = v_idx + 1;
    END WHILE;
    
    -- Update order total
    UPDATE orders
    SET total_amount = v_order_total,
        status = 'confirmed'
    WHERE order_id = p_order_id;
    
    -- Update customer metrics
    UPDATE customer_metrics
    SET total_orders = total_orders + 1,
        lifetime_value = lifetime_value + v_order_total,
        last_order_date = NOW()
    WHERE customer_id = p_customer_id;
    
    -- If everything succeeded, commit
    COMMIT;
    
    SET p_error_message = NULL;
    
END$$

DELIMITER ;
```

**Usage:**
```sql
SET @order_id = NULL;
SET @error = NULL;

CALL process_order(
    123,  -- customer_id
    '[{"product_id": 456, "quantity": 2}, {"product_id": 789, "quantity": 1}]',
    @order_id,
    @error
);

SELECT @order_id AS order_id, @error AS error_message;
```

---

**Alternative: Application-level transaction management**
```python
from contextlib import contextmanager
import mysql.connector

@contextmanager
def transaction(conn):
    """Context manager for transactions with automatic rollback"""
    cursor = conn.cursor()
    try:
        cursor.execute("START TRANSACTION")
        yield cursor
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()

def process_order(customer_id, items):
    conn = mysql.connector.connect(...)
    
    with transaction(conn) as cursor:
        # Create order
        cursor.execute(
            "INSERT INTO orders (customer_id, status) VALUES (%s, 'processing')",
            (customer_id,)
        )
        order_id = cursor.lastrowid
        
        order_total = 0
        
        for item in items:
            product_id = item['product_id']
            quantity = item['quantity']
            
            # Lock and check stock
            cursor.execute(
                """SELECT price, stock_quantity FROM products 
                   WHERE product_id = %s FOR UPDATE""",
                (product_id,)
            )
            price, stock = cursor.fetchone()
            
            if stock < quantity:
                raise ValueError(f"Insufficient stock for product {product_id}")
            
            # Add order item
            cursor.execute(
                """INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                   VALUES (%s, %s, %s, %s)""",
                (order_id, product_id, quantity, price)
            )
            
            # Update inventory
            cursor.execute(
                """UPDATE products SET stock_quantity = stock_quantity - %s
                   WHERE product_id = %s""",
                (quantity, product_id)
            )
            
            order_total += price * quantity
        
        # Update order total
        cursor.execute(
            "UPDATE orders SET total_amount = %s, status = 'confirmed' WHERE order_id = %s",
            (order_total, order_id)
        )
        
        return order_id
    
    # Context manager automatically commits or rolls back
```

**Key transaction features:**
1. ✅ Atomicity - All items processed or none
2. ✅ Consistency - Stock never goes negative
3. ✅ Isolation - FOR UPDATE prevents race conditions
4. ✅ Durability - Committed orders are permanent
5. ✅ Error handling - Automatic rollback on failure
6. ✅ Savepoints - Can partially rollback
7. ✅ Inventory tracking - Audit trail maintained
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 2 questions
- Medium: 2 questions
- Hard: 1 question
- Expert: 1 question

**Topics Covered:**
- ✅ ACID properties explained
- ✅ COMMIT, ROLLBACK, SAVEPOINT
- ✅ Isolation levels and their problems
- ✅ Deadlock detection and resolution
- ✅ Long-running transaction handling
- ✅ Complete order processing example

**Key Takeaways:**
- Always use transactions for multi-step operations
- Choose isolation level based on requirements
- Implement deadlock retry logic
- Keep transactions short
- Use savepoints for complex workflows
- Lock resources in consistent order

**Next Steps:**
- Chapter 13: Indexes and Constraints
- Practice transaction patterns in real applications
