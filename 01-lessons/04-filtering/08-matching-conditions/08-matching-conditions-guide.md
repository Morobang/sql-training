# Lesson 08: Matching Conditions - Visual Guide

## What You'll Learn
- Pattern matching with LIKE operator
- Using wildcards (%, _, [], [^])
- Advanced text searching techniques
- Performance considerations

---

## Wildcard Characters

```
┌──────────┬───────────────────────────────────────────┐
│ Wildcard │              Meaning                      │
├──────────┼───────────────────────────────────────────┤
│    %     │  Any sequence of characters (0 or more)   │
│    _     │  Exactly one character                    │
│   []     │  Any single character within brackets     │
│   [^]    │  Any character NOT in brackets            │
└──────────┴───────────────────────────────────────────┘
```

---

## The % Wildcard

### Pattern: `LIKE 'J%'` (Starts with J)

```
Database: Sales.Customers

┌────────────┬────────────┬─────────────────┬──────────┐
│ FirstName  │  Pattern   │   'J%' Match?   │  Result  │
├────────────┼────────────┼─────────────────┼──────────┤
│ John       │    J...    │      YES        │    ✓     │
│ Jane       │    J...    │      YES        │    ✓     │
│ Jennifer   │    J.....  │      YES        │    ✓     │
│ Mike       │    M...    │      NO         │    ✗     │
│ Sarah      │    S....   │      NO         │    ✗     │
└────────────┴────────────┴─────────────────┴──────────┘
```

### Pattern: `LIKE '%son'` (Ends with 'son')

```
┌────────────┬────────────┬──────────────────┬──────────┐
│  LastName  │  Pattern   │  '%son' Match?   │  Result  │
├────────────┼────────────┼──────────────────┼──────────┤
│ Johnson    │   ...son   │      YES         │    ✓     │
│ Anderson   │   .....son │      YES         │    ✓     │
│ Smith      │   .....    │      NO          │    ✗     │
│ Wilson     │   ...son   │      YES         │    ✓     │
└────────────┴────────────┴──────────────────┴──────────┘
```

### Pattern: `LIKE '%Dell%'` (Contains 'Dell')

```
┌──────────────────┬────────────┬─────────────────┬──────────┐
│   ProductName    │  Pattern   │ '%Dell%' Match? │  Result  │
├──────────────────┼────────────┼─────────────────┼──────────┤
│ Dell Laptop      │  Dell...   │      YES        │    ✓     │
│ HP DellVision    │  ...Dell.. │      YES        │    ✓     │
│ SuperDell Pro    │  ....Dell..│      YES        │    ✓     │
│ HP Laptop        │  ........  │      NO         │    ✗     │
└──────────────────┴────────────┴─────────────────┴──────────┘
```

---

## The _ Wildcard (Underscore)

### Pattern: `LIKE 'J___'` (J + exactly 3 characters)

```
┌────────────┬──────────────┬───────────────┬──────────┐
│ FirstName  │   Pattern    │ 'J___' Match? │  Result  │
├────────────┼──────────────┼───────────────┼──────────┤
│ John       │    J + 3     │      YES      │    ✓     │
│ Jane       │    J + 3     │      YES      │    ✓     │
│ Jennifer   │    J + 7     │      NO       │    ✗     │
│ Jim        │    J + 2     │      NO       │    ✗     │
│ Mike       │    M + 3     │      NO       │    ✗     │
└────────────┴──────────────┴───────────────┴──────────┘

J___ means: J followed by EXACTLY 3 characters
```

### Pattern: `LIKE '_a%'` (2nd character is 'a')

```
┌────────────┬──────────────┬───────────────┬──────────┐
│ FirstName  │   Pattern    │  '_a%' Match? │  Result  │
├────────────┼──────────────┼───────────────┼──────────┤
│ Sarah      │   S-a-rah    │      YES      │    ✓     │
│ Daniel     │   D-a-niel   │      YES      │    ✓     │
│ Jake       │   J-a-ke     │      YES      │    ✓     │
│ John       │   J-o-hn     │      NO       │    ✗     │
│ Emily      │   E-m-ily    │      NO       │    ✗     │
└────────────┴──────────────┴───────────────┴──────────┘

_a% means: ANY character, then 'a', then anything
```

