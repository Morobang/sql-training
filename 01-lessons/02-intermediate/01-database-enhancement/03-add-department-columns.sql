-- ============================================
-- Intermediate Lesson 1.3: Add Department Columns
-- ============================================

USE TechStore;

-- Add Location column
ALTER TABLE Departments
ADD Location VARCHAR(100);

-- Add ManagerID column (which employee manages this dept)
ALTER TABLE Departments
ADD ManagerID INT;

-- Add Budget column
ALTER TABLE Departments
ADD Budget DECIMAL(12,2);

-- ============================================
-- Verify the new structure
-- ============================================

EXEC sp_help 'Departments';

-- ============================================
-- Departments table now has:
-- - DepartmentID (from beginner)
-- - DepartmentName (from beginner)
-- - Location (NEW)
-- - ManagerID (NEW)
-- - Budget (NEW)
-- ============================================
