# 📂 SQL Scripts Directory Structure

This document shows the location of all executable SQL scripts in the course.

## 🗂️ Complete Structure

```
sql-training/
│
├── 📄 README.md                          # Main course documentation
├── 📄 QUICK-START.md                     # ⭐ Start here!
├── 📄 HOW-TO-USE-SCRIPTS.md             # Detailed guide
├── 📄 WHATS-NEW-SCRIPTS.md              # What's been added
│
├── 📁 00-getting-started/
│   ├── 01-installation-guide.md
│   ├── 02-database-setup.md
│   └── 03-tools-overview.md
│
├── 📁 01-lessons/
│   │
│   ├── 📁 01-background/                 # Chapter 01 (README files only)
│   │   ├── 01-intro-databases/
│   │   ├── 02-nonrelational-databases/
│   │   └── ... (11 lessons total)
│   │
│   └── 📁 02-creating-database/          # Chapter 02 ⭐ MODULAR SQL SCRIPTS!
│       │
│       ├── 📁 00-setup/                  # ⚡ RUN THESE FIRST!
│       │   ├── 📜 01-database-setup-complete.sql      # MUST RUN FIRST
│       │   └── 📜 02-sample-data-insertion.sql        # THEN THIS
│       │
│       ├── 📁 01-creating-sqlserver-database/
│       │   ├── 📄 README.md             # Theory & explanations
│       │   ├── 📜 01-create-database-basic.sql
│       │   ├── 📜 02-create-database-options.sql
│       │   ├── 📜 03-manage-databases.sql
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 02-sqlserver-command-line-tool/
│       │   ├── 📄 README.md             # Documentation
│       │   ├── 📜 01-basic-commands.sql
│       │   ├── 📜 02-navigation-commands.sql
│       │   ├── 📜 03-information-queries.sql
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 03-data-types-character/
│       │   ├── 📄 README.md             # Theory & explanations
│       │   ├── 📜 01-char-varchar-basic.sql          # ✅ NEW
│       │   ├── 📜 02-text-types.sql                  # 🔜 Coming
│       │   ├── 📜 03-string-functions-basic.sql      # 🔜 Coming
│       │   ├── 📜 04-string-functions-intermediate.sql # 🔜 Coming
│       │   ├── 📜 05-collation-charset.sql           # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 04-data-types-numeric/
│       │   ├── 📄 README.md             # Theory & explanations
│       │   ├── 📜 01-integer-types.sql               # 🔜 Coming
│       │   ├── 📜 02-decimal-float.sql               # 🔜 Coming
│       │   ├── 📜 03-numeric-functions-basic.sql     # 🔜 Coming
│       │   ├── 📜 04-numeric-functions-advanced.sql  # 🔜 Coming
│       │   ├── 📜 05-auto-increment.sql              # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 05-data-types-temporal/
│       │   ├── 📄 README.md             # Theory & explanations
│       │   ├── 📜 01-date-time-types.sql             # 🔜 Coming
│       │   ├── 📜 02-timestamp-year.sql              # 🔜 Coming
│       │   ├── 📜 03-date-functions-basic.sql        # 🔜 Coming
│       │   ├── 📜 04-date-functions-intermediate.sql # 🔜 Coming
│       │   ├── 📜 05-date-formatting.sql             # 🔜 Coming
│       │   ├── 📜 06-timezone-handling.sql           # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 06-table-creation-design/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-create-table-basic.sql          # 🔜 Coming
│       │   ├── 📜 02-primary-key-constraints.sql     # 🔜 Coming
│       │   ├── 📜 03-foreign-key-relationships.sql   # 🔜 Coming
│       │   ├── 📜 04-table-constraints-complete.sql  # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 07-table-creation-refinement/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-alter-table-basic.sql           # 🔜 Coming
│       │   ├── 📜 02-modify-columns.sql              # 🔜 Coming
│       │   ├── 📜 03-constraint-management.sql       # 🔜 Coming
│       │   ├── 📜 04-table-optimization.sql          # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 08-building-schema-statements/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-complete-schema-example.sql     # 🔜 Coming
│       │   ├── 📜 02-relationship-types.sql          # 🔜 Coming
│       │   ├── 📜 03-normalization-basics.sql        # 🔜 Coming
│       │   ├── 📜 04-schema-documentation.sql        # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 09-inserting-data/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-insert-single-row.sql           # 🔜 Coming
│       │   ├── 📜 02-insert-multiple-rows.sql        # 🔜 Coming
│       │   ├── 📜 03-insert-select.sql               # 🔜 Coming
│       │   ├── 📜 04-insert-ignore-replace.sql       # 🔜 Coming
│       │   ├── 📜 05-bulk-insert-techniques.sql      # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 10-updating-data/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-update-basic.sql                # 🔜 Coming
│       │   ├── 📜 02-update-with-conditions.sql      # 🔜 Coming
│       │   ├── 📜 03-update-multiple-tables.sql      # 🔜 Coming
│       │   ├── 📜 04-update-best-practices.sql       # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 11-deleting-data/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-delete-basic.sql                # 🔜 Coming
│       │   ├── 📜 02-delete-with-conditions.sql      # 🔜 Coming
│       │   ├── 📜 03-truncate-vs-delete.sql          # 🔜 Coming
│       │   ├── 📜 04-cascade-delete.sql              # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 12-common-errors/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-primary-key-errors.sql          # 🔜 Coming
│       │   ├── 📜 02-foreign-key-errors.sql          # 🔜 Coming
│       │   ├── 📜 03-data-type-errors.sql            # 🔜 Coming
│       │   ├── 📜 04-constraint-violations.sql       # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       ├── 📁 13-sakila-database/
│       │   ├── 📄 README.md
│       │   ├── 📜 01-sakila-schema-exploration.sql   # 🔜 Coming
│       │   ├── 📜 02-sakila-data-practice.sql        # 🔜 Coming
│       │   └── 📜 examples.sql          # Legacy combined file
│       │
│       └── 📁 14-test-your-knowledge/
│           ├── 📄 README.md
│           ├── 📜 01-basic-exercises.sql             # 🔜 Coming
│           ├── 📜 02-intermediate-exercises.sql      # 🔜 Coming
│           ├── 📜 03-advanced-challenges.sql         # 🔜 Coming
│           ├── 📜 04-solutions.sql                   # 🔜 Coming
│           └── 📜 examples.sql          # Legacy combined file
│
├── 📁 02-exercises/
│   ├── 📁 chapter-01/
│   │   └── (exercises coming soon)
│   │
│   ├── 📁 chapter-02/                    # ⭐ HAS EXERCISES!
│   │   ├── 📜 exercises.sql             # ✅ Practice problems (~550 lines)
│   │   └── 📜 solutions.sql             # 🔜 Coming soon
│   │
│   └── 📁 chapter-03 through chapter-18/
│       └── (coming soon)
│
├── 📁 03-assets/
│   ├── cheatsheets/
│   ├── er-diagrams/
│   └── sql-scripts/
│
└── 📁 04-projects/
    ├── 01-library-management-system/
    ├── 02-e-commerce-analysis/
    ├── 03-employee-database/
    └── 04-sales-reporting-system/
```

