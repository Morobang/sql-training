# Lesson 17.11: Cloud Computing for Databases

## Learning Objectives

By the end of this lesson, you will be able to:
1. Compare cloud database services (Azure SQL, AWS RDS, GCP Cloud SQL)
2. Understand serverless vs provisioned database models
3. Design for cloud scalability and elasticity
4. Evaluate cost optimization strategies
5. Plan cloud migration from on-premises SQL Server

## Business Context

**Cloud databases** offer elasticity, managed services, and global scale without infrastructure management. Understanding cloud database options and cost models is essential for modern data architecture decisions.

**Time:** 55 minutes  
**Level:** Advanced

---

## Part 1: Cloud Database Service Models

### IaaS vs PaaS vs DBaaS

```
┌─────────────────────────────────────────────────────┐
│  INFRASTRUCTURE AS A SERVICE (IaaS)                  │
│  Example: SQL Server on Azure VM                    │
├─────────────────────────────────────────────────────┤
│  YOU MANAGE:                                         │
│  ✓ SQL Server installation & configuration          │
│  ✓ Patches and updates                              │
│  ✓ Backups                                           │
│  ✓ High availability setup                           │
│  ✓ Security                                          │
│                                                      │
│  CLOUD PROVIDES:                                     │
│  ✓ Virtual machine                                   │
│  ✓ Storage                                           │
│  ✓ Network                                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  PLATFORM AS A SERVICE (PaaS)                        │
│  Example: Azure SQL Database                        │
├─────────────────────────────────────────────────────┤
│  YOU MANAGE:                                         │
│  ✓ Database schema                                   │
│  ✓ Queries and indexes                              │
│  ✓ Application code                                  │
│                                                      │
│  CLOUD PROVIDES:                                     │
│  ✓ SQL Server installation                           │
│  ✓ Automatic patching                                │
│  ✓ Automatic backups                                 │
│  ✓ Built-in high availability                        │
│  ✓ Scaling                                           │
│  ✓ Security                                          │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  DATABASE AS A SERVICE (DBaaS)                       │
│  Example: Azure Cosmos DB, AWS DynamoDB             │
├─────────────────────────────────────────────────────┤
│  YOU MANAGE:                                         │
│  ✓ Data model                                        │
│  ✓ Application code                                  │
│                                                      │
│  CLOUD PROVIDES:                                     │
│  ✓ Everything (fully managed)                        │
│  ✓ Auto-scaling                                      │
│  ✓ Global distribution                               │
│  ✓ Built-in replication                              │
└─────────────────────────────────────────────────────┘
```

### Comparison Matrix

| Aspect | IaaS (VM) | PaaS (Azure SQL) | DBaaS (Cosmos DB) |
|--------|-----------|------------------|-------------------|
| **Setup Time** | Hours-Days | Minutes | Seconds |
| **Maintenance** | Manual | Automatic | Automatic |
| **Control** | Full | Limited | Minimal |
| **Scaling** | Manual | Auto-scale | Auto-scale |
| **Cost** | Medium | Medium-High | Variable |
| **Best For** | Legacy apps | Modern apps | Global apps |

---

## Part 2: Azure SQL Database

### Azure SQL Options

```
1. SQL Database (Single Database)
   - One database, dedicated resources
   - Serverless or provisioned
   - 99.99% SLA

2. Elastic Pool
   - Multiple databases, shared resources
   - Cost-effective for many databases
   - Variable workloads

3. Managed Instance
   - Near 100% compatibility with SQL Server
   - VNet integration
   - Migration from on-premises

4. SQL Server on Azure VM
   - Full control
   - Same as on-premises
   - Lift-and-shift migration
```

### Service Tiers

**General Purpose:**
```
✓ Cost-effective
✓ 5-10ms latency (remote storage)
✓ 99.99% SLA
✓ Point-in-time restore (35 days)

Use: Most workloads
```

**Business Critical:**
```
✓ Low latency (< 2ms, local SSD)
✓ Built-in readable replica
✓ 99.99% SLA
✓ Failover groups

Use: Mission-critical, low-latency apps
```

**Hyperscale:**
```
✓ Up to 100 TB database
✓ Fast backup/restore
✓ Rapid scale-up
✓ Multiple read replicas

Use: Very large databases
```

