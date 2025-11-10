-- ============================================
-- Lesson 6.2: Create Related Tables
-- ============================================

USE TechStore;

-- First: Create the parent table (Departments)
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY,
    DepartmentName VARCHAR(50)
);

-- Second: Create the child table (Employees)
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    DepartmentID INT,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

-- ============================================
-- Created TWO tables with a relationship!
-- Employees.DepartmentID → Departments.DepartmentID
-- ============================================