---

## 🎯 Quick Navigation

### ⚡ Must-Run First
```
01-lessons/02-creating-database/00-setup/complete-setup.sql
```

### 📚 Chapter 02 Lesson Scripts
```
01-lessons/02-creating-database/01-creating-mysql-database/examples.sql
01-lessons/02-creating-database/03-data-types-character/examples.sql
01-lessons/02-creating-database/04-data-types-numeric/examples.sql
01-lessons/02-creating-database/05-data-types-temporal/examples.sql
```

### 🎓 Practice & Exercises
```
02-exercises/chapter-02/exercises.sql
```

---

## 📊 File Count by Type

| Type | Count | Total Lines | Status |
|------|-------|-------------|--------|
| Setup Scripts | 1 | ~450 | ✅ Complete |
| Example Scripts | 4 | ~2,500 | ✅ Complete |
| Exercise Scripts | 1 | ~550 | ✅ Complete |
| README Docs | 30+ | ~45,000 | ✅ Complete |
| Solution Scripts | 0 | 0 | 🔜 Coming |

**Total Executable SQL:** ~3,500 lines across 6 files

---

## 🗺️ Learning Path Map

```
START HERE
    ↓
┌───────────────────────────────┐
│  QUICK-START.md               │  Read first!
└───────────────────────────────┘
    ↓
┌───────────────────────────────┐
│  00-setup/complete-setup.sql  │  Run once
└───────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│  Lesson Cycle (repeat for each lesson):       │
│  1. Read README.md (theory)                   │
│  2. Run examples.sql (practice)               │
│  3. Experiment (modify code)                  │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────┐
│  exercises.sql                │  Test skills
└───────────────────────────────┘
    ↓
┌───────────────────────────────┐
│  solutions.sql                │  Check answers
└───────────────────────────────┘
    ↓
CHAPTER COMPLETE! 🎉
```

