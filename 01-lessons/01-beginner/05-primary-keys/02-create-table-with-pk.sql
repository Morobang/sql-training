-- ============================================
-- Lesson 5.2: Create Table WITH Primary Key
-- ============================================

USE TechStore;

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100)
);

-- ============================================
-- Created Customers table
-- CustomerID is the PRIMARY KEY
-- ============================================
