# Lesson 08: Self Joins - Visual Guide

## What You'll Learn
- Joining a table to itself
- Employee-Manager hierarchies
- Finding related records in same table
- Comparing rows within a table

---

## What is a Self Join?

A **self join** is when a table is joined to **itself** using different aliases.

```
┌──────────────────────────────────────────────────────┐
│              Same Table Used Twice                   │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Employees Table (as "emp"):                         │
│  ┌────┬─────────┬───────────┐                        │
│  │ ID │  Name   │ ManagerID │                        │
│  ├────┼─────────┼───────────┤                        │
│  │ 1  │  John   │   NULL    │ ← CEO                 │
│  │ 2  │  Sarah  │     1     │ ← Reports to John     │
│  │ 3  │  Mike   │     1     │ ← Reports to John     │
│  │ 4  │  Emily  │     2     │ ← Reports to Sarah    │
│  └────┴─────────┴───────────┘                        │
│         ↑              ↓                              │
│         │    Self-Reference                          │
│         └──────────────┘                              │
│                                                       │
│  Employees Table (as "mgr"):                         │
│  ┌────┬─────────┬───────────┐                        │
│  │ ID │  Name   │ ManagerID │                        │
│  ├────┼─────────┼───────────┤                        │
│  │ 1  │  John   │   NULL    │                        │
│  │ 2  │  Sarah  │     1     │                        │
│  │ 3  │  Mike   │     1     │                        │
│  │ 4  │  Emily  │     2     │                        │
│  └────┴─────────┴───────────┘                        │
│                                                       │
│  Same physical table, two different roles!           │
└──────────────────────────────────────────────────────┘
```

---

## Classic Example: Employee-Manager Relationship

### The Data

```
Employees Table:
┌────────────┬───────────┬───────────┬───────────┐
│ EmployeeID │ FirstName │ LastName  │ ManagerID │
├────────────┼───────────┼───────────┼───────────┤
│      1     │   John    │   Smith   │    NULL   │ ← CEO
│      2     │   Sarah   │   Johnson │      1    │ ← John's report
│      3     │   Mike    │   Wilson  │      1    │ ← John's report
│      4     │   Emily   │   Brown   │      2    │ ← Sarah's report
│      5     │   David   │   Lee     │      2    │ ← Sarah's report
└────────────┴───────────┴───────────┴───────────┘
                                      ↑
                        References EmployeeID in SAME table
```

### The Self Join

```sql
SELECT 
    emp.FirstName AS Employee,
    mgr.FirstName AS Manager
FROM Employees emp
INNER JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID;
```

### How It Works

```
Step 1: Table appears twice with different aliases

emp (Employee perspective):    mgr (Manager perspective):
┌────┬───────┬───────┐        ┌────┬───────┬───────┐
│ ID │ Name  │ MgrID │        │ ID │ Name  │ MgrID │
├────┼───────┼───────┤        ├────┼───────┼───────┤
│ 2  │ Sarah │   1   │────────→│ 1  │ John  │ NULL  │
│ 3  │ Mike  │   1   │────────→│ 2  │ Sarah │   1   │
│ 4  │ Emily │   2   │────────→│ 3  │ Mike  │   1   │
└────┴───────┴───────┘        └────┴───────┴───────┘

Step 2: Match emp.ManagerID with mgr.EmployeeID

Sarah's ManagerID (1) → John's EmployeeID (1) ✓
Mike's ManagerID (1)  → John's EmployeeID (1) ✓
Emily's ManagerID (2) → Sarah's EmployeeID (2) ✓

Step 3: Result

┌──────────┬─────────┐
│ Employee │ Manager │
├──────────┼─────────┤
│  Sarah   │  John   │
│  Mike    │  John   │
│  Emily   │  Sarah  │
│  David   │  Sarah  │
└──────────┴─────────┘
```

---

## Visual: Self Join Process

```
┌────────────────────────────────────────────────────────┐
│                   Self Join Visualization              │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Employees (as 'emp')          Employees (as 'mgr')    │
│  ┌────┬────────┬──────┐       ┌────┬────────┐         │
│  │ ID │  Name  │MgrID │       │ ID │  Name  │         │
│  ├────┼────────┼──────┤       ├────┼────────┤         │
│  │ 2  │ Sarah  │  1   │───────→│ 1  │ John   │        │
│  │ 3  │ Mike   │  1   │───────→│ 1  │ John   │        │
│  │ 4  │ Emily  │  2   │───────→│ 2  │ Sarah  │        │
│  │ 5  │ David  │  2   │───────→│ 2  │ Sarah  │        │
│  └────┴────────┴──────┘       └────┴────────┘         │
│                                                         │
│  JOIN ON emp.ManagerID = mgr.EmployeeID                │
│                                                         │
│  Result:                                                │
│  ┌────────┬─────────┐                                  │
│  │  emp   │   mgr   │                                  │
│  ├────────┼─────────┤                                  │
│  │ Sarah  │  John   │  ← Sarah reports to John        │
│  │ Mike   │  John   │  ← Mike reports to John         │
│  │ Emily  │  Sarah  │  ← Emily reports to Sarah       │
│  │ David  │  Sarah  │  ← David reports to Sarah       │
│  └────────┴─────────┘                                  │
└────────────────────────────────────────────────────────┘
```

