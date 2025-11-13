# Project 2: Data Vault 2.0 - Banking Compliance System

## Overview
Build a **Data Vault 2.0** warehouse for a banking system using **professional schema-based organization**. This architecture is perfect for industries requiring **strict audit trails, regulatory compliance, and historical tracking** (banking, healthcare, insurance).

## ✨ Architecture Highlights

This project uses **SQL Server schemas** for proper Data Vault layer separation:

```sql
SecureBank_DataVault (Database)
├── raw schema         -- Staging area for source data
├── dv_hub schema      -- Business keys (immutable)
├── dv_link schema     -- Relationships between entities
├── dv_sat schema      -- Descriptive attributes (temporal)
├── business_vault     -- Query-friendly views
└── metadata schema    -- Pipeline tracking & audit
```

**Production-Ready Features:**
- ✅ Schema-based organization (dv_hub.hub_customer, dv_sat.sat_customer_demographics)
- ✅ MD5 hash keys for business key management
- ✅ SCD Type 2 for complete history tracking
- ✅ Metadata tracking with pipeline runs and data lineage
- ✅ Compliance-ready reporting (SOX, GDPR, Basel III)

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

### Phase 0: Setup
- `00-setup-database.sql` - **NEW!** Creates SecureBank_DataVault database with 6 schemas, metadata tracking, and hash key functions

### Phase 1: Hubs (Foundation)
Navigate to `01-hubs/`:
1. `01-create-hubs.sql` - Create hub tables (`dv_hub.hub_customer`, `dv_hub.hub_account`, `dv_hub.hub_transaction`, `dv_hub.hub_branch`)
2. `02-generate-sample-data.sql` - Generate 63K+ realistic banking records (customers, accounts, transactions, branches)
3. `03-load-hubs.sql` - Load business keys into hubs with MD5 hash generation

**Hubs Created:** `dv_hub.hub_customer`, `dv_hub.hub_account`, `dv_hub.hub_transaction`, `dv_hub.hub_branch`

### Phase 2: Links (Relationships)
Navigate to `02-links/`:
1. `01-create-links.sql` - Create link tables (`dv_link.link_customer_account`, `dv_link.link_account_transaction`, `dv_link.link_account_branch`)
2. `02-load-links.sql` - Load relationships with composite hash keys

**Links Created:** `dv_link.link_customer_account`, `dv_link.link_account_transaction`, `dv_link.link_account_branch`

### Phase 3: Satellites (Attributes)
Navigate to `03-satellites/`:
1. `01-create-satellites.sql` - Create satellite tables with SCD Type 2 structure
2. `02-load-satellites.sql` - Load descriptive attributes with hash diff detection

**Satellites Created:** `dv_sat.sat_customer_demographics`, `dv_sat.sat_customer_status`, `dv_sat.sat_account_details`, `dv_sat.sat_transaction_details`, `dv_sat.sat_branch_info`

### Phase 4: Business Vault (Query Layer)
Navigate to `04-business-vault/`:
1. `01-create-views.sql` - Create query-friendly views (customer 360, account details, transaction history, audit trail)
2. `02-compliance-reports.sql` - Regulatory compliance reports (SOX, GDPR, Basel III, fraud detection)

**Views Created:** `business_vault.vw_customer_360`, `business_vault.vw_account_details`, `business_vault.vw_transaction_history`, `business_vault.vw_customer_audit_trail`

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

## How to Complete This Project

### Step 0: Database Setup (NEW!)
```sql
-- Run this FIRST to create database and schemas
00-setup-database.sql
```
Creates:
- `SecureBank_DataVault` database
- 6 schemas: `raw`, `dv_hub`, `dv_link`, `dv_sat`, `business_vault`, `metadata`
- Metadata tracking tables
- Hash key generator functions

### Step 1: Build Foundation (Hubs)
```
cd 01-hubs/
```
1. Run `01-create-hubs.sql` - Creates 4 hub tables
2. Run `02-generate-sample-data.sql` - Generates 63K+ records (~2 min)
3. Run `03-load-hubs.sql` - Loads business keys with hash generation

**Result:** 4 hub tables with ~13K unique business keys

### Step 2: Connect Entities (Links)
```
cd 02-links/
```
1. Run `01-create-links.sql` - Creates 3 link tables
2. Run `02-load-links.sql` - Loads relationships

**Result:** 3 link tables tracking customer-account-transaction relationships

### Step 3: Track Changes (Satellites)
```
cd 03-satellites/
```
1. Run `01-create-satellites.sql` - Creates 5 satellite tables
2. Run `02-load-satellites.sql` - Loads attributes with SCD Type 2

**Result:** 5 satellite tables with full history tracking (load_end_date pattern)

### Step 4: Query & Report (Business Vault)
```
cd 04-business-vault/
```
1. Run `01-create-views.sql` - Creates 4 business views
2. Run `02-compliance-reports.sql` - Runs 7 compliance reports

**Result:** Easy-to-query views and regulatory compliance reports

### Step 5: Explore Compliance Features
```sql
-- Query customer 360 view
SELECT * FROM business_vault.vw_customer_360 
WHERE customer_status = 'Active' 
ORDER BY total_balance DESC;

-- Point-in-time query (data as of 30 days ago)
DECLARE @PointInTime DATETIME = DATEADD(DAY, -30, GETDATE());
SELECT * FROM dv_sat.sat_customer_demographics
WHERE load_date <= @PointInTime
  AND (load_end_date IS NULL OR load_end_date > @PointInTime);

-- Audit trail
SELECT * FROM business_vault.vw_customer_audit_trail
WHERE customer_id = 'CUST000001'
ORDER BY change_date DESC;

-- Check metadata
SELECT * FROM metadata.pipeline_runs ORDER BY start_time DESC;
```

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
