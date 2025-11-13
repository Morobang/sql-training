-- ========================================
-- NULL Functions: COALESCE
-- ========================================

USE TechStore;

-- COALESCE: Return first non-NULL value
-- COALESCE(value1, value2, value3, ...)

-- Single column with default
SELECT 
    EmployeeID,
    COALESCE(Email, 'No Email') AS Email
FROM Employees;

-- Multiple columns (fallback chain)
SELECT 
    EmployeeID,
    COALESCE(Email, Phone, 'No Contact Info') AS ContactInfo
FROM Employees;

-- Practical: Best available contact method
SELECT 
    EmployeeID,
    Email,
    Phone,
    COALESCE(Email, Phone, 'No Contact') AS PreferredContact
FROM Employees;

-- ISNULL vs COALESCE:
-- ISNULL: 2 parameters (SQL Server specific)
-- COALESCE: Multiple parameters (ANSI standard)
