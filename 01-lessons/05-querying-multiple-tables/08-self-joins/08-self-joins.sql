/*============================================
   LESSON 08: SELF JOINS
   Joining a table to itself
   
   Estimated Time: 20 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS A SELF JOIN?
   Definition and purpose
--------------------------------------------*/

/*
   A SELF JOIN is when a table is joined to itself
   
   Used for:
   • Hierarchical data (employees → managers)
   • Parent-child relationships
   • Comparing rows within same table
   • Finding related records
   
   Key: Same table appears twice with different aliases
*/

/*--------------------------------------------
   PART 2: CLASSIC EXAMPLE: EMPLOYEE HIERARCHY
   Employees and their managers
--------------------------------------------*/

-- View the Employees table structure
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    ManagerID  -- References another EmployeeID in same table!
FROM HR.Employees;

-- SELF JOIN: Match employees with their managers
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    mgr.FirstName + ' ' + mgr.LastName AS Manager
FROM HR.Employees emp
INNER JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID;

-- "emp" and "mgr" are SAME table, different roles!

/*--------------------------------------------
   PART 3: UNDERSTANDING THE RELATIONSHIP
   How self-referencing works
--------------------------------------------*/

/*
   Employees Table:
   ┌────────────┬───────────┬───────────┬───────────┐
   │ EmployeeID │ FirstName │ LastName  │ ManagerID │
   ├────────────┼───────────┼───────────┼───────────┤
   │     1      │   John    │   Smith   │    NULL   │  ← CEO (no manager)
   │     2      │   Sarah   │   Johnson │      1    │  ← Reports to John
   │     3      │   Mike    │   Wilson  │      1    │  ← Reports to John
   │     4      │   Emily   │   Brown   │      2    │  ← Reports to Sarah
   └────────────┴───────────┴───────────┴───────────┘
   
   Self Join Logic:
   emp.ManagerID = mgr.EmployeeID
   
   Results:
   Sarah's ManagerID (1) → John's EmployeeID (1)
   Mike's ManagerID (1)  → John's EmployeeID (1)
   Emily's ManagerID (2) → Sarah's EmployeeID (2)
*/

/*--------------------------------------------
   PART 4: INCLUDING TOP-LEVEL ROWS
   Using LEFT JOIN for complete hierarchy
--------------------------------------------*/

-- INNER JOIN: Excludes employees without managers (like CEO)
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    mgr.FirstName + ' ' + mgr.LastName AS Manager
FROM HR.Employees emp
INNER JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID;

-- LEFT JOIN: Includes ALL employees, even those without managers
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    ISNULL(mgr.FirstName + ' ' + mgr.LastName, 'No Manager (CEO)') AS Manager
FROM HR.Employees emp
LEFT JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID;

/*--------------------------------------------
   PART 5: MULTI-LEVEL HIERARCHY
   Including additional details
--------------------------------------------*/

-- Show employee, manager, and salary comparison
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    emp.Salary AS EmployeeSalary,
    ISNULL(mgr.FirstName + ' ' + mgr.LastName, 'Top Level') AS Manager,
    mgr.Salary AS ManagerSalary,
    CASE 
        WHEN mgr.Salary IS NULL THEN 'N/A'
        WHEN emp.Salary > mgr.Salary THEN 'Earns More than Manager!'
        ELSE 'Earns Less than Manager'
    END AS SalaryComparison
FROM HR.Employees emp
LEFT JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID
ORDER BY emp.ManagerID, emp.Salary DESC;

/*--------------------------------------------
   PART 6: COUNTING DIRECT REPORTS
   How many employees report to each manager?
--------------------------------------------*/

-- Count direct reports per manager
SELECT 
    mgr.FirstName + ' ' + mgr.LastName AS Manager,
    COUNT(emp.EmployeeID) AS DirectReports
FROM HR.Employees mgr
LEFT JOIN HR.Employees emp ON mgr.EmployeeID = emp.ManagerID
GROUP BY mgr.EmployeeID, mgr.FirstName, mgr.LastName
ORDER BY DirectReports DESC;

/*--------------------------------------------
   PART 7: FINDING SPECIFIC RELATIONSHIPS
   Managers with certain characteristics
--------------------------------------------*/

-- Find employees who earn more than their manager
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    emp.Salary AS EmployeeSalary,
    mgr.FirstName + ' ' + mgr.LastName AS Manager,
    mgr.Salary AS ManagerSalary,
    emp.Salary - mgr.Salary AS SalaryDifference
FROM HR.Employees emp
INNER JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID
WHERE emp.Salary > mgr.Salary
ORDER BY SalaryDifference DESC;

/*--------------------------------------------
   PART 8: PEER COMPARISON
   Employees with same manager
--------------------------------------------*/

-- Find employees who share the same manager (peers)
SELECT 
    emp1.FirstName + ' ' + emp1.LastName AS Employee1,
    emp2.FirstName + ' ' + emp2.LastName AS Employee2,
    mgr.FirstName + ' ' + mgr.LastName AS SharedManager
FROM HR.Employees emp1
INNER JOIN HR.Employees emp2 ON emp1.ManagerID = emp2.ManagerID
INNER JOIN HR.Employees mgr ON emp1.ManagerID = mgr.EmployeeID
WHERE emp1.EmployeeID < emp2.EmployeeID  -- Avoid duplicates
ORDER BY SharedManager, Employee1;

/*--------------------------------------------
   PART 9: THREE-LEVEL HIERARCHY
   Employee → Manager → Manager's Manager
--------------------------------------------*/

