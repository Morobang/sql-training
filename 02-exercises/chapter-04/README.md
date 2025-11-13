# Chapter 04 Exercises - Filtering

## 📚 Topics Covered
- Condition evaluation (AND, OR, NOT)
- Using parentheses for grouping
- NOT operator
- Range conditions (BETWEEN, comparison operators)
- Membership conditions (IN, NOT IN)
- Pattern matching (LIKE, wildcards %, _)
- Regular expressions (REGEXP)
- NULL handling (IS NULL, IS NOT NULL, COALESCE)
- Case-insensitive searching
- Complex multi-condition filters

## 📝 Practice Materials
- **[questions.md](questions.md)** - 13 practice questions with detailed solutions
  - 2 Easy questions
  - 7 Medium questions
  - 3 Hard questions
  - 1 Expert challenge question

## 🎯 Learning Objectives
By completing these exercises, you should be able to:
- Combine conditions with AND/OR/NOT
- Use parentheses for correct evaluation order
- Filter with range and membership operators
- Match patterns with LIKE and wildcards
- Apply regular expressions
- Handle NULL values correctly
- Build flexible search queries
- Optimize filter performance

## 💡 Study Tips
1. Always use parentheses for clarity with AND/OR
2. BETWEEN is inclusive (includes both endpoints)
3. Can't use = or != with NULL (use IS NULL / IS NOT NULL)
4. % = any characters, _ = exactly one character
5. Test your WHERE clauses with SELECT COUNT(*) first
6. Practice with the silver layer cleaning queries in `04-projects/01-medallion-architecture/02-silver/`

## 🔗 Related Lessons
See `01-lessons/04-filtering/` for detailed explanations.
