# TechStore Database - Entity Relationship Diagram

## Overview

The **TechStore** database is used throughout the SQL training projects for demonstrating data warehousing patterns, data quality monitoring, and advanced SQL techniques.

---

## 📊 Schema Diagram

```
┌────────────────────────┐
│      CUSTOMERS         │
├────────────────────────┤
│ • CustomerID (PK)      │
│   FirstName            │
│   LastName             │
│   Email                │
│   City                 │
│   State                │
│   CreatedDate          │
│   IsActive             │
│   CustomerType         │
└────────────────────────┘
           │
           │ 1
           │
           │
           │ *
           │
           ▼
┌────────────────────────┐         ┌────────────────────────┐
│       ORDERS           │         │      PRODUCTS          │
├────────────────────────┤         ├────────────────────────┤
│ • OrderID (PK)         │         │ • ProductID (PK)       │
│   CustomerID (FK) ────┼────┐    │   ProductName          │
│   ProductID (FK) ─────┼────┼────▶   Category             │
│   OrderDate            │    │    │   Price                │
│   TotalAmount          │    │    │   StockQuantity        │
│   Quantity             │    │    │   LastRestockedDate    │
│   LoadedAt             │    │    │   IsActive             │
│   Status               │    │    └────────────────────────┘
└────────────────────────┘    │
           │                  │
           │ 1                │
           │                  │
           │                  │
           │ *                │
           │                  │
           ▼                  │
┌────────────────────────┐    │
│    ORDER_DETAILS       │    │
│    (Extended Schema)   │    │
├────────────────────────┤    │
│ • OrderDetailID (PK)   │    │
│   OrderID (FK)         │    │
│   ProductID (FK) ──────┼────┘
│   Quantity             │
│   UnitPrice            │
│   Discount             │
│   LineTotal            │
└────────────────────────┘
```

---

## 📋 Entity Descriptions

### CUSTOMERS
**Purpose**: Store customer information

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| CustomerID | INT | PRIMARY KEY, IDENTITY | Unique customer identifier |
| FirstName | VARCHAR(50) | NOT NULL | Customer's first name |
| LastName | VARCHAR(50) | NOT NULL | Customer's last name |
| Email | VARCHAR(100) | UNIQUE | Customer's email address |
| City | VARCHAR(50) | | Customer's city |
| State | VARCHAR(2) | | Two-letter state code |
| CreatedDate | DATETIME | DEFAULT GETDATE() | Account creation timestamp |
| IsActive | BIT | DEFAULT 1 | Active status flag |
| CustomerType | VARCHAR(20) | | VIP, Premium, Standard |

**Indexes**:
- `PK_CustomerID` (Clustered)
- `IX_Email` (Non-clustered, Unique)
- `IX_City_State` (Non-clustered, Composite)

---

### PRODUCTS
**Purpose**: Store product catalog information

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| ProductID | INT | PRIMARY KEY, IDENTITY | Unique product identifier |
| ProductName | VARCHAR(100) | NOT NULL | Product name |
| Category | VARCHAR(50) | | Product category (Electronics, Accessories, etc.) |
| Price | DECIMAL(10,2) | CHECK (Price >= 0) | Current selling price |
| StockQuantity | INT | CHECK (StockQuantity >= 0) | Available inventory count |
| LastRestockedDate | DATETIME | | Last inventory replenishment date |
| IsActive | BIT | DEFAULT 1 | Product availability flag |

**Indexes**:
- `PK_ProductID` (Clustered)
- `IX_Category` (Non-clustered)
- `IX_Price` (Non-clustered)

**Business Rules**:
- Price must be non-negative
- StockQuantity must be non-negative
- LastRestockedDate updated on inventory changes

---

### ORDERS
**Purpose**: Store customer order transactions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| OrderID | INT | PRIMARY KEY, IDENTITY | Unique order identifier |
| CustomerID | INT | FOREIGN KEY → Customers | Customer who placed order |
| ProductID | INT | FOREIGN KEY → Products | Ordered product |
| OrderDate | DATETIME | NOT NULL, DEFAULT GETDATE() | Order placement timestamp |
| TotalAmount | DECIMAL(10,2) | CHECK (TotalAmount >= 0) | Total order value |
| Quantity | INT | DEFAULT 1, CHECK (Quantity > 0) | Quantity ordered |
| LoadedAt | DATETIME | DEFAULT GETDATE() | ETL load timestamp (for DQ monitoring) |
| Status | VARCHAR(20) | DEFAULT 'Pending' | Pending, Shipped, Delivered, Cancelled |

**Indexes**:
- `PK_OrderID` (Clustered)
- `IX_CustomerID` (Non-clustered)
- `IX_ProductID` (Non-clustered)
- `IX_OrderDate` (Non-clustered)
- `IX_LoadedAt` (Non-clustered, for freshness checks)