-- Show employee, manager, and grand-manager
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    mgr.FirstName + ' ' + mgr.LastName AS Manager,
    grandmgr.FirstName + ' ' + grandmgr.LastName AS ExecutiveManager
FROM HR.Employees emp
LEFT JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID
LEFT JOIN HR.Employees grandmgr ON mgr.ManagerID = grandmgr.EmployeeID
WHERE emp.ManagerID IS NOT NULL;

/*--------------------------------------------
   PART 10: ORGANIZATIONAL DEPTH
   How many levels in hierarchy?
--------------------------------------------*/

-- Calculate reporting level for each employee
WITH EmployeeLevel AS (
    -- Base case: Top-level employees (no manager)
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        ManagerID,
        0 AS Level
    FROM HR.Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive case: Employees with managers
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        e.ManagerID,
        el.Level + 1
    FROM HR.Employees e
    INNER JOIN EmployeeLevel el ON e.ManagerID = el.EmployeeID
)
SELECT 
    FirstName + ' ' + LastName AS Employee,
    Level,
    REPLICATE('  ', Level) + FirstName AS HierarchyView
FROM EmployeeLevel
ORDER BY Level, LastName;

/*--------------------------------------------
   PART 11: PRACTICAL EXAMPLE: PRODUCT CATEGORIES
   If categories had parent categories
--------------------------------------------*/

/*
   Example: If we had hierarchical categories
   
   CategoryID  CategoryName     ParentCategoryID
   1           Electronics      NULL
   2           Computers        1
   3           Laptops          2
   4           Gaming Laptops   3
   
   Self-join would show:
   Laptops → Computers → Electronics
*/

-- Simulated example with comments
/*
SELECT 
    child.CategoryName AS Subcategory,
    parent.CategoryName AS ParentCategory
FROM Categories child
INNER JOIN Categories parent ON child.ParentCategoryID = parent.CategoryID;
*/

/*--------------------------------------------
   PART 12: FINDING ORPHANS
   Records that should have a parent but don't
--------------------------------------------*/

-- Find employees whose ManagerID points to non-existent employee
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    emp.ManagerID AS InvalidManagerID
FROM HR.Employees emp
LEFT JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID
WHERE emp.ManagerID IS NOT NULL
  AND mgr.EmployeeID IS NULL;

-- Should return no rows if data integrity is good!

/*--------------------------------------------
   PART 13: SALARY RANGES WITHIN TEAMS
   Compare employees to their teammates
--------------------------------------------*/

-- Show salary range within each manager's team
SELECT 
    mgr.FirstName + ' ' + mgr.LastName AS Manager,
    COUNT(emp.EmployeeID) AS TeamSize,
    MIN(emp.Salary) AS MinSalary,
    MAX(emp.Salary) AS MaxSalary,
    AVG(emp.Salary) AS AvgSalary,
    MAX(emp.Salary) - MIN(emp.Salary) AS SalaryRange
FROM HR.Employees mgr
INNER JOIN HR.Employees emp ON mgr.EmployeeID = emp.ManagerID
GROUP BY mgr.EmployeeID, mgr.FirstName, mgr.LastName
HAVING COUNT(emp.EmployeeID) > 1
ORDER BY TeamSize DESC;

/*--------------------------------------------
   PART 14: BEST PRACTICES FOR SELF JOINS
--------------------------------------------*/

/*
   ✅ DO:
   • Use descriptive aliases (emp, mgr NOT e1, e2)
   • Include NULL handling for top-level records
   • Use LEFT JOIN to include all records
   • Comment the relationship being modeled
   • Validate foreign key integrity
   
   ❌ DON'T:
   • Use cryptic aliases
   • Forget about NULL references
   • Create infinite loops (employee manages themselves!)
   • Join without clear business logic
   • Ignore orphaned records
*/

/*--------------------------------------------
   PART 15: COMMON SELF JOIN PATTERNS
--------------------------------------------*/

-- Pattern 1: Parent-Child
-- SELECT child.*, parent.* FROM Table child JOIN Table parent ON child.ParentID = parent.ID

-- Pattern 2: Peers (same parent)
-- SELECT t1.*, t2.* FROM Table t1 JOIN Table t2 ON t1.ParentID = t2.ParentID WHERE t1.ID < t2.ID

-- Pattern 3: Multi-level hierarchy
-- SELECT e1.*, e2.*, e3.* FROM Table e1 JOIN Table e2 ON e1.ParentID = e2.ID JOIN Table e3 ON e2.ParentID = e3.ID

-- Pattern 4: Recursive (using CTE)
-- WITH RECURSIVE ... (covered in Chapter 09)

/*--------------------------------------------
   PART 16: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. List all employees with their managers' names

-- 2. Find employees who don't have a manager (top-level)

-- 3. Count how many direct reports each manager has

-- 4. Find employees who earn within $5,000 of their manager

-- 5. Show employees and their manager's manager

-- 6. List employees who have the same manager (peers)

-- 7. Find the highest-paid employee in each manager's team

-- 8. Calculate the average salary of each manager's team

/*============================================
   KEY CONCEPTS
============================================*/

/*
   Self Join:
   • Table joined to itself
   • Requires different aliases (emp, mgr)
   • Common for hierarchical data
   • Use LEFT JOIN to include top-level records
   • Check for orphaned records
   
   Classic Pattern (Employee-Manager):
   SELECT 
       emp.Name AS Employee,
       mgr.Name AS Manager
   FROM Employees emp
   LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID;
   
   Key Fields:
   • ID (primary key)
   • ParentID/ManagerID (foreign key to same table)
*/

/*============================================
   NEXT: Lesson 09 - Test Your Knowledge
   (Comprehensive practice exercises)
============================================*/
