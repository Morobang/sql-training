-- ============================================
-- Lesson 5.3: Test Primary Key Rules
-- ============================================

USE TechStore;

-- This works (CustomerID = 1)
INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
VALUES (1, 'John', 'Smith', 'john@email.com');

-- This works (CustomerID = 2, different from 1)
INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
VALUES (2, 'Sarah', 'Johnson', 'sarah@email.com');

-- This FAILS! (CustomerID = 1 already exists)
-- Try running this and see the error:
-- INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
-- VALUES (1, 'Mike', 'Williams', 'mike@email.com');

-- This also FAILS! (CustomerID cannot be NULL)
-- INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
-- VALUES (NULL, 'Jane', 'Doe', 'jane@email.com');

-- ============================================
-- Primary Key prevents duplicates and NULLs!
-- ============================================
