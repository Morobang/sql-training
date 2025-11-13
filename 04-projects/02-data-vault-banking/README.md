# Project 2: Data Vault 2.0 - Banking Compliance System

## Overview
Build a **Data Vault 2.0** warehouse for a banking system. This architecture is perfect for industries requiring **strict audit trails, regulatory compliance, and historical tracking** (banking, healthcare, insurance).

## What You'll Learn
- **Hub tables**: Core business entities (Customer, Account, Transaction)
- **Link tables**: Relationships between entities
- **Satellite tables**: Descriptive attributes that change over time
- **Historical tracking**: Track every change with timestamps
- **Audit compliance**: Perfect for SOX, GDPR, banking regulations

## Why Data Vault vs Medallion?

| Feature | Medallion | Data Vault 2.0 |
|---------|-----------|----------------|
| **Purpose** | Data quality progression | Historical tracking & compliance |
| **Best For** | Analytics & BI | Regulatory compliance & audit |
| **Change Tracking** | Snapshot based | Every change tracked |
| **Query Complexity** | Simple (1-3 joins) | Complex (5+ joins) |
| **Audit Trail** | Limited | Complete |
| **Regulatory** | Good | Excellent |

## Business Case
You're building a compliance data warehouse for **SecureBank**. Every customer interaction, account change, and transaction must be tracked for:
- **Regulatory compliance** (SOX, GDPR, Basel III)
- **Fraud detection** (pattern analysis over time)
- **Audit requirements** (7-year history retention)
- **Customer dispute resolution** (prove account state at any point in time)

## Data Vault Architecture

### Core Components

#### 1. Hubs (Business Keys)
Store unique business identifiers
- `hub_customer` - Unique customers
- `hub_account` - Unique accounts
- `hub_transaction` - Unique transactions
- `hub_branch` - Unique bank branches

#### 2. Links (Relationships)
Connect hubs together
- `link_customer_account` - Customer ↔ Account relationships
- `link_account_transaction` - Account ↔ Transaction relationships
- `link_account_branch` - Account ↔ Branch relationships

#### 3. Satellites (Descriptive Data)
Store changing attributes
- `sat_customer_demographics` - Name, address, phone (changes over time)
- `sat_customer_status` - Account status, credit score (changes frequently)
- `sat_account_details` - Balance, interest rate, type
- `sat_transaction_details` - Amount, description, category

## Project Structure

### Phase 1: Foundation (Hubs)
1. `01-data-vault-setup.md` - Understand Data Vault concepts
2. `02-create-hubs.sql` - Create hub tables (business keys)
3. `03-load-hub-customer.sql` - Load unique customers
4. `04-load-hub-account.sql` - Load unique accounts
5. `05-load-hub-transaction.sql` - Load unique transactions

### Phase 2: Relationships (Links)
6. `06-create-links.sql` - Create link tables
7. `07-load-link-customer-account.sql` - Connect customers to accounts
8. `08-load-link-account-transaction.sql` - Connect accounts to transactions
9. `09-link-queries.sql` - Query relationship history

### Phase 3: Attributes (Satellites)
10. `10-create-satellites.sql` - Create satellite tables
11. `11-load-sat-customer-demographics.sql` - Track customer info changes
12. `12-load-sat-account-details.sql` - Track account changes
13. `13-temporal-queries.sql` - Query data "as of" any date

### Phase 4: Business Intelligence
14. `14-create-business-vault.sql` - Build query-friendly views
15. `15-compliance-reports.sql` - Regulatory reporting queries
16. `16-audit-trail.sql` - Track who changed what when

## Real-World Example

### Scenario: Customer Changes Address

**Traditional Database:**
```sql
UPDATE customers 
SET address = '456 New St' 
WHERE customer_id = 'C001';
```
❌ **Problem**: Old address is lost forever!

