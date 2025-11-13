# 04-projects: Real-World Data Architecture Projects

## Overview
This folder contains **5 comprehensive projects** that teach you production-ready data architecture patterns. Each project builds a complete system you'd use in real companies.

## Why These Projects?

After completing SQL lessons, you know the syntax. These projects teach you **how to architect data systems** - the patterns that separate junior developers from senior data engineers.

> "The medallion architecture I alone learned about it in this course and I use it in my projects." - You'll learn 4 MORE patterns like this!

## Projects

### 1. Data Warehouse (Medallion Architecture)
**Pattern**: Bronze → Silver → Gold layer progression  
**Best For**: ETL/ELT pipelines, data lakes, cloud warehouses  
**Time**: 7-10 hours  
**You'll Build**: E-commerce data warehouse with raw, cleaned, and aggregated layers  

**Key Concepts**:
- Raw data landing zones (Bronze)
- Data cleaning and validation (Silver)
- Business-ready analytics (Gold)
- Incremental loading patterns

**When to Use**: Any modern data platform (Databricks, Snowflake, BigQuery)

---

### 2. Data Vault 2.0 - Banking Compliance
**Pattern**: Hub-Link-Satellite architecture  
**Best For**: Regulatory compliance, audit trails, historical tracking  
**Time**: 9-11 hours  
**You'll Build**: Banking system with complete change history  

**Key Concepts**:
- Hubs (business keys)
- Links (relationships)
- Satellites (changing attributes)
- Point-in-time queries
- Regulatory reporting

**When to Use**: Banking, healthcare, insurance (strict compliance requirements)

---

### 3. Kimball Star Schema - Retail Analytics
**Pattern**: Fact & Dimension tables  
**Best For**: Business intelligence, dashboards, reporting  
**Time**: 9-12 hours  
**You'll Build**: Retail analytics warehouse for Power BI/Tableau  

**Key Concepts**:
- Fact tables (measures)
- Dimension tables (context)
- Slowly Changing Dimensions (SCD Type 2)
- Aggregate tables
- Time-series analysis

**When to Use**: Any BI/analytics project (most common pattern in industry)

---

### 4. Change Data Capture (CDC) Pipeline
**Pattern**: Real-time data replication  
**Best For**: Near real-time analytics, event-driven systems  
**Time**: 9-12 hours  
**You'll Build**: Live sync between operational DB and warehouse  

**Key Concepts**:
- SQL Server Change Tracking
- Temporal tables (time travel)
- Trigger-based CDC
- Incremental loading
- Conflict resolution

**When to Use**: Real-time dashboards, fraud detection, live inventory

---

### 5. Data Quality Monitoring & Observability
**Pattern**: Automated validation and alerting  
**Best For**: Production data systems, ensuring data trust  
**Time**: 9-12 hours  
**You'll Build**: Monitoring system that validates data quality  

**Key Concepts**:
- Completeness checks
- Accuracy validation
- Anomaly detection
- Automated alerting
- Quality scorecards

**When to Use**: EVERY production data system (critical for data trust)

---

## Pattern Comparison Matrix

| Pattern | Query Speed | Complexity | Best For | Industry Adoption |
|---------|-------------|------------|----------|-------------------|
| **Medallion** | Medium | Low | ETL/ELT pipelines | ⭐⭐⭐⭐⭐ (Cloud-native) |
| **Data Vault 2.0** | Slow | High | Compliance & audit | ⭐⭐⭐ (Banking, healthcare) |
| **Kimball Star Schema** | Fast | Low | BI & dashboards | ⭐⭐⭐⭐⭐ (Most popular) |
| **CDC Pipeline** | Real-time | Medium | Live sync | ⭐⭐⭐⭐ (Growing fast) |
| **Data Quality** | N/A | Medium | All systems | ⭐⭐⭐⭐⭐ (Critical) |

## Learning Path

### For Analytics/BI Focus
```
1. Medallion Architecture (understand data layers)
   ↓
2. Kimball Star Schema (learn dimensional modeling)
   ↓
3. Data Quality Monitoring (ensure reliable analytics)
```

### For Data Engineering Focus
```
1. Medallion Architecture (master ETL patterns)
   ↓
2. CDC Pipeline (real-time data movement)
   ↓
3. Data Quality Monitoring (production reliability)
```

### For Compliance/Audit Focus
```
1. Data Vault 2.0 (historical tracking)
   ↓
2. CDC Pipeline (capture all changes)
   ↓
3. Data Quality Monitoring (validate compliance)
```

## Prerequisites

**Required Knowledge** (from lessons):
- SQL JOINs, GROUP BY, window functions
- Indexes and query optimization
- Stored procedures and triggers
- CTEs and subqueries

**Recommended Sequence**:
- Complete Beginner + Intermediate lessons first
- At least some Advanced lessons (especially 01-subqueries, 02-ctes, 09-transactions)
- Have completed TechStore database setup

## What You'll Gain

### Technical Skills
✅ Design data warehouse architectures  
✅ Choose the right pattern for business needs  
✅ Build production-ready SQL systems  
✅ Implement automated data pipelines  
✅ Monitor and maintain data quality  

### Career Skills
✅ Portfolio-ready projects for job interviews  
✅ Real-world patterns used at FAANG companies  
✅ Architectural decision-making experience  
✅ Understanding of trade-offs between patterns  

## Project Structure

Each project contains:
- **README.md**: Complete project overview
- **Setup guides**: Understand the architecture
- **SQL scripts**: Step-by-step implementation
- **Practice exercises**: Hands-on coding
- **Real-world examples**: Production patterns

## Time Investment

**Total Time**: 40-50 hours for all 5 projects

**Recommended Pace**:
- **Fast Track**: 1 project per week (5 weeks total)
- **Steady**: 1 project per 2 weeks (10 weeks total)
- **Thorough**: 1 project per month (5 months total)

## Industry Relevance

These patterns are used at:
- **Medallion**: Databricks, Snowflake, Azure Synapse, AWS Redshift
- **Data Vault**: Banks (JP Morgan, Wells Fargo), insurance companies
- **Kimball**: Every company with Power BI, Tableau, Looker dashboards
- **CDC**: Uber, Netflix, Airbnb (real-time systems)
- **Data Quality**: Google, Amazon, Microsoft (data reliability)

## Getting Help

As you work through projects:
1. Start with `README.md` in each project folder
2. Follow files in numerical order (01, 02, 03...)
3. Complete all exercises before moving to next phase
4. Test your code after each file

## Next Steps

**Start with Project 1**: Data Warehouse (Medallion Architecture)  
📂 `01-data-warehouse-medallion/README.md`

This is the most beginner-friendly and widely used pattern. Once you master this, the other patterns will make more sense!

---

**Remember**: These aren't just tutorials - they're **real architectures** used by companies to solve billion-dollar data problems. Master these, and you'll be ready for senior data engineering roles! 🚀
