# Chapter 03 Exercises - Query Primer

## 📚 Topics Covered
- SELECT clause and column aliases
- FROM clause and table aliases
- WHERE conditions (=, >, <, BETWEEN, IN, LIKE)
- NULL handling (IS NULL, IS NOT NULL, COALESCE)
- Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY and HAVING
- ORDER BY (ASC, DESC)
- Query execution order
- Calculated columns

## 📝 Practice Materials
- **[questions.md](questions.md)** - 16 practice questions with detailed solutions
  - 5 Easy questions
  - 6 Medium questions
  - 4 Hard questions
  - 1 Expert challenge question

## 🎯 Learning Objectives
By completing these exercises, you should be able to:
- Write effective SELECT queries
- Filter data with WHERE conditions
- Use aggregate functions correctly
- Group and filter groups with HAVING
- Sort results appropriately
- Handle NULL values
- Understand query execution order
- Create calculated columns

## 💡 Study Tips
1. Practice SELECT queries on the Sakila database
2. Understand WHERE vs HAVING (before vs after grouping)
3. Remember: Can't use column alias in WHERE, but can in ORDER BY
4. Test NULL behavior - it's different from empty strings or zero
5. Work through the gold layer queries in `04-projects/01-medallion-architecture/03-gold/`

## 🔗 Related Lessons
See `01-lessons/03-query-primer/` for detailed explanations.