**Data Vault Approach:**
```sql
-- Hub (never changes)
hub_customer: 
  customer_hash_key, customer_id, load_date

-- Satellite (tracks all changes)
sat_customer_demographics:
  customer_hash_key, load_date, address
  ---------------------------------------
  HASH123, 2024-01-01, '123 Old St'
  HASH123, 2024-06-15, '456 New St'  ← New record added
```
✅ **Benefit**: Complete history preserved! Can query address at any point in time.

## Data Vault Patterns

### Pattern 1: Slowly Changing Dimensions (SCD Type 2)
Every change creates a new satellite record
```sql
SELECT address 
FROM sat_customer_demographics
WHERE customer_hash_key = @key
  AND load_date <= '2024-03-01'  -- What was address on this date?
ORDER BY load_date DESC
LIMIT 1;
```

### Pattern 2: Point-in-Time Queries
See complete entity state at any historical moment
```sql
-- Get customer profile as it appeared on 2024-01-15
SELECT 
    h.customer_id,
    d.full_name,
    d.address,
    s.status,
    s.credit_score
FROM hub_customer h
JOIN sat_customer_demographics d ON h.customer_hash_key = d.customer_hash_key
JOIN sat_customer_status s ON h.customer_hash_key = s.customer_hash_key
WHERE d.load_date <= '2024-01-15' 
  AND s.load_date <= '2024-01-15';
```

### Pattern 3: Audit Trail
Who changed what and when
```sql
SELECT 
    load_date AS change_date,
    record_source AS changed_by,
    address AS new_address
FROM sat_customer_demographics
WHERE customer_hash_key = @key
ORDER BY load_date;
```

## Benefits of Data Vault

### ✅ **Complete Audit Trail**
Every change tracked with timestamp and source

### ✅ **Regulatory Compliance**
Prove data state at any point in time (required for SOX, GDPR)

### ✅ **Graceful Schema Evolution**
Add new attributes without changing existing structure

### ✅ **Parallel Loading**
Hubs, links, satellites can be loaded independently

### ✅ **No Data Loss**
Never UPDATE or DELETE - only INSERT

## Challenges & Solutions

### Challenge: Complex Queries
Data Vault requires many joins (5-10 tables)

**Solution**: Create Business Vault views
```sql
CREATE VIEW vw_customer_360 AS
SELECT 
    h.customer_id,
    d.full_name,
    d.address,
    s.status,
    COUNT(l.account_hash_key) AS account_count
FROM hub_customer h
JOIN sat_customer_demographics d ON h.customer_hash_key = d.customer_hash_key
JOIN sat_customer_status s ON h.customer_hash_key = s.customer_hash_key
LEFT JOIN link_customer_account l ON h.customer_hash_key = l.customer_hash_key;
```

### Challenge: Storage Overhead
Tracking every change uses more space

**Solution**: Use for critical compliance data only, not all data

## Industry Use Cases

### Banking (This Project)
- **Regulatory**: SOX compliance, Basel III reporting
- **Fraud**: Historical pattern analysis
- **Audit**: Account state at dispute date

### Healthcare
- **HIPAA**: Patient record access tracking
- **Clinical**: Treatment history timeline
- **Billing**: Claim status progression

### Insurance
- **Claims**: Policy changes during claim period
- **Underwriting**: Risk assessment history
- **Compliance**: State regulatory reporting

## Expected Outcomes

By the end of this project:
1. ✅ Understand Hub-Link-Satellite architecture
2. ✅ Track every data change with timestamps
3. ✅ Query data "as of" any historical date
4. ✅ Build audit trail reports
5. ✅ Understand when to use Data Vault vs other patterns

## Time Estimate
- Phase 1 (Hubs): 2-3 hours
- Phase 2 (Links): 2 hours
- Phase 3 (Satellites): 3-4 hours
- Phase 4 (Business Vault): 2 hours
- **Total**: 9-11 hours

## Prerequisites
- Complete Medallion Architecture project
- Understand JOINs and GROUP BY
- Basic knowledge of hashing (MD5, SHA)

## Next Steps
After this project:
- **Project 3**: Kimball Star Schema (simpler analytics)
- **Project 4**: CDC Pipeline (real-time Data Vault loading)

Start with `01-data-vault-setup.md`!
