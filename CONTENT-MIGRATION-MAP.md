# Content Migration Map

This document shows how the original 18-chapter structure maps to the new 3-level course structure.

---

## Migration Strategy

**OLD STRUCTURE** (18 sequential chapters)  
→ **NEW STRUCTURE** (3 levels: Beginner / Intermediate / Advanced)

---

## BEGINNER LEVEL (Lessons 1-5)

Already created - keep as is with new comprehensive lessons.

---

## INTERMEDIATE LEVEL

### Source → Destination Mapping

| New Lesson | Source Chapters | Content to Merge |
|------------|----------------|------------------|
| 01-filtering-data | 04-filtering | All lessons on WHERE, operators, conditions |
| 02-sql-joins-basics | 05-querying-multiple-tables (lessons 1-4) | INNER JOIN, basic syntax |
| 03-sql-joins-advanced | 05-querying-multiple-tables (5-8), 10-joins-revisited | OUTER, SELF, advanced patterns |
| 04-set-operators | 06-working-with-sets | UNION, INTERSECT, EXCEPT |
| 05-string-functions | 07-data-generation-manipulation (lessons 1-2) | String functions |
| 06-numeric-functions | 07-data-generation-manipulation (lessons 3-4) | Numeric functions |
| 07-date-time-functions | 07-data-generation-manipulation (lessons 5-8) | Date/time functions |
| 08-null-functions | 04-filtering (09-null-handling) | NULL handling, COALESCE |
| 09-case-expressions | 11-conditional-logic | CASE statements |
| 10-aggregate-functions | 08-grouping-aggregates | GROUP BY, HAVING, aggregates |
| 11-window-functions-basics | 16-analytic-functions (lessons 1-3) | OVER(), PARTITION BY |
| 12-window-functions-aggregates | 16-analytic-functions (lessons 4-6) | Window frames, moving avg |
| 13-window-functions-ranking | 16-analytic-functions (lessons 7-8) | ROW_NUMBER, RANK, NTILE |
| 14-window-functions-value | 16-analytic-functions (lessons 9-10) | LAG, LEAD, FIRST_VALUE |

---

## ADVANCED LEVEL

### Source → Destination Mapping

| New Lesson | Source Chapters | Content to Merge |
|------------|----------------|------------------|
| 01-subqueries | 09-subqueries | All subquery lessons |
| 02-ctes | 09-subqueries (CTEs if present), new content | Common Table Expressions |
| 03-views | 14-views | Creating and managing views |
| 04-stored-procedures | 15-metadata (if procedures covered), new | Stored procedures |
| 05-functions | 15-metadata (if UDFs covered), new | User-defined functions |
| 06-triggers | New content | Triggers |
| 07-indexes-performance | 13-indexes-constraints (index lessons) | Index design, performance |
| 08-execution-plans | 17-large-databases (performance lessons) | Reading execution plans |
| 09-transactions | 12-transactions | ACID, isolation levels |
| 10-query-optimization | 17-large-databases | Query tuning |
| 11-partitioning | 17-large-databases (partitioning lessons) | Table partitioning |
| 12-advanced-analytics | 18-sql-big-data | Analytics, modern SQL |

---

## Files to Preserve

Keep these in their original locations (or archive):
- `00-getting-started/` - Setup guides
- `02-exercises/` - All exercises by chapter
- `03-assets/` - Cheatsheets, diagrams, scripts
- `04-projects/` - Project folders

---

## Migration Commands (PowerShell)

Execute these to reorganize content (BACKUP FIRST!):

```powershell
# Create backup
Copy-Item "01-lessons" "01-lessons-BACKUP-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Recurse

# Move chapters to archive folder (preserve originals)
New-Item -Path "01-lessons/00-original-chapters" -ItemType Directory -Force
Move-Item "01-lessons/01-background" "01-lessons/00-original-chapters/"
Move-Item "01-lessons/02-creating-database" "01-lessons/00-original-chapters/"
# ... (continue for all 18 chapters)
```

---

## Next Steps

1. ✅ Create backup of 01-lessons folder
2. Create archive folder for original chapters
3. Keep new 3-level structure (01-beginner, 02-intermediate, 03-advanced)
4. Original chapters available in archive for reference
5. Update main README with new navigation

---

## Benefits of New Structure

- **Progressive Learning**: Clear beginner → intermediate → advanced path
- **Video-Aligned**: Timeline markers for video production
- **Consolidated**: Related topics grouped together (e.g., all window functions in 4 lessons)
- **Practical**: Focused on skills needed at each level
