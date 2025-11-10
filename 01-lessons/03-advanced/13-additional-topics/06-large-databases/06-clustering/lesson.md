# Lesson 17.6: Clustering for High Availability

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand SQL Server clustering concepts
2. Distinguish between Failover Clustering and Always On Availability Groups
3. Plan high availability architecture
4. Understand read-scale and load distribution
5. Evaluate clustering options for your needs

## Business Context

**High availability** is critical for production databases. Clustering provides automatic failover, disaster recovery, and read-scale capabilities. Downtime costs money - clustering minimizes it.

**Time:** 45 minutes  
**Level:** Advanced

---

## Part 1: What is Database Clustering?

### Definition

**Clustering** = Multiple database servers working together to provide:
- **High Availability:** Automatic failover if primary server fails
- **Disaster Recovery:** Geographic redundancy
- **Read-Scale:** Distribute read workloads
- **Maintenance Flexibility:** Upgrade without downtime

### Real-World Analogy

Think of clustering like having backup generators:
- **Primary server** = Main power supply
- **Secondary servers** = Backup generators
- **Automatic failover** = Automatic switch when power fails
- **Load balancing** = Multiple generators sharing the load

---

## Part 2: SQL Server Clustering Technologies

### Technology Comparison

| Feature | Failover Cluster Instance (FCI) | Always On Availability Groups (AG) |
|---------|--------------------------------|-----------------------------------|
| **Purpose** | Instance-level HA | Database-level HA |
| **Shared Storage** | Required | Not required |
| **Multiple Replicas** | No (active/passive) | Yes (1 primary, up to 8 secondary) |
| **Read Secondaries** | No | Yes |
| **Automatic Failover** | Yes | Yes |
| **Geographic Distribution** | Limited | Yes (can span data centers) |
| **Edition** | Standard or Enterprise | Enterprise (Standard limited) |
| **Best For** | Single-site HA | Multi-site DR, read-scale |

### When to Use Each

**Failover Cluster Instance (FCI):**
```
✓ Single data center
✓ Need instance-level protection
✓ Existing shared storage infrastructure
✓ Standard Edition budget
✗ Need read replicas
✗ Multi-site disaster recovery
```

**Always On Availability Groups:**
```
✓ Multi-site disaster recovery
✓ Need read-scale (reporting)
✓ Granular database control
✓ No shared storage
✗ Single database instance
✗ Budget constraints (Enterprise only for full features)
```

---

## Part 3: Failover Cluster Instance (FCI)

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Windows Cluster                    │
├─────────────────────┬───────────────────────────────┤
│   Node 1 (Active)   │    Node 2 (Passive)           │
│   SQL Server        │    SQL Server                 │
│   IP: 10.0.1.100    │    IP: 10.0.1.101             │
└──────────┬──────────┴────────────┬──────────────────┘
           │                       │
           └───────────┬───────────┘
                       │
           ┌───────────▼───────────┐
           │   Shared Storage      │
           │   (SAN / Cluster Disk)│
           │   Database Files      │
           └───────────────────────┘

Virtual IP: 10.0.1.200 (clients connect here)
```

### How FCI Works

1. **Normal Operation:**
   - Node 1 runs SQL Server instance
   - Database files on shared storage
   - Clients connect to virtual IP (10.0.1.200)
   - Node 2 is passive (standby)

2. **Failure Detection:**
   - Windows Cluster monitors Node 1
   - Detects failure (hardware, OS, SQL crash)
   - Initiates failover (30-60 seconds)

3. **Failover:**
   - Node 2 becomes active
   - Mounts shared storage
   - Starts SQL Server
   - Takes over virtual IP
   - Clients reconnect automatically

4. **Recovery:**
   - Automatic database recovery (rollback/roll-forward)
   - Applications reconnect
   - Downtime: typically 30-120 seconds

### FCI Components

**Windows Server Failover Clustering (WSFC):**
- Cluster nodes (minimum 2)
- Shared storage (SAN, iSCSI, Storage Spaces Direct)
- Cluster quorum (voting mechanism)
- Virtual network name

**SQL Server Components:**
- SQL Server instance (shared between nodes)
- Database files (on shared storage)
- Transaction logs (on shared storage)
- tempdb (local or shared)

### FCI Limitations

```
❌ Active/passive only (one node active at a time)
❌ Requires expensive shared storage
❌ Limited to same data center (storage proximity)
❌ No read-scale capabilities
❌ Failover downtime (30-120 seconds)
❌ Shared storage = single point of failure
```

### FCI Best Practices

1. **Storage:**
   - Use enterprise SAN with redundancy
   - RAID 10 for data files
   - Separate storage for logs
   - Monitor storage performance

2. **Network:**
   - Dedicated cluster network
   - Redundant network adapters
   - Low-latency connections

3. **Quorum:**
   - Node and File Share Majority (recommended)
   - Avoid "disk-only" quorum
   - Monitor quorum health

4. **Testing:**
   - Regular failover testing (monthly)
   - Validate recovery times
   - Test under load
   - Document procedures

---

## Part 4: Always On Availability Groups

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Availability Group: AG_Sales             │
├────────────────┬────────────────┬──────────────────────────┤
│  Primary       │  Secondary 1   │  Secondary 2             │
│  (Read/Write)  │  (Read-Only)   │  (Read-Only)             │
│  DC1           │  DC1           │  DC2 (DR Site)           │
│  10.0.1.10     │  10.0.1.11     │  10.0.2.10              │
└────────┬───────┴────────┬───────┴────────┬────────────────┘
         │                 │                 │
         │ Synchronous     │                 │ Asynchronous
         │ Commit          │                 │ Commit
         └─────────────────┴─────────────────┘
         
Listener: AG_Sales_Listener (10.0.1.100)
- Read-Write: Routes to Primary
- Read-Only: Routes to Secondaries (load balanced)
```

