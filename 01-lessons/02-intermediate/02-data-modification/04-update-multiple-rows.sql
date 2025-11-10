-- ========================================
-- UPDATE Multiple Rows: Give Raises
-- ========================================

USE TechStore;

-- Before: See all employees in department 1
SELECT * FROM Employees WHERE DepartmentID = 1;

-- Give 10% raise to all employees in department 1
UPDATE Employees
SET Salary = Salary * 1.10
WHERE DepartmentID = 1;

-- After: Verify the raises
SELECT * FROM Employees WHERE DepartmentID = 1;