### Compute Tiers: Provisioned vs Serverless

**Provisioned (Traditional):**
```sql
-- Always running
-- Pay for allocated capacity (even if idle)
-- Predictable performance
-- Choose vCores or DTU model

Example:
- 8 vCores, 32 GB RAM
- Cost: $500/month (24/7)
- Good for: Production apps with steady traffic
```

**Serverless (Pay-per-use):**
```sql
-- Auto-pause when idle
-- Auto-scale based on load
-- Pay only for compute used
-- Storage billed separately

Example:
- Min: 1 vCore, Max: 4 vCores
- Auto-pause after 1 hour idle
- Cost: $50-200/month (based on usage)
- Good for: Dev/test, intermittent workloads
```

### Scaling Strategies

**Vertical Scaling (Scale Up/Down):**
```sql
-- Azure Portal or T-SQL
ALTER DATABASE MyDatabase
MODIFY (SERVICE_OBJECTIVE = 'P4');  -- 500 DTU

-- Downtime: Minimal (connection reset)
-- Time: Minutes
-- Use: Seasonal traffic, planned capacity changes
```

**Horizontal Scaling (Read Scale-Out):**
```sql
-- Business Critical tier only
-- Built-in readable secondary

-- Connection string for read-only:
Server=myserver.database.windows.net;
Database=MyDB;
ApplicationIntent=ReadOnly;

-- Offload reporting, analytics
-- No additional cost (included in tier)
```

**Sharding (Manual):**
```sql
-- Elastic Database Tools
-- Shard map manager
-- Data-dependent routing

-- Example: Shard by CustomerId
Shard 1: CustomerID 1-100,000
Shard 2: CustomerID 100,001-200,000
Shard 3: CustomerID 200,001-300,000
...

-- Application routes queries to correct shard
```

---

## Part 3: AWS RDS (Relational Database Service)

### RDS for SQL Server

**Key Features:**
```
✓ Managed SQL Server
✓ Automated backups
✓ Multi-AZ (high availability)
✓ Read replicas
✓ Automatic scaling
```

### RDS Instance Types

```
1. db.t3 (Burstable):
   - Dev/test
   - Low cost
   - Variable workload

2. db.m5 (General Purpose):
   - Balanced compute/memory
   - Production workloads
   - $500-2000/month

3. db.r5 (Memory Optimized):
   - High memory
   - Large databases
   - Analytics
   - $1000-5000/month

4. db.x1e (Extreme Memory):
   - Very large in-memory databases
   - SAP HANA
   - $10,000+/month
```

### Multi-AZ Deployment

```
┌─────────────────────────────────────┐
│  Availability Zone A                │
│  ┌───────────────────────────────┐  │
│  │   Primary Instance            │  │
│  │   (Read/Write)                │  │
│  └──────────┬────────────────────┘  │
└─────────────┼───────────────────────┘
              │ Synchronous
              │ Replication
┌─────────────▼───────────────────────┐
│  Availability Zone B                │
│  ┌───────────────────────────────┐  │
│  │   Standby Instance            │  │
│  │   (Automatic Failover)        │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

- Failover: 60-120 seconds
- Zero data loss
- Automatic
- 99.95% SLA
```

### Read Replicas

```
Primary Instance (us-east-1)
    │
    ├──→ Read Replica (us-east-1)
    ├──→ Read Replica (us-west-2)
    └──→ Read Replica (eu-west-1)

Benefits:
✓ Scale read workload
✓ Cross-region replication
✓ Disaster recovery
✓ Low latency reads globally
```

---

## Part 4: Google Cloud SQL

### Cloud SQL for SQL Server

**Features:**
```
✓ Fully managed
✓ Automated backups
✓ High availability (99.95% SLA)
✓ Automatic storage increase
✓ Private IP (VPC)
```

### High Availability Configuration

```
Regional HA:
- Primary instance
- Standby replica (different zone)
- Synchronous replication
- Automatic failover
- 99.95% SLA

vs

Single Zone:
- One instance
- No automatic failover
- 99.50% SLA
- Lower cost
```

---

## Part 5: Cloud Cost Optimization

### Pricing Models

