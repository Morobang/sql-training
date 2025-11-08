# SQL Unplugged

## 🎯 Learning Objectives

- Practice thinking about database problems conceptually
- Develop data modeling intuition
- Learn to plan before coding
- Build mental models for SQL solutions

---

## What is "SQL Unplugged"?

> **SQL Unplugged** means thinking about database problems **without writing code** - just using pen, paper, and your brain!

**Why This Matters:**
- 💭 Understand the problem before rushing to code
- 📝 Design better databases
- 🎯 Write better queries on first try
- 🧠 Develop database thinking skills

**Like a chess player thinking moves ahead, think database design ahead!**

---

## Exercise 1: Real-World to Database

### Scenario: University System

**Real World:**
- Students enroll in courses
- Professors teach courses
- Courses have schedules
- Students get grades

**Your Task (No Code!):**

1. **Identify Entities (Things/Nouns)**
   - What are the main "things" in this system?
   - Which ones need their own tables?

2. **Identify Attributes (Properties)**
   - What information do we need about each entity?
   - What are the characteristics?

3. **Identify Relationships**
   - How do entities connect?
   - One-to-many? Many-to-many?

---

### Solution Discussion (Think First!)

**Entities:**
- Students
- Professors
- Courses
- Enrollments (junction table)
- Departments

**Attributes:**

*Students:*
- student_id (PK)
- first_name
- last_name
- email
- date_of_birth
- major

*Professors:*
- professor_id (PK)
- first_name
- last_name
- email
- department_id (FK)

*Courses:*
- course_id (PK)
- course_code (e.g., CS101)
- course_name
- credits
- professor_id (FK)

*Enrollments:*
- student_id (FK)
- course_id (FK)
- semester
- grade
- (Composite PK: student_id + course_id)

**Relationships:**
- One student → Many enrollments (1:N)
- One course → Many enrollments (1:N)
- Students ↔ Courses (M:N via enrollments)
- One professor → Many courses (1:N)
- One department → Many professors (1:N)

---

## Exercise 2: Query Planning

### Scenario Question

**Question:** "Show me all students who got an A in any Computer Science course last semester"

**Before Writing SQL, Think:**

1. **What tables do I need?**
   - Students (for student info)
   - Courses (to filter Computer Science)
   - Enrollments (for grades and semester)

2. **How are they connected?**
   - Students → Enrollments (student_id)
   - Courses → Enrollments (course_id)

3. **What filters do I need?**
   - grade = 'A'
   - semester = 'Fall 2024'
   - course department = 'Computer Science'

4. **What do I want to show?**
   - Student name
   - Course name
   - Grade

---

### Mental SQL (Pseudo-query)

```
SELECT student name, course name, grade
FROM students JOIN enrollments JOIN courses
WHERE grade = 'A'
  AND semester = last semester
  AND course is Computer Science
```

**Now writing actual SQL is easy! You've already solved it mentally.**

---

## Exercise 3: Spotting Bad Design

### Bad Design Example

```
Table: orders
┌──────────┬───────────────┬────────────┬─────────┬───────────┐
│ order_id │ customer_name │ product1   │ price1  │ product2  │
├──────────┼───────────────┼────────────┼─────────┼───────────┤
│ 1        │ John Smith    │ Laptop     │ 999     │ Mouse     │
│ 2        │ Jane Doe      │ Phone      │ 699     │ NULL      │
│ 3        │ Mike Chen     │ Monitor    │ 299     │ Keyboard  │
└──────────┴───────────────┴────────────┴─────────┴───────────┘
```

**Problems (Think About It!):**

1. **What if a customer orders 3 products?** 
   - Need product3, price3 columns? Where does it end?

2. **What if we want to list all products sold?**
   - Complex! Need to UNION product1 and product2 columns

3. **Redundant customer information**
   - Customer name repeated for each order

4. **Can't query products easily**
   - Products spread across multiple columns

---

### Better Design (Mental Model)

**Tables:**

```
customers
- customer_id (PK)
- customer_name
- email

orders
- order_id (PK)
- customer_id (FK)
- order_date
- total_amount

order_items
- order_item_id (PK)
- order_id (FK)
- product_id (FK)
- quantity
- price

products
- product_id (PK)
- product_name
- current_price
- category
```

**Benefits:**
- ✅ Unlimited products per order
- ✅ Easy to query products
- ✅ No redundant data
- ✅ Flexible and maintainable

---

## Exercise 4: Think Through the Query

### Scenario: E-Commerce Analytics

**Question:** "What are the top 5 selling products in the last 30 days?"

**Mental Checklist:**

1. **What defines "selling"?**
   - Quantity sold? 
   - Revenue generated?
   - Number of orders?

2. **What time range?**
   - Last 30 days from today
   - Need order_date filter

3. **What tables?**
   - products (for product name)
   - order_items (for quantities/prices)
   - orders (for order date)

4. **How to aggregate?**
   - GROUP BY product
   - SUM quantity or SUM (quantity * price)

5. **How to get top 5?**
   - ORDER BY total DESC
   - TOP 5 or LIMIT 5

**Mental Query Flow:**
```
1. Join products with order_items
2. Join with orders to get date
3. Filter: last 30 days
4. Group by product
5. Sum quantities
6. Sort by total descending
7. Take top 5
```

---

## Exercise 5: Data Integrity Thinking

### Scenario: Banking System

**Question:** "A customer transfers $500 from Account A to Account B"

**Think Through the Risks:**

1. **What if the debit happens but not the credit?**
   - $500 vanishes!
   - Customer loses money

2. **What if the credit happens but not the debit?**
   - $500 created from nothing!
   - Bank loses money

3. **What if another transaction reads balances during transfer?**
   - Sees incorrect intermediate state
   - Could make wrong decisions