---

## INNER JOIN vs LEFT JOIN

### INNER JOIN (Excludes top-level)

```sql
SELECT emp.Name, mgr.Name AS Manager
FROM Employees emp
INNER JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID;
```

```
┌──────────┬─────────┐
│ Employee │ Manager │
├──────────┼─────────┤
│  Sarah   │  John   │
│  Mike    │  John   │
│  Emily   │  Sarah  │
│  David   │  Sarah  │
└──────────┴─────────┘

John is MISSING! (He has no manager → ManagerID = NULL)
```

### LEFT JOIN (Includes everyone)

```sql
SELECT 
    emp.Name AS Employee,
    ISNULL(mgr.Name, 'No Manager') AS Manager
FROM Employees emp
LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID;
```

```
┌──────────┬──────────────┐
│ Employee │   Manager    │
├──────────┼──────────────┤
│  John    │ No Manager   │ ← Now included!
│  Sarah   │  John        │
│  Mike    │  John        │
│  Emily   │  Sarah       │
│  David   │  Sarah       │
└──────────┴──────────────┘

Everyone appears, even those without a manager
```

---

## Organizational Chart Visualization

```
                    John (CEO)
                       │
           ┌───────────┴───────────┐
           │                       │
         Sarah                   Mike
           │
     ┌─────┴─────┐
     │           │
   Emily       David

Self Join Query Result:
┌──────────┬─────────┬────────┐
│ Employee │ Manager │ Level  │
├──────────┼─────────┼────────┤
│  John    │  NULL   │   0    │ ← Top
│  Sarah   │  John   │   1    │ ← Reports to CEO
│  Mike    │  John   │   1    │ ← Reports to CEO
│  Emily   │  Sarah  │   2    │ ← Reports to Sarah
│  David   │  Sarah  │   2    │ ← Reports to Sarah
└──────────┴─────────┴────────┘
```

---

## Finding Peers (Same Manager)

```sql
SELECT 
    emp1.Name AS Employee1,
    emp2.Name AS Employee2,
    mgr.Name AS SharedManager
FROM Employees emp1
INNER JOIN Employees emp2 ON emp1.ManagerID = emp2.ManagerID
INNER JOIN Employees mgr ON emp1.ManagerID = mgr.EmployeeID
WHERE emp1.EmployeeID < emp2.EmployeeID;
```

### How It Works

```
Employees with same ManagerID:

ManagerID = 1 (John):           ManagerID = 2 (Sarah):
┌────┬───────┐                 ┌────┬───────┐
│ ID │ Name  │                 │ ID │ Name  │
├────┼───────┤                 ├────┼───────┤
│ 2  │ Sarah │                 │ 4  │ Emily │
│ 3  │ Mike  │                 │ 5  │ David │
└────┴───────┘                 └────┴───────┘
     ↑                              ↑
   Peers!                         Peers!

Result:
┌───────────┬───────────┬────────────────┐
│ Employee1 │ Employee2 │ SharedManager  │
├───────────┼───────────┼────────────────┤
│  Sarah    │   Mike    │     John       │
│  Emily    │   David   │     Sarah      │
└───────────┴───────────┴────────────────┘
```

---

## Three-Level Hierarchy

```sql
SELECT 
    emp.Name AS Employee,
    mgr.Name AS Manager,
    grandmgr.Name AS ExecutiveManager
FROM Employees emp
LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID
LEFT JOIN Employees grandmgr ON mgr.ManagerID = grandmgr.EmployeeID;
```

### Visualization

```
Employee → Manager → Executive

Emily    → Sarah   → John
David    → Sarah   → John
Sarah    → John    → NULL
Mike     → John    → NULL
John     → NULL    → NULL

┌──────────┬─────────┬───────────────────┐
│ Employee │ Manager │ ExecutiveManager  │
├──────────┼─────────┼───────────────────┤
│  Emily   │  Sarah  │      John         │ ← 3 levels
│  David   │  Sarah  │      John         │ ← 3 levels
│  Sarah   │  John   │      NULL         │ ← 2 levels
│  Mike    │  John   │      NULL         │ ← 2 levels
│  John    │  NULL   │      NULL         │ ← 1 level
└──────────┴─────────┴───────────────────┘
```

---