### How Always On Works

1. **Normal Operation:**
   - Primary replica: Read/write workload
   - Secondary replicas: Synchronized continuously
   - Synchronous commit: Data on multiple replicas before ACK
   - Asynchronous commit: No wait for distant replicas

2. **Data Synchronization:**
   ```
   Transaction on Primary
         │
         ▼
   Write to transaction log
         │
         ├──→ Synchronous Secondary 1 (wait for ACK)
         │    - Hardens log on secondary
         │    - Sends ACK to primary
         │    - Transaction commits
         │
         └──→ Asynchronous Secondary 2 (no wait)
              - Receives log records
              - No impact on primary commit
   ```

3. **Automatic Failover:**
   ```
   Primary Failure Detected
         │
         ▼
   WSFC Initiates Failover (10-30 seconds)
         │
         ▼
   Synchronous Secondary Becomes Primary
         │
         ▼
   Listener Updates to New Primary
         │
         ▼
   Clients Reconnect Automatically
   ```

### Availability Group Modes

**Synchronous Commit (High Availability):**
```
✓ Zero data loss
✓ Automatic failover
✓ Primary waits for secondary ACK
✓ Low latency required (<5ms)
✗ Performance impact on primary
✗ Limited to nearby replicas
```

**Asynchronous Commit (Disaster Recovery):**
```
✓ No performance impact on primary
✓ Works across WAN (high latency)
✓ Geographic redundancy
✗ Potential data loss during failover
✗ Manual failover only
✗ Not for automatic HA
```

### Read-Scale with Availability Groups

**Offload reporting to secondaries:**

```sql
-- Connection strings
Primary (Read-Write):
Server=AG_Sales_Listener;Database=SalesDB;ApplicationIntent=ReadWrite

Secondary (Read-Only):
Server=AG_Sales_Listener;Database=SalesDB;ApplicationIntent=ReadOnly
```

**Benefits:**
- Primary handles OLTP (inserts, updates, deletes)
- Secondaries handle reporting, analytics, backups
- Read-scale: 2-8 readable secondaries
- No performance impact on primary

**Load Balancing:**
```
Read-Only Routing List:
Secondary 1 (Priority 1)
Secondary 2 (Priority 2)

Connections distributed:
- First connection → Secondary 1
- Second connection → Secondary 2
- Third connection → Secondary 1
- ...
```

### Always On Limitations

```
❌ Enterprise Edition required (for full features)
❌ More complex than FCI
❌ Requires WSFC
❌ Database-level (not instance-level)
❌ Some features not supported (database mail, cross-database transactions)
❌ Synchronous = latency sensitive
```

### Always On Best Practices

1. **Replica Configuration:**
   - 2-3 synchronous replicas in same data center
   - 1-2 asynchronous replicas in DR site
   - Maximum 9 total replicas (1 primary + 8 secondary)
   - Use automatic failover for synchronous only

2. **Network:**
   - Dedicated network for replica traffic
   - Low latency for synchronous (<5ms)
   - Bandwidth for data volume
   - Monitor network performance

3. **Monitoring:**
   - Data synchronization health
   - Failover readiness
   - Replication lag
   - Automatic seeding progress

4. **Read-Only Routing:**
   - Configure read-only routing list
   - Load balance reporting workload
   - Monitor secondary replica performance
   - Use ApplicationIntent in connection strings

---

## Part 5: Clustering Decision Matrix

### Choose Your Technology

