# DELETE vs TRUNCATE

## 🔄 What's the Difference?

Both **DELETE** and **TRUNCATE** remove rows from a table, but they work very differently!

---

## 📊 Quick Comparison

| Feature | DELETE | TRUNCATE |
|---------|--------|----------|
| **Speed** | Slow 🐢 | Fast ⚡ |
| **WHERE clause** | ✅ Yes | ❌ No |
| **Rollback** | ✅ Can undo | ❌ Can't undo |
| **Reset Auto ID** | ❌ No | ✅ Yes |
| **Triggers** | ✅ Fires | ❌ Doesn't fire |
| **Logs changes** | ✅ Yes | ❌ No |

---

## 💡 DELETE - Selective Removal

```sql
-- Delete SPECIFIC rows
DELETE FROM Products
WHERE Price < 50;

-- Can use WHERE clause
-- Logs each row deleted
-- Can rollback
-- Slow but safe
```

### DELETE Example
```
Before DELETE WHERE Price < 50:
┌────┬──────────┬───────┐
│ ID │ Product  │ Price │
├────┼──────────┼───────┤
│ 1  │ Mouse    │ 29.99 │ ← Will delete
│ 2  │ Keyboard │ 129   │ ← Stays
│ 3  │ Webcam   │ 149   │ ← Stays
└────┴──────────┴───────┘

After DELETE:
┌────┬──────────┬───────┐
│ ID │ Product  │ Price │
├────┼──────────┼───────┤
│ 2  │ Keyboard │ 129   │
│ 3  │ Webcam   │ 149   │
└────┴──────────┴───────┘
IDs 2 and 3 preserved!
```

---

## ⚡ TRUNCATE - Remove Everything

```sql
-- Remove ALL rows (no WHERE!)
TRUNCATE TABLE Products;

-- Can't use WHERE clause
-- Doesn't log individual rows
-- Can't rollback
-- Fast but dangerous
-- Resets auto-increment ID to 1
```

### TRUNCATE Example
```
Before TRUNCATE:
┌────┬──────────┬───────┐
│ ID │ Product  │ Price │
├────┼──────────┼───────┤
│ 1  │ Mouse    │ 29.99 │
│ 2  │ Keyboard │ 129   │
│ 3  │ Webcam   │ 149   │
└────┴──────────┴───────┘

After TRUNCATE:
┌────┬──────────┬───────┐
│ ID │ Product  │ Price │
├────┼──────────┼───────┤
│    │  (empty) │       │
└────┴──────────┴───────┘
All data gone! ID resets to 1!
```

---

## 🎯 When to Use Each

### Use DELETE when:
- ✅ Removing **specific rows** (using WHERE)
- ✅ Need to **rollback** if mistake
- ✅ Want to **keep** auto-increment ID sequence
- ✅ Working with **small** number of rows

### Use TRUNCATE when:
- ✅ Removing **ALL rows** from table
- ✅ Want to **reset** auto-increment ID to 1
- ✅ Need **fast** performance
- ✅ Don't need rollback (100% sure)
- ✅ Clearing test/temp data

---

## 💡 Examples

### DELETE with WHERE
```sql
-- Remove old sales
DELETE FROM Sales
WHERE SaleDate < '2024-01-01';
```

### DELETE ALL (slow but safe)
```sql
-- Remove all products (keeps ID sequence)
DELETE FROM Products;
```

### TRUNCATE ALL (fast but permanent)
```sql
-- Remove all products (resets ID to 1)
TRUNCATE TABLE Products;
```

---

## ⚠️ Foreign Key Warning

```sql
-- This FAILS if Sales references Products!
TRUNCATE TABLE Products;
-- Error: Cannot truncate table 'Products' because 
-- it is referenced by foreign key constraint

-- DELETE works even with foreign keys
DELETE FROM Products;
-- Success: Deletes rows respecting FK constraints
```

---

## 🎯 Key Takeaway

**DELETE** = Selective, safe, slow, can rollback
- Use when: Need WHERE clause or might need to undo

**TRUNCATE** = All rows, fast, permanent, resets IDs
- Use when: Clearing entire table and 100% sure

💡 **Rule of Thumb:** If you're hesitating, use DELETE!
