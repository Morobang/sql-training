# Chapter 05 Exercises - Querying Multiple Tables

## 📚 Topics Covered
- What is a JOIN and why use it?
- INNER JOIN (intersection)
- LEFT JOIN (all from left table + matches)
- RIGHT JOIN (all from right table + matches)
- CROSS JOIN (Cartesian product)
- Self-joins (table joined to itself)
- Multiple JOINs (chaining tables)
- JOIN with aggregates
- Multiple join conditions
- Finding missing relationships
- Recursive CTEs for hierarchies

## 📝 Practice Materials
- **[questions.md](questions.md)** - 13 practice questions with detailed solutions
  - 3 Easy questions
  - 5 Medium questions
  - 3 Hard questions
  - 2 Expert challenge questions

## 🎯 Learning Objectives
By completing these exercises, you should be able to:
- Choose the correct JOIN type for your needs
- Combine data from multiple tables
- Use self-joins for hierarchical data
- Find missing relationships with LEFT JOIN + IS NULL
- Chain multiple JOINs correctly
- Aggregate data across joined tables
- Apply multiple join conditions
- Work with recursive queries

## 💡 Study Tips
1. Visualize JOINs with Venn diagrams
2. INNER JOIN = only matches; LEFT JOIN = all from left + matches
3. Use table aliases (especially for self-joins)
4. LEFT JOIN + WHERE IS NULL finds missing data
5. All JOINs must be LEFT to preserve outer rows
6. Study the Data Vault link and satellite loading in `04-projects/02-datavault-banking/`
7. Practice with multi-table views in `04-projects/02-datavault-banking/04-business-vault/`

## 🔗 Related Lessons
See `01-lessons/05-querying-multiple-tables/` for detailed explanations.
