/*
============================================================================
Lesson 12.01 - Multiuser Databases
============================================================================

Description:
Understand the challenges of concurrent database access in multi-user
environments. Learn about race conditions, lost updates, dirty reads,
non-repeatable reads, and phantom reads.

Topics Covered:
• Concurrent access scenarios
• Race conditions
• Lost update problem
• Dirty reads
• Non-repeatable reads
• Phantom reads
• Importance of concurrency control
• Real-world examples

Prerequisites:
• Basic SQL operations (SELECT, INSERT, UPDATE, DELETE)
• Understanding of database basics

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Multi-User Environments
============================================================================
*/

-- Example 1.1: Single User vs Multi-User
/*
SINGLE USER DATABASE:
┌────────────┐
│   User 1   │
└─────┬──────┘
      │
      ▼
┌─────────────┐
│  Database   │
└─────────────┘

• Simple, predictable
• No conflicts
• No need for locking
• Fast operations


MULTI-USER DATABASE:
┌────────────┐  ┌────────────┐  ┌────────────┐
│   User 1   │  │   User 2   │  │   User 3   │
└─────┬──────┘  └─────┬──────┘  └─────┬──────┘
      │               │               │
      └───────┬───────┴───────┬───────┘
              │               │
              ▼               ▼
        ┌─────────────────────────┐
        │      Database          │
        └─────────────────────────┘

• Complex interactions
• Potential conflicts
• Requires locking
• Need for transaction control
• Concurrency challenges
*/

-- Example 1.2: Typical Multi-User Scenario
/*
Time  User 1                        User 2
──────────────────────────────────────────────────────────────
T1    SELECT Balance FROM Accounts
      WHERE AccountID = 123;
      (Reads: $1000)

T2                                  SELECT Balance FROM Accounts
                                    WHERE AccountID = 123;
                                    (Reads: $1000)

T3    UPDATE Accounts
      SET Balance = 900
      WHERE AccountID = 123;
      (Withdraws $100)

T4                                  UPDATE Accounts
                                    SET Balance = 800
                                    WHERE AccountID = 123;
                                    (Withdraws $200)

T5    COMMIT;                       COMMIT;

Result: Balance = $800 (Should be $700!)
Problem: User 2's update overwrote User 1's update
This is called a "LOST UPDATE"
*/

-- Example 1.3: Concurrent Access Demonstration Setup
CREATE TABLE #BankAccounts (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(50),
    Balance DECIMAL(10,2)
);

INSERT INTO #BankAccounts VALUES
(101, 'Alice', 1000.00),
(102, 'Bob', 1500.00),
(103, 'Charlie', 2000.00);

SELECT * FROM #BankAccounts;


/*
============================================================================
PART 2: Race Conditions
============================================================================
*/

-- Example 2.1: Race Condition Definition
/*
RACE CONDITION:
A situation where the outcome depends on the timing or sequence of events
that are unpredictable or uncontrollable.

Visual Example - Two Users Booking Last Seat:
┌─────────────────────────────────────────────────────────────┐
│  Time    User A                    User B                   │
├─────────────────────────────────────────────────────────────┤
│  T1      Check seats available     Check seats available   │
│          (Result: 1 seat)          (Result: 1 seat)        │
│  T2      Reserve seat              Reserve seat            │
│  T3      Confirm booking           Confirm booking         │
└─────────────────────────────────────────────────────────────┘

Problem: Both users booked the same seat because they checked 
         availability before either completed their booking.
*/

-- Example 2.2: Race Condition Scenario
CREATE TABLE #ProductInventory (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    QuantityAvailable INT
);

INSERT INTO #ProductInventory VALUES
(1, 'Limited Edition Widget', 1);  -- Only 1 left!

-- User 1's perspective (Session 1)
DECLARE @User1_Check INT;
SELECT @User1_Check = QuantityAvailable 
FROM #ProductInventory 
WHERE ProductID = 1;

PRINT 'User 1 sees: ' + CAST(@User1_Check AS VARCHAR) + ' available';

IF @User1_Check > 0
BEGIN
    PRINT 'User 1: Product available, proceeding with purchase...';
    -- Simulating processing time
    WAITFOR DELAY '00:00:02';
    
    UPDATE #ProductInventory 
    SET QuantityAvailable = QuantityAvailable - 1
    WHERE ProductID = 1;
    
    PRINT 'User 1: Purchase complete!';