## Counting Direct Reports

```sql
SELECT 
    mgr.Name AS Manager,
    COUNT(emp.EmployeeID) AS DirectReports
FROM Employees mgr
LEFT JOIN Employees emp ON mgr.EmployeeID = emp.ManagerID
GROUP BY mgr.EmployeeID, mgr.Name;
```

### Visual Breakdown

```
John (EmployeeID 1):
├─ Sarah (ManagerID = 1) ✓
├─ Mike  (ManagerID = 1) ✓
→ Count = 2

Sarah (EmployeeID 2):
├─ Emily (ManagerID = 2) ✓
├─ David (ManagerID = 2) ✓
→ Count = 2

Mike (EmployeeID 3):
└─ (no reports)
→ Count = 0

Result:
┌─────────┬────────────────┐
│ Manager │ DirectReports  │
├─────────┼────────────────┤
│  John   │       2        │
│  Sarah  │       2        │
│  Mike   │       0        │
│  Emily  │       0        │
│  David  │       0        │
└─────────┴────────────────┘
```

---

## Common Self Join Patterns

### Pattern 1: Parent-Child

```sql
SELECT child.*, parent.*
FROM Table child
JOIN Table parent ON child.ParentID = parent.ID;
```

### Pattern 2: Peers (Shared Parent)

```sql
SELECT t1.Name, t2.Name, parent.Name
FROM Table t1
JOIN Table t2 ON t1.ParentID = t2.ParentID
JOIN Table parent ON t1.ParentID = parent.ID
WHERE t1.ID < t2.ID;  -- Avoid duplicates
```

### Pattern 3: Comparing Rows

```sql
SELECT p1.Name, p2.Name
FROM Products p1
JOIN Products p2 ON p1.CategoryID = p2.CategoryID
WHERE p1.ProductID <> p2.ProductID;
```

---

## Avoiding Common Mistakes

### Mistake #1: Comparing to Self

```sql
-- ❌ BAD: Employee compared to themselves
SELECT emp.Name, peer.Name
FROM Employees emp
JOIN Employees peer ON emp.ManagerID = peer.ManagerID;

Result includes: Sarah → Sarah, Mike → Mike (wrong!)

-- ✅ GOOD: Exclude self-comparison
SELECT emp.Name, peer.Name
FROM Employees emp
JOIN Employees peer ON emp.ManagerID = peer.ManagerID
WHERE emp.EmployeeID <> peer.EmployeeID;
```

### Mistake #2: Duplicate Pairs

```sql
-- ❌ BAD: Gets both (A, B) and (B, A)
SELECT t1.Name, t2.Name
FROM Table t1
JOIN Table t2 ON t1.ParentID = t2.ParentID
WHERE t1.ID <> t2.ID;

-- ✅ GOOD: Use < to get only one pair
SELECT t1.Name, t2.Name
FROM Table t1
JOIN Table t2 ON t1.ParentID = t2.ParentID
WHERE t1.ID < t2.ID;
```

---

## Real-World Use Cases

```
1. Organizational Charts
   └─ Employee → Manager hierarchies

2. Category Trees
   └─ Category → Parent Category

3. Product Comparisons
   └─ Compare products in same category

4. Friend Networks
   └─ User → Friend (both are users)

5. Location Hierarchies
   └─ City → State → Country

6. Part Assemblies
   └─ Part → Parent Assembly
```

---

## Key Takeaways

```
✅ DO:
  • Use descriptive aliases (emp, mgr not e1, e2)
  • Use LEFT JOIN to include top-level records
  • Exclude self-comparisons (emp.ID <> mgr.ID)
  • Use ID < ID to avoid duplicate pairs
  • Handle NULL foreign keys (top-level records)

❌ DON'T:
  • Forget different aliases (required!)
  • Allow rows to match themselves
  • Create duplicate pairs
  • Use cryptic alias names
  • Ignore NULL handling
```

---

## Quick Reference

### Self Join Template

```sql
-- Employee-Manager Pattern
SELECT 
    emp.Name AS Employee,
    mgr.Name AS Manager
FROM Employees emp
LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID;

-- Peer Comparison Pattern
SELECT 
    t1.Name AS Item1,
    t2.Name AS Item2
FROM Table t1
JOIN Table t2 ON t1.CategoryID = t2.CategoryID
WHERE t1.ID < t2.ID;  -- Avoid duplicates

-- Three-Level Hierarchy
SELECT 
    child.Name,
    parent.Name,
    grandparent.Name
FROM Table child
LEFT JOIN Table parent ON child.ParentID = parent.ID
LEFT JOIN Table grandparent ON parent.ParentID = grandparent.ID;
```

---

**Next:** [Lesson 09 - Test Your Knowledge](../09-test-your-knowledge/09-test-your-knowledge.sql)
