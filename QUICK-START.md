# 🚀 Quick Start: Run Your First SQL Script

## ⚡ 5-Minute Setup

### Step 1: Install Software (If Not Already Installed)
- **SQL Server**: [Download Free Edition](https://www.microsoft.com/sql-server/sql-server-downloads)
- **SQL Client** (choose one):
  - [SQL Server Management Studio (SSMS)](https://aka.ms/ssmsfullsetup) - Windows only
  - [Azure Data Studio](https://aka.ms/azuredatastudio) - Works everywhere

### Step 2: Open Your SQL Client
- Launch SSMS or Azure Data Studio
- Connect to your SQL Server (usually `localhost` or `.`)

### Step 3: Run the Setup Script
1. **File → Open → File**
2. Navigate to: `01-lessons/02-creating-database/00-setup/complete-setup.sql`
3. Click **Execute** (F5)
4. Wait ~30 seconds for setup to complete

✅ **Done!** You now have a complete BookStore database with sample data.

---

## 🎓 Run Your First Lesson

### Lesson: Character Data Types

1. **Open the script:**
   ```
   01-lessons/02-creating-database/03-data-types-character/examples.sql
   ```

2. **Run it** (F5 or click Execute)

3. **See the results** in the Results pane

4. **Try modifying** some queries and run again!

---

## 📝 Try Your First Exercise

1. **Open:**
   ```
   02-exercises/chapter-02/exercises.sql
   ```

2. **Scroll to Exercise 1.1**

3. **Uncomment the code block** (remove `/*` and `*/`)

4. **Fill in your solution** where it says `-- Your solution here`

5. **Run it** to test your code

6. **Compare with solutions** (coming soon)

---

## 🎯 Learning Path

```
┌─────────────────────────────────────────┐
│ 1. Run complete-setup.sql               │  ← Do this ONCE
├─────────────────────────────────────────┤
│ 2. Read lesson README.md                │  ← Learn concepts
├─────────────────────────────────────────┤
│ 3. Run lesson examples.sql              │  ← See code in action
├─────────────────────────────────────────┤
│ 4. Experiment with the code             │  ← Modify and learn
├─────────────────────────────────────────┤
│ 5. Complete exercises.sql               │  ← Practice skills
├─────────────────────────────────────────┤
│ 6. Move to next lesson                  │  ← Repeat!
└─────────────────────────────────────────┘
```

---

## 💡 Pro Tips

### Tip 1: Run Sections at a Time
Highlight specific parts of a script and press F5 to run just that section.

### Tip 2: Use Comments
Add your own comments as you learn:
```sql
-- I learned that VARCHAR uses less space than CHAR!
SELECT LEN('test') AS Length;
```

### Tip 3: Save Your Experiments
Create a new file called `my-experiments.sql` to save interesting queries.

### Tip 4: Check Results
Always look at the Results pane after running queries to understand what happened.

### Tip 5: Read Error Messages
If something breaks, read the error message carefully - it tells you what went wrong!

---

## 🆘 Common Issues

### "Cannot open database BookStore"
**Solution:** Run the setup script first: `00-setup/complete-setup.sql`

### "Invalid object name 'Customers'"
**Solution:** Make sure you're using the BookStore database:
```sql
USE BookStore;
GO
```

### "There is already an object named 'X' in the database"
**Solution:** The script checks for this and drops existing objects. Just run it again!

### File path errors
**Solution:** Some scripts reference `C:\SQLData\`. Either:
- Create that folder: `mkdir C:\SQLData` (in PowerShell/CMD)
- OR modify the script to use a different path

---

## 🎉 You're Ready!

You now know how to:
- ✅ Run SQL scripts
- ✅ Execute code sections
- ✅ See results
- ✅ Practice with exercises

**Now go learn some SQL! 🚀**

---

## 📚 Reference

### Available Scripts (Chapter 02)

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `00-setup/complete-setup.sql` | Setup database | Once at start |
| `01-*/examples.sql` | Database creation | After setup |
| `03-*/examples.sql` | Character data types | After setup |
| `04-*/examples.sql` | Numeric data types | After setup |
| `05-*/examples.sql` | Date/time types | After setup |
| `exercises.sql` | Practice problems | After learning |

### Keyboard Shortcuts

| Action | SSMS | Azure Data Studio |
|--------|------|-------------------|
| Execute | F5 | F5 |
| New Query | Ctrl+N | Ctrl+N |
| Open File | Ctrl+O | Ctrl+O |
| Save | Ctrl+S | Ctrl+S |
| Comment | Ctrl+K, Ctrl+C | Ctrl+/ |
| Uncomment | Ctrl+K, Ctrl+U | Ctrl+/ |

---

**Need more help?** See [HOW-TO-USE-SCRIPTS.md](HOW-TO-USE-SCRIPTS.md) for detailed instructions!