```
┌─────────────────────────────────────────────────────────┐
│ DECISION TREE                                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Need read-scale? ───YES──→ Always On AG                │
│      │                                                   │
│      NO                                                  │
│      │                                                   │
│ Multi-site DR? ───YES──→ Always On AG                  │
│      │                                                   │
│      NO                                                  │
│      │                                                   │
│ Have shared storage? ───YES──→ FCI                     │
│      │                                                   │
│      NO ──→ Always On AG (no shared storage needed)    │
│                                                          │
│ Budget constraint? ───YES──→ FCI (Standard Edition)    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Scenario Recommendations

| Scenario | Recommended Solution | Reason |
|----------|---------------------|--------|
| E-commerce website (24/7) | Always On AG (2 sync + 1 async) | Auto failover + DR + read-scale |
| ERP system (single site) | FCI | Simple, cost-effective HA |
| Reporting heavy workload | Always On AG | Offload reports to secondaries |
| Global application | Always On AG (multiple async) | Geographic distribution |
| Small business | Database Mirroring* | Simple, low cost (deprecated) |
| Mission-critical 24/7 | Always On AG (3 sync) | Zero data loss, instant failover |

*Note: Database Mirroring is deprecated; use Always On AG instead.

---

## Part 6: Hybrid and Cloud Clustering

### Azure SQL Database

**Built-in High Availability:**
- Automatic replicas (no configuration needed)
- 99.99% SLA
- Automatic failover
- No additional cost

**Read-Scale:**
```sql
-- Premium/Business Critical tier
ApplicationIntent=ReadOnly  -- Routes to readable secondary
```

### Hybrid Always On

**On-Premises + Azure:**
```
Primary Replica (On-Premises)
    │
    ├──→ Secondary Replica (On-Premises) [Sync]
    │
    └──→ Azure VM Replica [Async]
         - Disaster recovery
         - Cloud migration path
         - Cost-effective DR
```

### Distributed Availability Groups

**Cross-cluster AG:**
```
Cluster 1 (Data Center 1)
  AG1: Primary + Secondary
        │
        └──→ Distributed AG
                │
Cluster 2 (Data Center 2)
  AG2: Primary + Secondary
  
Benefits:
- Multi-cluster disaster recovery
- Migration between clusters
- Global scale-out
```

---

## Practical Exercise

### Exercise 1: Design High Availability Solution

**Scenario:** Design HA solution for global e-commerce platform

**Requirements:**
- 24/7 availability (99.99% uptime)
- Users in North America, Europe, Asia
- 10TB database
- Heavy reporting workload
- Zero data loss tolerance in primary region
- 15-minute RPO for DR site

**Your Design:**
```
Components:
- Number of replicas: ____
- Synchronous vs asynchronous: ____
- Geographic distribution: ____
- Read-scale configuration: ____
- Backup strategy: ____
```

**Solution:**
```
Recommended Design: Always On Availability Group

Primary Site (North America):
- Primary Replica (Read/Write)
- Secondary Replica 1 (Synchronous, Auto Failover)
- Secondary Replica 2 (Synchronous, Read-Only for Reporting)

DR Site (Europe):
- Secondary Replica 3 (Asynchronous)

Read-Scale:
- Route NA/LATAM reads to Secondary 2
- Route EU reads to Secondary 3 (when not failing over)
- Primary handles all writes

Justification:
✓ 99.99% uptime (auto failover in <30 seconds)
✓ Zero data loss in primary region (synchronous)
✓ 15-minute RPO for Europe (asynchronous)
✓ Read-scale for reporting (secondaries)
✓ Geographic distribution (NA + EU)
```

---

## Key Takeaways

### Failover Cluster Instance (FCI)
```
✓ Instance-level high availability
✓ Automatic failover (30-120 seconds)
✓ Shared storage required
✓ Good for single-site HA
✓ Standard Edition support
✗ No read-scale
✗ Active/passive only
```

### Always On Availability Groups
```
✓ Database-level high availability
✓ Multiple readable replicas
✓ Geographic distribution
✓ No shared storage needed
✓ Synchronous = zero data loss
✓ Read-scale offloads primary
✗ Enterprise Edition (full features)
✗ More complex setup
```

### Best Practices
1. **Plan for failure** - Regular testing
2. **Monitor health** - Continuous monitoring
3. **Document procedures** - Runbooks for failover
4. **Test regularly** - Monthly failover drills
5. **Match SLA to business needs** - Don't over-engineer
6. **Consider costs** - Licensing, storage, network

### Common Mistakes to Avoid
```
❌ Not testing failover regularly
❌ Using synchronous over WAN (high latency)
❌ Insufficient network bandwidth
❌ No monitoring/alerting
❌ Single point of failure (shared storage in FCI)
❌ Not planning for split-brain scenarios
```

---

## Next Steps

**Continue to Lesson 17.7: Sharding**  
Learn how to scale horizontally by distributing data across multiple database servers.

---

## Additional Resources

- **Microsoft Docs:** Always On Availability Groups
- **Microsoft Docs:** Failover Cluster Instances
- **Performance Tuning:** Monitoring AG synchronization
- **Best Practices:** HA/DR architectures
