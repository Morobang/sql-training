-- ============================================
-- Intermediate Lesson 1.4: Create Products Table
-- ============================================
-- Our tech store needs an inventory system!
-- ============================================

USE TechStore;

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),
    StockQuantity INT DEFAULT 0,
    SupplierID INT,
    IsActive BIT DEFAULT 1
);

-- ============================================
-- Insert sample products
-- ============================================

INSERT INTO Products (ProductID, ProductName, Category, Price, Cost, StockQuantity)
VALUES 
    (1, 'Wireless Mouse Pro', 'Accessories', 49.99, 25.00, 150),
    (2, 'Mechanical Keyboard RGB', 'Accessories', 129.99, 65.00, 75),
    (3, 'USB-C Hub 7-in-1', 'Accessories', 79.99, 40.00, 200),
    (4, 'Laptop Stand Aluminum', 'Accessories', 59.99, 28.00, 120),
    (5, 'Webcam 4K Ultra HD', 'Video', 149.99, 75.00, 50),
    (6, 'Portable SSD 1TB', 'Storage', 199.99, 95.00, 80),
    (7, 'Gaming Headset Pro', 'Audio', 99.99, 48.00, 60),
    (8, 'Monitor 27" 4K', 'Displays', 499.99, 250.00, 30),
    (9, 'Wireless Charger Pad', 'Accessories', 39.99, 18.00, 180),
    (10, 'Blue Light Glasses', 'Accessories', 34.99, 12.00, 220);

-- ============================================
-- Verify
-- ============================================

SELECT * FROM Products;

-- ============================================
-- Products table created with 10 items!
-- ============================================