**Referential Integrity**:
```sql
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
```

---

### ORDER_DETAILS (Extended Schema)
**Purpose**: Normalized order line items (for advanced projects)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| OrderDetailID | INT | PRIMARY KEY, IDENTITY | Unique line item identifier |
| OrderID | INT | FOREIGN KEY → Orders | Parent order |
| ProductID | INT | FOREIGN KEY → Products | Ordered product |
| Quantity | INT | NOT NULL, CHECK (Quantity > 0) | Quantity of this product |
| UnitPrice | DECIMAL(10,2) | NOT NULL | Price at time of order |
| Discount | DECIMAL(5,2) | DEFAULT 0, CHECK (Discount >= 0 AND Discount <= 100) | Discount percentage |
| LineTotal | AS (Quantity * UnitPrice * (1 - Discount/100)) | COMPUTED | Calculated line total |

---

## 🔗 Relationships

### One-to-Many Relationships

1. **Customers → Orders**
   - One customer can place many orders
   - One order belongs to exactly one customer
   - Cascade behavior: Typically SET NULL or NO ACTION (preserve historical orders)

2. **Products → Orders**
   - One product can appear in many orders
   - One order references exactly one product (simplified schema)
   - Cascade behavior: NO ACTION (prevent deletion of ordered products)

3. **Orders → OrderDetails** (Extended Schema)
   - One order can have many line items
   - One line item belongs to exactly one order
   - Cascade behavior: CASCADE DELETE (delete details when order deleted)

---

## 🎯 Sample Queries

### Customer Lifetime Value
```sql
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS customer_name,
    COUNT(o.OrderID) AS total_orders,
    SUM(o.TotalAmount) AS lifetime_value,
    AVG(o.TotalAmount) AS avg_order_value
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY lifetime_value DESC;
```

### Product Sales Ranking
```sql
SELECT 
    p.ProductID,
    p.ProductName,
    COUNT(o.OrderID) AS times_ordered,
    SUM(o.Quantity) AS total_quantity_sold,
    SUM(o.TotalAmount) AS total_revenue
FROM Products p
LEFT JOIN Orders o ON p.ProductID = o.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY total_revenue DESC;
```

### Find Orphan Orders (Data Quality Check)
```sql
-- Orders with invalid CustomerID
SELECT o.*
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID
);

-- Orders with invalid ProductID
SELECT o.*
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID
);
```

---

## 📊 Cardinality & Volume

**Typical Production Volumes**:
- Customers: 10,000 - 1,000,000 rows
- Products: 500 - 50,000 rows
- Orders: 100,000 - 10,000,000 rows
- OrderDetails: 200,000 - 30,000,000 rows

**Expected Ratios**:
- Orders per Customer: Avg 10-50
- Orders per Product: Avg 100-5000
- Line Items per Order: Avg 2-5 (extended schema)

---

## 🔒 Security & Permissions

**Recommended Access Patterns**:

```sql
-- Read-only analyst role
CREATE ROLE AnalystRole;
GRANT SELECT ON Customers TO AnalystRole;
GRANT SELECT ON Products TO AnalystRole;
GRANT SELECT ON Orders TO AnalystRole;

-- Application role (CRUD)
CREATE ROLE AppRole;
GRANT SELECT, INSERT, UPDATE ON Customers TO AppRole;
GRANT SELECT, INSERT, UPDATE ON Products TO AppRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Orders TO AppRole;

-- Admin role
CREATE ROLE AdminRole;
GRANT CONTROL ON DATABASE::TechStore TO AdminRole;
```

---

## 🧪 Data Quality Dimensions

This schema demonstrates all 6 quality dimensions:

1. **Completeness**: Required fields (FirstName, LastName, Email, TotalAmount)
2. **Accuracy**: CHECK constraints (Price >= 0, StockQuantity >= 0)
3. **Consistency**: Foreign keys (CustomerID, ProductID)
4. **Timeliness**: LoadedAt timestamp for freshness monitoring
5. **Uniqueness**: Email UNIQUE constraint, Primary keys
6. **Distribution**: Statistical analysis on TotalAmount, StockQuantity

---

## 📚 Usage in Training Projects

- **Project 1 - Medallion Architecture**: Raw → Bronze → Silver → Gold transformations
- **Project 2 - Data Vault 2.0**: Hubs, Links, Satellites modeling
- **Project 3 - Kimball Star Schema**: Dimensional modeling (Fact_Orders, Dim_Customer, Dim_Product)
- **Project 4 - CDC Pipeline**: Change tracking on Orders table
- **Project 5 - Data Quality Monitoring**: 18 quality rules across all tables

---

*Database Version*: TechStore v1.0  
*Last Updated*: November 14, 2025  
*Compatible with*: SQL Server 2016+, Azure SQL Database
