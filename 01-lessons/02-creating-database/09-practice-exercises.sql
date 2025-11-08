-- ============================================================================
-- Lesson 09: Practice Exercises
-- ============================================================================
-- Test your knowledge with these beginner-friendly exercises
-- Prerequisites: Completed Lessons 01-08
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- EXERCISE 1: Create a New Table
-- ============================================================================
-- Create a table called ProductReviews with:
-- - ReviewID (auto-increment primary key)
-- - ProductID (foreign key to Products)
-- - CustomerID (foreign key to Customers)
-- - Rating (1-5)
-- - ReviewText
-- - ReviewDate (default to current date)

-- YOUR CODE HERE:



-- ============================================================================
-- EXERCISE 2: Insert Data
-- ============================================================================
-- Insert 3 categories into Inventory.Categories:
-- - Books
-- - Sports
-- - Toys

-- YOUR CODE HERE:



-- ============================================================================
-- EXERCISE 3: Update Data
-- ============================================================================
-- Update the 'Wireless Mouse' product:
-- - Change the price to $24.99
-- - Increase the quantity in stock to 300

-- YOUR CODE HERE:



-- ============================================================================
-- EXERCISE 4: Simple Query
-- ============================================================================
-- Select all products that:
-- - Are in the Electronics category
-- - Have a price less than $500

-- YOUR CODE HERE:



-- ============================================================================
-- EXERCISE 5: Add a Constraint
-- ============================================================================
-- Add a CHECK constraint to ProductReviews table
-- to ensure Rating is between 1 and 5

-- YOUR CODE HERE:



-- ============================================================================
-- ANSWERS (Scroll down to check your work)
-- ============================================================================

/*

-- Exercise 1:
CREATE TABLE Sales.ProductReviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating INT CHECK (Rating >= 1 AND Rating <= 5),
    ReviewText NVARCHAR(1000),
    ReviewDate DATE DEFAULT CAST(GETDATE() AS DATE),
    FOREIGN KEY (ProductID) REFERENCES Inventory.Products(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID)
);

-- Exercise 2:
INSERT INTO Inventory.Categories (CategoryName)
VALUES ('Books'), ('Sports'), ('Toys');

-- Exercise 3:
UPDATE Inventory.Products
SET Price = 24.99, QuantityInStock = 300
WHERE ProductName = 'Wireless Mouse';

-- Exercise 4:
SELECT ProductName, Price
FROM Inventory.Products
WHERE CategoryID = 1 AND Price < 500;

-- Exercise 5:
-- (Already included in Exercise 1 solution above)

*/
