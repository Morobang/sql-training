-- ============================================
-- Intermediate Lesson 1.2: Add Employee Columns
-- ============================================
-- Prerequisites: Complete beginner lessons (TechStore database exists)
-- ============================================

USE TechStore;

-- Add Email column
ALTER TABLE Employees
ADD Email VARCHAR(100);

-- Add Phone column
ALTER TABLE Employees
ADD Phone VARCHAR(20);

-- Add Salary column
ALTER TABLE Employees
ADD Salary DECIMAL(10,2);

-- Add HireDate column
ALTER TABLE Employees
ADD HireDate DATE;

-- ============================================
-- Verify the new structure
-- ============================================

EXEC sp_help 'Employees';

-- ============================================
-- Employees table now has:
-- - EmployeeID (from beginner)
-- - EmployeeName (from beginner)
-- - DepartmentID (from beginner)
-- - Email (NEW)
-- - Phone (NEW)
-- - Salary (NEW)
-- - HireDate (NEW)
-- ============================================