**1. On-Demand (Pay-as-you-go):**
```
Azure SQL:
- vCore: $0.50/vCore/hour
- 8 vCores = $2,920/month (24/7)

AWS RDS:
- db.m5.xlarge (4 vCores): $0.36/hour
- Monthly: $262 (24/7)

GCP Cloud SQL:
- db-n1-standard-4: $0.23/hour
- Monthly: $167 (24/7)
```

**2. Reserved (1-3 year commitment):**
```
Azure SQL Reserved:
- 1 year: 40% discount
- 3 year: 65% discount
- 8 vCores: $1,022/month (3-year reserved)

AWS RDS Reserved:
- 1 year: 35% discount
- 3 year: 60% discount

Savings: $1,900/month vs on-demand!
```

**3. Serverless:**
```
Azure SQL Serverless:
- Min: 1 vCore ($75/month minimum)
- Max: 4 vCores ($300/month maximum)
- Auto-pause: No compute cost when idle
- Good for: Dev/test, variable workload

Actual cost example:
- Database active 8 hours/day
- Cost: ~$100/month
- vs Provisioned: $500/month
- Savings: 80%!
```

### Cost Optimization Strategies

**1. Right-Sizing:**
```sql
-- Monitor resource usage
SELECT 
    AVG(avg_cpu_percent) AS AvgCPU,
    MAX(avg_cpu_percent) AS MaxCPU,
    AVG(avg_memory_percent) AS AvgMemory
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(DAY, -7, GETDATE());

-- If AvgCPU < 20% → Downsize
-- If MaxCPU > 80% → Upsize or optimize queries
```

**2. Use Serverless for Dev/Test:**
```
Production: Provisioned ($500/month)
Staging: Serverless ($100/month)
Dev: Serverless ($50/month)
QA: Serverless ($50/month)

Savings: $300/month on non-production
```

**3. Elastic Pools (Azure):**
```
Instead of:
- DB1: 2 vCores ($200/month)
- DB2: 2 vCores ($200/month)
- DB3: 2 vCores ($200/month)
Total: $600/month

Use Elastic Pool:
- 4 vCores shared ($300/month)
- 3 databases share resources
- Savings: $300/month (50%)
```

**4. Compression:**
```sql
-- Page compression (50-80% space savings)
ALTER TABLE Orders
REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);

-- Storage cost: 1 TB → 300 GB
-- Savings: $70/month (700 GB × $0.10/GB)
```

**5. Backup Retention:**
```
Azure SQL:
- Short-term: 7-35 days (included)
- Long-term: 1-10 years (additional cost)

Default: 7 days ($0/month)
35 days: +$10/month
10 years: +$50/month

Recommendation: Use long-term only for compliance
```

**6. Reserved Instances:**
```
Committed workload:
- On-demand: $500/month
- 1-year reserved: $300/month (-40%)
- 3-year reserved: $175/month (-65%)

Payback period: 7-8 months
```

### Cost Comparison: On-Premises vs Cloud

**On-Premises (5-Year TCO):**
```
Hardware: $50,000
Licenses: $15,000
Data center: $5,000/year × 5 = $25,000
DBA salary: $120,000/year × 5 = $600,000
Utilities, cooling: $10,000/year × 5 = $50,000

Total: $740,000 over 5 years
Monthly equivalent: $12,333
```

**Cloud (Azure SQL Business Critical):**
```
8 vCores: $1,800/month
Reserved 3-year: $630/month
Backups: $100/month
Monitoring: $50/month

Total: $780/month
5-year total: $46,800

Savings: $693,200 (94%!)
```

**Note:** Assumes no DBA salary in cloud (or reduced hours)

---

## Part 6: Cloud Migration Strategies

### Migration Approaches

**1. Lift-and-Shift (IaaS):**
```
SQL Server on-premises
    ↓
SQL Server on Azure VM

Method: Backup/restore
Downtime: Hours
Compatibility: 100%
Effort: Low
```

**2. Re-Platform (PaaS):**
```
SQL Server on-premises
    ↓
Azure SQL Managed Instance

Method: Azure Database Migration Service
Downtime: Minutes
Compatibility: 99%
Effort: Medium
```

**3. Refactor (PaaS):**
```
SQL Server on-premises
    ↓
Azure SQL Database

Method: Schema migration + data migration
Downtime: Minutes-Hours
Compatibility: 95% (some features unsupported)
Effort: High
```

