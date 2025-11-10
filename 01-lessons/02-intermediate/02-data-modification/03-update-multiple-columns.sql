-- ========================================
-- UPDATE Multiple Columns at Once
-- ========================================

USE TechStore;

-- Before: See employee 2
SELECT * FROM Employees WHERE EmployeeID = 2;

-- Update multiple columns for employee 2
UPDATE Employees
SET 
    Email = 'jane.smith.updated@techstore.com',
    Phone = '555-9999',
    Salary = 70000.00
WHERE EmployeeID = 2;

-- After: Verify all changes
SELECT * FROM Employees WHERE EmployeeID = 2;
