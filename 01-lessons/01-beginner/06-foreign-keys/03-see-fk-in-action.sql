-- ============================================
-- Lesson 6.3: Test Foreign Key Rules
-- ============================================

USE TechStore;

-- Step 1: Insert departments first
INSERT INTO Departments (DepartmentID, DepartmentName)
VALUES (1, 'IT');

INSERT INTO Departments (DepartmentID, DepartmentName)
VALUES (2, 'Sales');

-- Step 2: Insert employees with valid department IDs
INSERT INTO Employees (EmployeeID, EmployeeName, DepartmentID)
VALUES (101, 'John Smith', 1);  -- DepartmentID = 1 exists ✓

INSERT INTO Employees (EmployeeID, EmployeeName, DepartmentID)
VALUES (102, 'Sarah Johnson', 2);  -- DepartmentID = 2 exists ✓

-- Step 3: Try to insert employee with INVALID department
-- This FAILS! (DepartmentID = 99 doesn't exist)
-- INSERT INTO Employees (EmployeeID, EmployeeName, DepartmentID)
-- VALUES (103, 'Mike Williams', 99);

-- ============================================
-- Foreign Key prevents orphaned data!
-- Employee must belong to a real department
-- ============================================
