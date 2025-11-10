-- ============================================
-- Intermediate Lesson 1.5: Create Sales Table
-- ============================================
-- Track customer purchases!
-- ============================================

USE TechStore;

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    SaleDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2),
    PaymentMethod VARCHAR(20),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- ============================================
-- Insert sample sales
-- ============================================

INSERT INTO Sales (SaleID, CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES 
    (1, 1, 1, 2, '2024-11-01', 99.98, 'Credit Card'),
    (2, 1, 3, 1, '2024-11-01', 79.99, 'Credit Card'),
    (3, 2, 2, 1, '2024-11-05', 129.99, 'Debit Card'),
    (4, 2, 5, 1, '2024-11-05', 149.99, 'Debit Card'),
    (5, 1, 7, 1, '2024-11-08', 99.99, 'PayPal'),
    (6, 2, 4, 2, '2024-11-10', 119.98, 'Credit Card');

-- ============================================
-- Verify
-- ============================================

SELECT * FROM Sales;

-- ============================================
-- Sales table created with 6 transactions!
-- ============================================