### Migration Tools

**Azure Database Migration Service:**
```
Features:
✓ Online migration (minimal downtime)
✓ Automated assessment
✓ Schema conversion
✓ Data migration
✓ Cutover orchestration

Process:
1. Assessment (compatibility check)
2. Schema migration
3. Initial data sync
4. Continuous replication
5. Cutover (switch to cloud)
```

**Data Migration Assistant (DMA):**
```
1. Download DMA
2. Connect to on-premises SQL Server
3. Run assessment
4. Review compatibility issues
5. Fix issues
6. Migrate schema
7. Migrate data
```

### Migration Checklist

```
PRE-MIGRATION:
☐ Assess compatibility (DMA)
☐ Identify blockers (features not in cloud)
☐ Estimate cost (Azure Pricing Calculator)
☐ Plan downtime window
☐ Test migration in non-production
☐ Update connection strings
☐ Plan rollback strategy

MIGRATION:
☐ Backup on-premises database
☐ Migrate schema
☐ Migrate data (initial sync)
☐ Validate data integrity
☐ Test application
☐ Cutover (switch to cloud)

POST-MIGRATION:
☐ Monitor performance
☐ Optimize queries (cloud patterns different)
☐ Configure backups
☐ Set up alerts
☐ Document new architecture
☐ Train team on cloud tools
```

---

## Part 7: Global Distribution

### Azure SQL Failover Groups

```
┌────────────────────────────────┐
│  Primary Region (East US)       │
│  ┌──────────────────────────┐  │
│  │  Primary Database        │  │
│  │  (Read/Write)            │  │
│  └──────────┬───────────────┘  │
└─────────────┼──────────────────┘
              │ Async Replication
┌─────────────▼──────────────────┐
│  Secondary Region (West US)     │
│  ┌──────────────────────────┐  │
│  │  Secondary Database      │  │
│  │  (Read-Only or Failover) │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘

Read/Write Listener: 
  myserver.database.windows.net

Read-Only Listener:
  myserver.secondary.database.windows.net

Automatic Failover:
- RPO: < 5 seconds (potential data loss)
- RTO: < 30 seconds (downtime)
```

### Multi-Region Deployment Strategies

**Active-Passive:**
```
Primary (East US): Read/Write
Secondary (West US): Failover only

Cost: 2x database
Benefit: Disaster recovery
```

**Active-Active:**
```
Primary (East US): Read/Write + Read
Secondary (West US): Read-Only

Cost: 2x database
Benefit: DR + read scale + low latency reads
```

**Multi-Region (Cosmos DB):**
```
Write Region: East US
Read Regions:
  - West US
  - Europe West
  - Asia Southeast

Cost: 4x database
Benefit: Global low-latency reads
```

---

## Key Takeaways

### Cloud Service Models
```
IaaS: Full control, manual management
PaaS: Managed, automatic updates
DBaaS: Fully managed, auto-scale
```

### Cost Optimization
```
1. Right-size instances (monitor usage)
2. Reserved instances (40-65% savings)
3. Serverless for variable workload
4. Elastic pools for multiple databases
5. Compression (storage savings)
6. Optimize backup retention
```

### Migration Strategy
```
1. Assess compatibility (DMA)
2. Choose model (IaaS vs PaaS)
3. Test migration (non-production first)
4. Plan cutover (minimize downtime)
5. Monitor and optimize post-migration
```

### Scaling
```
Vertical: Scale up/down (minutes)
Horizontal: Read replicas (reporting)
Sharding: Distribute data (manual)
Global: Multi-region (DR + performance)
```

### Best Practices
```
1. Use PaaS when possible (less management)
2. Reserved instances for production
3. Serverless for dev/test
4. Monitor costs regularly
5. Test failover scenarios
6. Automate backups
7. Use resource tags for cost tracking
```

---

## Next Steps

**Continue to Lesson 17.12: Test Your Knowledge**  
Comprehensive assessment covering all large database topics from Chapter 17.

---

## Additional Resources

- **Azure SQL Database Documentation**
- **AWS RDS Best Practices**
- **Google Cloud SQL Documentation**
- **Tool:** Azure Pricing Calculator
- **Tool:** AWS Total Cost of Ownership Calculator