END

-- User 2's perspective (would run in separate session simultaneously)
/*
DECLARE @User2_Check INT;
SELECT @User2_Check = QuantityAvailable 
FROM #ProductInventory 
WHERE ProductID = 1;

PRINT 'User 2 sees: ' + CAST(@User2_Check AS VARCHAR) + ' available';

IF @User2_Check > 0
BEGIN
    PRINT 'User 2: Product available, proceeding with purchase...';
    WAITFOR DELAY '00:00:01';
    
    UPDATE #ProductInventory 
    SET QuantityAvailable = QuantityAvailable - 1
    WHERE ProductID = 1;
    
    PRINT 'User 2: Purchase complete!';
END
*/

-- Result: QuantityAvailable could be -1 (oversold!)
SELECT * FROM #ProductInventory;

DROP TABLE #ProductInventory;


/*
============================================================================
PART 3: Lost Update Problem
============================================================================
*/

-- Example 3.1: Lost Update Scenario
/*
LOST UPDATE:
One transaction's update is overwritten by another transaction.

Timeline:
┌──────────────────────────────────────────────────────────────┐
│ Time  Transaction 1              Transaction 2               │
├──────────────────────────────────────────────────────────────┤
│ T1    READ Balance = 1000                                    │
│ T2                                 READ Balance = 1000       │
│ T3    Calculate: 1000 - 100 = 900                           │
│ T4                                 Calculate: 1000 - 200 = 800│
│ T5    WRITE Balance = 900                                    │
│ T6                                 WRITE Balance = 800       │
│ T7    COMMIT                                                 │
│ T8                                 COMMIT                    │
└──────────────────────────────────────────────────────────────┘

Expected Final Balance: 700 (1000 - 100 - 200)
Actual Final Balance: 800 (Transaction 1's update lost!)
*/

-- Example 3.2: Demonstrating Lost Update
-- Session 1:
BEGIN TRANSACTION;
    DECLARE @Balance1 DECIMAL(10,2);
    
    SELECT @Balance1 = Balance 
    FROM #BankAccounts 
    WHERE AccountID = 101;
    
    PRINT 'Session 1: Read balance = ' + CAST(@Balance1 AS VARCHAR);
    
    -- Simulate processing delay
    WAITFOR DELAY '00:00:03';
    
    SET @Balance1 = @Balance1 - 100;
    
    UPDATE #BankAccounts 
    SET Balance = @Balance1 
    WHERE AccountID = 101;
    
    PRINT 'Session 1: Updated balance to ' + CAST(@Balance1 AS VARCHAR);
COMMIT TRANSACTION;

-- Session 2 (run simultaneously in different window):
/*
BEGIN TRANSACTION;
    DECLARE @Balance2 DECIMAL(10,2);
    
    SELECT @Balance2 = Balance 
    FROM #BankAccounts 
    WHERE AccountID = 101;
    
    PRINT 'Session 2: Read balance = ' + CAST(@Balance2 AS VARCHAR);
    
    WAITFOR DELAY '00:00:01';
    
    SET @Balance2 = @Balance2 - 200;
    
    UPDATE #BankAccounts 
    SET Balance = @Balance2 
    WHERE AccountID = 101;
    
    PRINT 'Session 2: Updated balance to ' + CAST(@Balance2 AS VARCHAR);
COMMIT TRANSACTION;
*/

SELECT * FROM #BankAccounts WHERE AccountID = 101;


/*
============================================================================
PART 4: Dirty Reads
============================================================================
*/

-- Example 4.1: Dirty Read Definition
/*
DIRTY READ:
Reading uncommitted data from another transaction that may be rolled back.

Timeline:
┌──────────────────────────────────────────────────────────────┐
│ Time  Transaction 1              Transaction 2               │
├──────────────────────────────────────────────────────────────┤
│ T1    BEGIN TRANSACTION                                      │
│ T2    UPDATE Price = 99.99                                   │
│ T3                                 READ Price = 99.99 ✗ DIRTY│
│ T4    ROLLBACK                                               │
│ T5                                 Use wrong price!          │
└──────────────────────────────────────────────────────────────┘

Transaction 2 read data that was never actually committed!
*/

-- Example 4.2: Dirty Read Scenario
CREATE TABLE #ProductPrices (
    ProductID INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);