---

## Character Ranges with []

### Pattern: `LIKE '[ABC]%'` (Starts with A, B, or C)

```
┌────────────┬──────────────┬─────────────────┬──────────┐
│ FirstName  │ First Letter │ '[ABC]%' Match? │  Result  │
├────────────┼──────────────┼─────────────────┼──────────┤
│ Alice      │      A       │      YES        │    ✓     │
│ Bob        │      B       │      YES        │    ✓     │
│ Charlie    │      C       │      YES        │    ✓     │
│ David      │      D       │      NO         │    ✗     │
│ Emily      │      E       │      NO         │    ✗     │
└────────────┴──────────────┴─────────────────┴──────────┘
```

### Pattern: `LIKE '[AEIOU]%'` (Starts with vowel)

```
┌────────────┬──────────────┬────────────────────┬──────────┐
│ FirstName  │ First Letter │ '[AEIOU]%' Match?  │  Result  │
├────────────┼──────────────┼────────────────────┼──────────┤
│ Alice      │      A       │      YES (vowel)   │    ✓     │
│ Emily      │      E       │      YES (vowel)   │    ✓     │
│ Ian        │      I       │      YES (vowel)   │    ✓     │
│ Oliver     │      O       │      YES (vowel)   │    ✓     │
│ Bob        │      B       │      NO            │    ✗     │
│ Charlie    │      C       │      NO            │    ✗     │
└────────────┴──────────────┴────────────────────┴──────────┘
```

### Pattern: `LIKE '[0-9]%'` (Starts with number)

```
┌──────────────────┬──────────────┬──────────────────┬──────────┐
│   ProductName    │ First Char   │ '[0-9]%' Match?  │  Result  │
├──────────────────┼──────────────┼──────────────────┼──────────┤
│ 15-inch Monitor  │      1       │      YES         │    ✓     │
│ 24GB RAM         │      2       │      YES         │    ✓     │
│ Laptop Pro       │      L       │      NO          │    ✗     │
│ 500GB SSD        │      5       │      YES         │    ✓     │
└──────────────────┴──────────────┴──────────────────┴──────────┘
```

---

## Negated Ranges with [^]

### Pattern: `LIKE '[^AEIOU]%'` (Does NOT start with vowel)

```
┌────────────┬──────────────┬──────────────────────┬──────────┐
│ FirstName  │ First Letter │ '[^AEIOU]%' Match?   │  Result  │
├────────────┼──────────────┼──────────────────────┼──────────┤
│ Bob        │      B       │      YES (consonant) │    ✓     │
│ Charlie    │      C       │      YES (consonant) │    ✓     │
│ David      │      D       │      YES (consonant) │    ✓     │
│ Alice      │      A       │      NO (vowel)      │    ✗     │
│ Emily      │      E       │      NO (vowel)      │    ✗     │
└────────────┴──────────────┴──────────────────────┴──────────┘
```

### Pattern: `LIKE '[^A-M]%'` (Starts with N-Z)

```
┌────────────┬──────────────┬──────────────────┬──────────┐
│  LastName  │ First Letter │ '[^A-M]%' Match? │  Result  │
├────────────┼──────────────┼──────────────────┼──────────┤
│ Smith      │      S       │      YES (N-Z)   │    ✓     │
│ Wilson     │      W       │      YES (N-Z)   │    ✓     │
│ Johnson    │      J       │      NO (A-M)    │    ✗     │
│ Anderson   │      A       │      NO (A-M)    │    ✗     │
└────────────┴──────────────┴──────────────────┴──────────┘
```

---

## Complex Pattern Combinations