---

## 🔖 File Naming Convention

All SQL scripts follow this pattern:

| Name | Purpose | Location |
|------|---------|----------|
| `complete-setup.sql` | One-time database setup | `00-setup/` |
| `examples.sql` | Lesson demonstrations | Each lesson folder |
| `exercises.sql` | Practice problems | `02-exercises/chapter-XX/` |
| `solutions.sql` | Exercise answers | `02-exercises/chapter-XX/` |

---

## 📝 File Content Structure

### examples.sql Files
```sql
-- ============================================================================
-- Lesson XX: Topic Name - Practical Examples
-- ============================================================================
-- Prerequisites and setup instructions

-- ============================================================================
-- SECTION 1: Basic Concepts
-- ============================================================================
-- Code examples with detailed comments

-- ============================================================================
-- SECTION 2: Intermediate Examples
-- ============================================================================
-- More complex demonstrations

-- ============================================================================
-- SECTION 3: Advanced/Real-World Examples
-- ============================================================================
-- Production-like scenarios

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
-- Code to reset/remove test data
```

### exercises.sql Files
```sql
-- ============================================================================
-- CHAPTER XX - PRACTICE EXERCISES
-- ============================================================================
-- Instructions and prerequisites

-- ============================================================================
-- EXERCISE SET 1: Topic Name
-- ============================================================================
-- Exercise description and requirements

-- YOUR CODE HERE:
/*
-- Student fills in solution here
*/

-- Repeat for all exercise sets
```

---

## 🎨 Visual Legend

| Icon | Meaning |
|------|---------|
| ⭐ | Important/recommended |
| ✅ | Complete and ready |
| 🔜 | Coming soon |
| ⚡ | Must run first |
| 📜 | SQL script file (.sql) |
| 📄 | Documentation file (.md) |
| 📁 | Directory/folder |

---

## 📞 Finding Files

### Windows File Explorer
```
C:\Users\YourName\Documents\GitHub\sql-training\01-lessons\02-creating-database\
```

### macOS Finder
```
/Users/YourName/Documents/GitHub/sql-training/01-lessons/02-creating-database/
```

### Linux/Command Line
```bash
cd ~/Documents/GitHub/sql-training/01-lessons/02-creating-database/
ls -la */examples.sql  # List all example scripts
```

---

## 🔍 Search for Scripts

### Find all .sql files
```bash
# Windows PowerShell
Get-ChildItem -Path . -Filter *.sql -Recurse

# macOS/Linux
find . -name "*.sql"
```

### Open in VS Code
```bash
# Open entire folder
code sql-training/

# Open specific file
code 01-lessons/02-creating-database/03-data-types-character/examples.sql
```

---

## 📦 What's Included Per Lesson

Each lesson with scripts contains:

1. **📄 README.md** (~3,000-5,000 lines)
   - Theory and concepts
   - Detailed explanations
   - Best practices
   - Visual examples
   - Quiz questions

2. **📜 examples.sql** (~400-800 lines)
   - Complete, runnable code
   - Multiple sections
   - Real-world scenarios
   - Detailed comments
   - Practice exercises

**Total per lesson:** ~4,000-6,000 lines of content!

---

## ✨ Script Features

Every SQL script includes:

- ✅ **Ready to run** - No setup needed (after complete-setup.sql)
- ✅ **Self-documenting** - Comments explain everything
- ✅ **Safe** - Can be run multiple times
- ✅ **Modular** - Run sections independently
- ✅ **Educational** - Designed for learning
- ✅ **Real-world** - Production-like examples
- ✅ **Complete** - No placeholders or TODOs

---

## 🎯 Recommended Order

1. ⚡ `00-setup/complete-setup.sql` (once)
2. 📜 `01-creating-mysql-database/examples.sql`
3. 📜 `03-data-types-character/examples.sql`
4. 📜 `04-data-types-numeric/examples.sql`
5. 📜 `05-data-types-temporal/examples.sql`
6. 📜 `exercises.sql` (practice everything)

---

**Questions?** See [HOW-TO-USE-SCRIPTS.md](01-lessons/02-creating-database/HOW-TO-USE-SCRIPTS.md)

**Ready to start?** See [QUICK-START.md](QUICK-START.md)