INSERT INTO #ProductPrices VALUES (1, 'Widget', 50.00);

-- Session 1: Updates but rolls back
BEGIN TRANSACTION;
    UPDATE #ProductPrices 
    SET Price = 25.00  -- Temporary price change
    WHERE ProductID = 1;
    
    PRINT 'Session 1: Price temporarily changed to 25.00';
    
    WAITFOR DELAY '00:00:05';  -- Delay to allow Session 2 to read
    
    ROLLBACK TRANSACTION;  -- Oops, cancel the change
    
    PRINT 'Session 1: Rolled back to original price';

-- Session 2: Reads uncommitted data (in separate window)
/*
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- Allows dirty reads

SELECT Price FROM #ProductPrices WHERE ProductID = 1;
-- Might see 25.00 even though it will be rolled back!

PRINT 'Session 2: Read price, creating invoice...';
-- Creates invoice with wrong price!
*/

SELECT * FROM #ProductPrices;  -- Price is back to 50.00

DROP TABLE #ProductPrices;


/*
============================================================================
PART 5: Non-Repeatable Reads
============================================================================
*/

-- Example 5.1: Non-Repeatable Read Definition
/*
NON-REPEATABLE READ:
Reading the same row twice within a transaction yields different values
because another transaction modified the data in between.

Timeline:
┌──────────────────────────────────────────────────────────────┐
│ Time  Transaction 1              Transaction 2               │
├──────────────────────────────────────────────────────────────┤
│ T1    BEGIN TRANSACTION                                      │
│ T2    READ Balance = 1000                                    │
│ T3                                 UPDATE Balance = 500      │
│ T4                                 COMMIT                    │
│ T5    READ Balance = 500 ✗ Different!                       │
│ T6    COMMIT                                                 │
└──────────────────────────────────────────────────────────────┘

The same SELECT returned different results within one transaction!
*/

-- Example 5.2: Non-Repeatable Read Scenario
-- Session 1: Reads same data twice
BEGIN TRANSACTION;
    -- First read
    SELECT Balance 
    FROM #BankAccounts 
    WHERE AccountID = 102;
    PRINT 'Session 1: First read of balance';
    
    -- Delay to allow Session 2 to update
    WAITFOR DELAY '00:00:05';
    
    -- Second read (same transaction)
    SELECT Balance 
    FROM #BankAccounts 
    WHERE AccountID = 102;
    PRINT 'Session 1: Second read of balance - might be different!';
    
COMMIT TRANSACTION;

-- Session 2: Updates in between (separate window)
/*
WAITFOR DELAY '00:00:02';  -- Wait for Session 1 to do first read

UPDATE #BankAccounts 
SET Balance = Balance + 500 
WHERE AccountID = 102;

PRINT 'Session 2: Updated balance';
*/


/*
============================================================================
PART 6: Phantom Reads
============================================================================
*/

-- Example 6.1: Phantom Read Definition
/*
PHANTOM READ:
Executing the same query twice returns different sets of rows
because another transaction inserted or deleted rows in between.

Timeline:
┌──────────────────────────────────────────────────────────────┐
│ Time  Transaction 1              Transaction 2               │
├──────────────────────────────────────────────────────────────┤
│ T1    BEGIN TRANSACTION                                      │
│ T2    SELECT COUNT(*) = 5                                    │
│ T3                                 INSERT new row            │
│ T4                                 COMMIT                    │
│ T5    SELECT COUNT(*) = 6 ✗ Phantom!                        │
│ T6    COMMIT                                                 │
└──────────────────────────────────────────────────────────────┘

New rows "appeared" (phantom) in the middle of the transaction!
*/

-- Example 6.2: Phantom Read Scenario
CREATE TABLE #DailyOrders (
    OrderID INT,
    OrderDate DATE,
    Amount DECIMAL(10,2)
);

INSERT INTO #DailyOrders VALUES
(1, '2024-01-15', 100.00),
(2, '2024-01-15', 200.00),
(3, '2024-01-15', 150.00);

-- Session 1: Counts orders twice
BEGIN TRANSACTION;
    -- First count
    SELECT COUNT(*) AS OrderCount
    FROM #DailyOrders 
    WHERE OrderDate = '2024-01-15';
    PRINT 'Session 1: First count';
    
    -- Delay to allow Session 2 to insert
    WAITFOR DELAY '00:00:05';
    
    -- Second count (same transaction)
    SELECT COUNT(*) AS OrderCount
    FROM #DailyOrders 
    WHERE OrderDate = '2024-01-15';
    PRINT 'Session 1: Second count - phantom row appeared!';
    