### Example 1: Two 'i' letters

```sql
WHERE ProductName LIKE '%i%i%'

┌──────────────────┬─────────────────────────────┬──────────┐
│   ProductName    │      Explanation            │  Result  │
├──────────────────┼─────────────────────────────┼──────────┤
│ Mini Projector   │  M(i)n(i) - 2 i's          │    ✓     │
│ WiFi Router      │  W(i)F(i) - 2 i's          │    ✓     │
│ Monitor          │  Only 1 'i'                 │    ✗     │
│ Printer          │  Pr(i)nter - only 1 'i'    │    ✗     │
└──────────────────┴─────────────────────────────┴──────────┘
```

### Example 2: Product code pattern (XX999...)

```sql
WHERE ProductName LIKE '[A-Z][A-Z][0-9][0-9][0-9]%'

┌──────────────────┬─────────────────────────────┬──────────┐
│   ProductName    │      Pattern Check          │  Result  │
├──────────────────┼─────────────────────────────┼──────────┤
│ AB123-Monitor    │  A B 1 2 3 - Match!        │    ✓     │
│ XY999-Pro        │  X Y 9 9 9 - Match!        │    ✓     │
│ A1234-Device     │  A [1] - 2nd not letter    │    ✗     │
│ ABC12-Product    │  A B C 1 2 - 3 letters     │    ✗     │
└──────────────────┴─────────────────────────────┴──────────┘

Pattern: [Letter][Letter][Digit][Digit][Digit]...
```

---

## Visual: AND vs OR with LIKE

### AND (Both patterns must match)

```sql
WHERE ProductName LIKE '%Pro%' AND ProductName LIKE '%15%'

┌──────────────────┬──────────────┬─────────────┬──────────┐
│   ProductName    │ Contains Pro?│ Contains 15?│  Result  │
├──────────────────┼──────────────┼─────────────┼──────────┤
│ MacBook Pro 15   │     YES      │     YES     │    ✓     │
│ Surface Pro 13   │     YES      │     NO      │    ✗     │
│ iPad 15 Air      │     NO       │     YES     │    ✗     │
│ Dell Laptop      │     NO       │     NO      │    ✗     │
└──────────────────┴──────────────┴─────────────┴──────────┘

Only products with BOTH "Pro" AND "15" match!
```

### OR (Either pattern can match)

```sql
WHERE ProductName LIKE '%Dell%' OR ProductName LIKE '%HP%'

┌──────────────────┬──────────────┬─────────────┬──────────┐
│   ProductName    │ Contains Dell│ Contains HP?│  Result  │
├──────────────────┼──────────────┼─────────────┼──────────┤
│ Dell Laptop      │     YES      │     NO      │    ✓     │
│ HP Printer       │     NO       │     YES     │    ✓     │
│ Dell HP Monitor  │     YES      │     YES     │    ✓     │
│ Lenovo ThinkPad  │     NO       │     NO      │    ✗     │
└──────────────────┴──────────────┴─────────────┴──────────┘

Products with EITHER "Dell" OR "HP" (or both) match!
```

---

## Escaping Special Characters

What if you need to search for literal %, _, [, or ]?

### Searching for literal % character

```sql
WHERE ProductName LIKE '%!%%' ESCAPE '!'

┌──────────────────┬─────────────────────────────┬──────────┐
│   ProductName    │      Explanation            │  Result  │
├──────────────────┼─────────────────────────────┼──────────┤
│ 20% Off Sale     │  Contains literal %         │    ✓     │
│ 100% Guarantee   │  Contains literal %         │    ✓     │
│ Laptop Pro       │  No % character             │    ✗     │
└──────────────────┴─────────────────────────────┴──────────┘

Pattern: %!%% means "anything, then literal %, then anything"
         ^ ESCAPE CHARACTER
```

### Searching for literal _ character

