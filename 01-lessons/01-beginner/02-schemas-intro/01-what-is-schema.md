# What is a Schema?

## 📁 Simple Explanation

A **schema** is like a **folder** inside a database.

Just like you organize files on your computer into folders, schemas organize tables into groups.

---

## 🏗️ Visual Example

```
Database: TechStore
├── Schema: dbo (default)
│   ├── Table: Products
│   └── Table: Customers
│
└── Schema: Sales
    ├── Table: Orders
    └── Table: Invoices
```

---

## ❓ Why Use Schemas?

✅ **Organization** - Keep related tables together  
✅ **Clarity** - Separate different parts of your application  
✅ **Security** - Control who can access which schemas  

---

## 👶 For Beginners

**Good news!** We'll use the default schema called **`dbo`**

You **don't need to type it** - SQL Server uses it automatically!

```sql
-- These are the SAME thing:
SELECT * FROM Products;
SELECT * FROM dbo.Products;
```

---

## 🎯 Key Takeaway

**Schema = Container for tables**

For this beginner course, everything goes in the **`dbo`** schema.  
You'll learn custom schemas in intermediate lessons!
