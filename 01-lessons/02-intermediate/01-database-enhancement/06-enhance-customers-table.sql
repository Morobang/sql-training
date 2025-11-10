-- ============================================
-- Intermediate Lesson 1.6: Update Customers with More Details
-- ============================================
-- Enhance the Customers table from beginner
-- ============================================

USE TechStore;

-- Add more customer information
ALTER TABLE Customers
ADD City VARCHAR(50);

ALTER TABLE Customers
ADD State VARCHAR(2);

ALTER TABLE Customers
ADD JoinDate DATE;

ALTER TABLE Customers
ADD TotalPurchases DECIMAL(10,2) DEFAULT 0.00;

-- ============================================
-- Update existing customers with sample data
-- ============================================

UPDATE Customers SET City = 'New York', State = 'NY', JoinDate = '2024-01-15' WHERE CustomerID = 1;
UPDATE Customers SET City = 'Los Angeles', State = 'CA', JoinDate = '2024-02-20' WHERE CustomerID = 2;

-- ============================================
-- Add more customers
-- ============================================

INSERT INTO Customers (CustomerID, FirstName, LastName, Email, City, State, JoinDate)
VALUES 
    (3, 'Mike', 'Williams', 'mike@email.com', 'Chicago', 'IL', '2024-03-10'),
    (4, 'Emma', 'Davis', 'emma@email.com', 'Houston', 'TX', '2024-04-05'),
    (5, 'James', 'Martinez', 'james@email.com', 'Phoenix', 'AZ', '2024-05-12');

-- ============================================
-- Verify
-- ============================================

SELECT * FROM Customers;

-- ============================================
-- Customers table enhanced with location and date info!
-- ============================================
