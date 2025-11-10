-- ========================================
-- Basic UPDATE: Update a Single Employee
-- ========================================

USE TechStore;

-- Before: Let's see current employee data
SELECT * FROM Employees;

-- Update employee 1's salary
UPDATE Employees
SET Salary = 65000.00
WHERE EmployeeID = 1;

-- After: Verify the change
SELECT * FROM Employees WHERE EmployeeID = 1;