COMMIT TRANSACTION;

-- Session 2: Inserts new row (separate window)
/*
WAITFOR DELAY '00:00:02';

INSERT INTO #DailyOrders VALUES
(4, '2024-01-15', 300.00);

PRINT 'Session 2: Inserted new order';
*/

DROP TABLE #DailyOrders;


/*
============================================================================
PART 7: Summary of Concurrency Problems
============================================================================
*/

-- Example 7.1: Concurrency Problems Comparison
/*
┌─────────────────────┬──────────────────────────────────────────────┐
│     Problem         │              Description                     │
├─────────────────────┼──────────────────────────────────────────────┤
│ Lost Update         │ One transaction's changes are overwritten    │
│                     │ by another transaction                       │
├─────────────────────┼──────────────────────────────────────────────┤
│ Dirty Read          │ Reading uncommitted data that may be         │
│                     │ rolled back                                  │
├─────────────────────┼──────────────────────────────────────────────┤
│ Non-Repeatable Read │ Same row read twice gives different values   │
│                     │ within a transaction                         │
├─────────────────────┼──────────────────────────────────────────────┤
│ Phantom Read        │ Same query returns different number of rows  │
│                     │ within a transaction                         │
└─────────────────────┴──────────────────────────────────────────────┘

SEVERITY RANKING (most to least severe):
1. Lost Update        - Data corruption
2. Dirty Read         - Reading invalid data
3. Non-Repeatable Read - Inconsistent reads
4. Phantom Read       - Inconsistent result sets
*/

-- Example 7.2: Real-World Impact
/*
BANKING SCENARIO - Lost Update:
• User A withdraws $100
• User B withdraws $200 simultaneously
• Balance should decrease by $300
• Due to lost update, only decreases by $200
• Impact: Bank loses $100

E-COMMERCE SCENARIO - Dirty Read:
• Admin temporarily marks product as 50% off
• Customer sees discount and places order
• Admin realizes mistake and rolls back
• Customer confirmation shows wrong price
• Impact: Customer service nightmare

REPORTING SCENARIO - Non-Repeatable Read:
• Report totals orders at start: $10,000
• New orders added during report generation
• Report totals at end: $15,000
• Impact: Inconsistent report

INVENTORY SCENARIO - Phantom Read:
• Count low-stock items: 5 items
• New items added to low-stock
• Recount for alert: 8 items
• Impact: Incorrect alert sent
*/


/*
============================================================================
PART 8: Why Concurrency Control is Critical
============================================================================
*/

-- Example 8.1: The Need for Transactions
/*
WITHOUT PROPER CONCURRENCY CONTROL:
┌─────────────────────────────────────────────────────────┐
│ • Lost updates (data corruption)                        │
│ • Inconsistent reads (unreliable reporting)             │
│ • Race conditions (overselling, double-booking)         │
│ • Data integrity violations                             │
│ • Unpredictable application behavior                    │
│ • Customer complaints                                   │
│ • Financial losses                                      │
└─────────────────────────────────────────────────────────┘

WITH PROPER CONCURRENCY CONTROL:
┌─────────────────────────────────────────────────────────┐
│ • Guaranteed data integrity                             │
│ • Predictable behavior                                  │
│ • Consistent results                                    │
│ • Protected against race conditions                     │
│ • Reliable multi-user operations                        │
│ • Business rules enforced                               │
└─────────────────────────────────────────────────────────┘
*/

-- Example 8.2: Solutions Preview
/*
Concurrency control mechanisms:

1. LOCKING
   • Prevents simultaneous access
   • Shared locks for reading
   • Exclusive locks for writing

2. TRANSACTIONS
   • Groups operations into atomic units
   • All-or-nothing execution
   • ACID properties

3. ISOLATION LEVELS
   • Controls visibility of changes
   • Balances consistency vs. performance
   • Different levels for different needs

4. OPTIMISTIC CONCURRENCY
   • Allow simultaneous access
   • Check for conflicts before committing
   • Use versioning or timestamps

We'll explore these solutions in the following lessons!
*/