```sql
WHERE ProductName LIKE '%!_%' ESCAPE '!'

┌──────────────────┬─────────────────────────────┬──────────┐
│   ProductName    │      Explanation            │  Result  │
├──────────────────┼─────────────────────────────┼──────────┤
│ 15_inch_Monitor  │  Contains literal _         │    ✓     │
│ Part_A123        │  Contains literal _         │    ✓     │
│ Laptop Pro       │  No _ character             │    ✗     │
└──────────────────┴─────────────────────────────┴──────────┘
```

---

## Performance Visualization

### ❌ SLOW: Leading wildcard (can't use index)

```sql
WHERE ProductName LIKE '%Laptop'

Database must scan EVERY row:
┌─────────────────────────────────────┐
│  Full Table Scan (SLOW)             │
│  ┌──────────────────┐               │
│  │ Row 1: Check all │ ──> Scan      │
│  │ Row 2: Check all │ ──> Scan      │
│  │ Row 3: Check all │ ──> Scan      │
│  │ ...              │               │
│  │ Row 1000: Check  │ ──> Scan      │
│  └──────────────────┘               │
│  ⏱️ Time: 1000 ms                   │
└─────────────────────────────────────┘
```

### ✅ FAST: No leading wildcard (can use index)

```sql
WHERE ProductName LIKE 'Laptop%'

Database can use index:
┌─────────────────────────────────────┐
│  Index Seek (FAST)                  │
│  ┌──────────────────┐               │
│  │ Index: L...      │               │
│  │   └─> Laptop     │ ──> Found!    │
│  │   └─> LaptopPro  │ ──> Found!    │
│  │                  │               │
│  └──────────────────┘               │
│  ⏱️ Time: 10 ms (100x faster!)      │
└─────────────────────────────────────┘
```

---

## Common Pattern Reference

```
┌─────────────────────┬──────────────────────────────────┐
│      Pattern        │           Matches                │
├─────────────────────┼──────────────────────────────────┤
│  LIKE 'A%'          │  Starts with A                   │
│  LIKE '%z'          │  Ends with z                     │
│  LIKE '%abc%'       │  Contains abc                    │
│  LIKE '_a%'         │  Second character is 'a'         │
│  LIKE '____'        │  Exactly 4 characters            │
│  LIKE '[ABC]%'      │  Starts with A, B, or C          │
│  LIKE '[A-Z]%'      │  Starts with any letter          │
│  LIKE '[0-9]%'      │  Starts with digit               │
│  LIKE '[^0-9]%'     │  Does NOT start with digit       │
│  LIKE '%!%%' ESCAPE │  Contains literal %              │
└─────────────────────┴──────────────────────────────────┘
```

---

## Key Takeaways

```
✅ DO:
  • Use LIKE for simple pattern matching
  • Avoid leading wildcards when possible (performance!)
  • Use [] for character sets
  • Use [^] for exclusions
  • Remember _ = exactly one character

❌ DON'T:
  • Overuse LIKE with leading wildcards
  • Forget case sensitivity (default: insensitive)
  • Use LIKE for large text searches (use full-text instead)
  • Forget to escape special characters
```

---

## Quick Wildcard Guide

```
% = Zero or more characters
    'A%'    → A, AB, ABC, ABCD, ...
    '%Z'    → Z, AZ, ABZ, ABCZ, ...
    '%X%'   → X, AXB, ABXCD, ...

_ = Exactly one character
    'A_'    → AB, AC, AD (not A or ABC!)
    '_B'    → AB, BB, CB (exactly 2 chars)
    'A__'   → ABC, ADE (exactly 3 chars)

[] = One character from set
    '[ABC]' → A, B, or C (exactly one)
    '[A-Z]' → Any single uppercase letter
    '[0-9]' → Any single digit

[^] = One character NOT in set
    '[^0-9]' → Any non-digit
    '[^AEIOU]' → Any non-vowel
```

---

**Next:** [Lesson 09 - NULL Handling](../09-null-handling/09-null-handling-guide.md)