**Solution Concepts (No Code):**

1. **Use a transaction**
   - BEGIN
   - Debit Account A
   - Credit Account B
   - COMMIT (or ROLLBACK if error)

2. **Atomic operation**
   - Both updates or neither

3. **Locking**
   - Lock both accounts during transfer
   - Prevent concurrent modifications

**This is ACID thinking!**

---

## Exercise 6: Normalization Puzzle

### Unnormalized Data

```
employee_skills
┌──────────┬───────────────┬────────────────────────────┐
│ emp_id   │ emp_name      │ skills                     │
├──────────┼───────────────┼────────────────────────────┤
│ 1        │ Alice         │ SQL, Python, Java          │
│ 2        │ Bob           │ JavaScript, HTML, CSS      │
│ 3        │ Carol         │ SQL, Excel                 │
└──────────┴───────────────┴────────────────────────────┘
```

**Problems:**
- Can't easily search for "who knows SQL?"
- Can't validate skill names
- Can't track skill levels
- Violates 1NF (non-atomic values)

**Think: How Would You Normalize?**

---

### Better Design

**employees**
```
┌──────────┬───────────────┐
│ emp_id   │ emp_name      │
├──────────┼───────────────┤
│ 1        │ Alice         │
│ 2        │ Bob           │
│ 3        │ Carol         │
└──────────┴───────────────┘
```

**skills**
```
┌──────────┬─────────────┐
│ skill_id │ skill_name  │
├──────────┼─────────────┤
│ 1        │ SQL         │
│ 2        │ Python      │
│ 3        │ Java        │
│ 4        │ JavaScript  │
└──────────┴─────────────┘
```

**employee_skills (junction table)**
```
┌──────────┬──────────┬──────────────┐
│ emp_id   │ skill_id │ skill_level  │
├──────────┼──────────┼──────────────┤
│ 1        │ 1        │ Expert       │
│ 1        │ 2        │ Intermediate │
│ 1        │ 3        │ Beginner     │
│ 2        │ 4        │ Expert       │
│ 3        │ 1        │ Intermediate │
└──────────┴──────────┴──────────────┘
```

**Benefits:**
- ✅ Easy to search by skill
- ✅ Can add skill levels
- ✅ Can add more skills without changing structure
- ✅ Atomic values (1NF)

---

## Exercise 7: Performance Thinking

### Scenario: Slow Query

**Problem:** "This query takes 5 minutes!"

```sql
SELECT c.customer_name, SUM(o.total) 
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name
```

**Think: Why Might It Be Slow?**

1. **No index on order_date?**
   - Scanning entire orders table

2. **Millions of orders?**
   - Large dataset

3. **No index on customer_id?**
   - Slow joins

**Mental Solutions:**

1. **Add index on order_date**
   - Fast filter

2. **Add index on customer_id**
   - Fast joins

3. **Consider if we need all customers**
   - Maybe just active customers?

4. **Could we cache this?**
   - Recalculate hourly instead of real-time?

**Performance thinking before writing queries saves hours!**

---

## Exercise 8: Requirements Analysis

### Business Request

**Request:** "We need a report showing our best customers"

**Questions to Ask (Before Writing SQL):**

1. **What defines "best"?**
   - Total revenue?
   - Number of orders?
   - Recent activity?
   - Profit margin?

2. **What time period?**
   - All time?
   - Last year?
   - Last quarter?

3. **How many customers?**
   - Top 10?
   - Top 100?
   - All above threshold?

4. **What information to show?**
   - Name only?
   - Contact info?
   - Purchase history?

5. **How often needed?**
   - One-time analysis?
   - Daily report?
   - Real-time dashboard?

**Good requirements = Good database design = Good queries!**

---

## Mental Modeling Tips

### 1. Draw It Out

```
┌─────────┐         ┌─────────┐
│Customer │──1:N────│ Orders  │
└─────────┘         └─────────┘
                          │
                          │ 1:N
                          │
                     ┌──────────┐
                     │OrderItems│
                     └──────────┘
                          │
                          │ N:1
                          │
                     ┌─────────┐
                     │Products │
                     └─────────┘
```

---

### 2. Use Real Examples

Instead of abstract thinking, use concrete data:

```
Customer: John Smith
Orders: #101, #102, #103
Order #101: Laptop ($999), Mouse ($29)
```

---

### 3. Think "What If?"

- What if we have a million rows?
- What if two users update simultaneously?
- What if the value is NULL?
- What if we add a new requirement?

---

### 4. Question Everything

- Why this structure?
- Is there a better way?
- What are the trade-offs?
- How will this scale?

---

## 🧠 Key Takeaways

1. **Think before you code** - planning saves time
2. **Draw diagrams** - visual thinking helps
3. **Identify entities and relationships** - foundation of design
4. **Consider edge cases** - what if scenarios
5. **Think about performance** - indexes, query optimization
6. **Ask questions** - clarify requirements
7. **Practice mental modeling** - build intuition

---

## 📝 Practice Exercises

Try these without writing SQL:

1. **Library System**
   - Design tables for books, members, loans
   - What relationships exist?

2. **Social Media**
   - Model users, posts, comments, likes
   - How would you handle followers?

3. **Restaurant**
   - Tables, orders, menu items, ingredients
   - How to track inventory?

4. **Hospital**
   - Patients, doctors, appointments, prescriptions
   - What about privacy/security?

---

## ⏭️ Next Lesson

Continue with: **[11 - Test Your Knowledge](../11-test-your-knowledge/)** - Quiz yourself on Chapter 01 concepts!

---

## 💡 Remember

> "Hours of planning can save weeks of coding"

**The best SQL developers spend more time thinking than typing!**