-- Cleanup
DROP TABLE #BankAccounts;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Describe a lost update scenario in an airline reservation system
2. Explain how a dirty read could affect an online shopping cart
3. Give an example of a non-repeatable read in a hotel booking system
4. Describe a phantom read scenario in an exam grading application
5. Design a scenario where race conditions cause double-booking

Solutions below ↓
*/

-- Solution 1: Airline Reservation Lost Update
/*
Time  Agent A                      Agent B
─────────────────────────────────────────────────────────────
T1    Check seats on Flight 123
      (10 seats available)

T2                                 Check seats on Flight 123
                                   (10 seats available)

T3    Reserve 5 seats
      (Update: 10 - 5 = 5 left)

T4                                 Reserve 3 seats
                                   (Update: 10 - 3 = 7 left)

T5    Commit                       Commit

Result: System shows 7 seats left, but should be 2!
Impact: Overselling by 5 seats
*/

-- Solution 2: Shopping Cart Dirty Read
/*
Scenario:
1. Customer adds expensive item to cart ($500)
2. System calculates tax based on cart total
3. Meanwhile, customer removes item and transaction rolls back
4. Tax calculation reads uncommitted $500 total (dirty read)
5. Customer checks out with different items ($50)
6. Charged incorrect tax amount

Impact: Wrong tax, customer dispute, refund processing
*/

-- Solution 3: Hotel Booking Non-Repeatable Read
/*
Time  Transaction 1                Transaction 2
─────────────────────────────────────────────────────────────
T1    BEGIN booking process

T2    Check room availability
      Room 301: Available

T3                                 UPDATE Room 301 to Reserved
                                   COMMIT

T4    Calculate total price
      (Room still appears available)

T5    Attempt to confirm booking
      Room 301: NOW Reserved!

T6    ERROR - Inconsistent state

Impact: Booking process fails, customer frustration
*/

-- Solution 4: Exam Grading Phantom Read
/*
Time  Grading Transaction          Student Submission
─────────────────────────────────────────────────────────────
T1    Count submitted exams: 25

T2    Calculate average score

T3                                 Late submission added

T4    Recount for verification: 26

T5    Average calculation wrong
      (based on 25, but 26 exist)

Impact: Incorrect grade statistics, unfair grading
*/

-- Solution 5: Event Ticketing Race Condition
/*
SCENARIO: Concert with 1 VIP ticket remaining

User A Process:                   User B Process:
1. Check VIP availability (1)     1. Check VIP availability (1)
2. Add to cart                    2. Add to cart
3. Enter payment info             3. Enter payment info
4. Click "Purchase"               4. Click "Purchase"
5. Decrement inventory            5. Decrement inventory
6. Confirm order                  6. Confirm order

Result: Both users get confirmation
        Inventory: -1 (oversold)
        
Impact: Double-booking, customer complaint, refund, bad PR
*/


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ MULTI-USER CHALLENGES:
  • Multiple users accessing same data simultaneously
  • Timing and order of operations matter
  • Conflicts are inevitable without control mechanisms
  • Need for coordination between transactions

✓ LOST UPDATES:
  • Most severe concurrency problem
  • Causes data corruption
  • Occurs with read-modify-write pattern
  • Must be prevented with locking

✓ DIRTY READS:
  • Reading uncommitted data
  • Data may be rolled back
  • Leads to invalid business decisions
  • Preventable with isolation levels

✓ NON-REPEATABLE READS:
  • Same row changes between reads
  • Inconsistent view within transaction
  • Problematic for calculations and reports
  • Requires higher isolation level

✓ PHANTOM READS:
  • Rows appear or disappear
  • Result set changes between queries
  • Affects aggregations and counts
  • Highest isolation level to prevent

✓ IMPORTANCE OF CONCURRENCY CONTROL:
  • Protects data integrity
  • Ensures predictable behavior
  • Prevents financial losses
  • Maintains customer trust
  • Required for multi-user systems

✓ SOLUTIONS (Coming in next lessons):
  • Locking mechanisms
  • Transactions (ACID properties)
  • Isolation levels
  • Optimistic concurrency control

✓ REAL-WORLD IMPACT:
  • Banking: Lost money
  • E-commerce: Overselling
  • Reservations: Double-booking
  • Reporting: Incorrect data
  • All industries affected

============================================================================
NEXT: Lesson 12.02 - Locking
Learn how databases use locks to control concurrent access.
============================================================================
*/
