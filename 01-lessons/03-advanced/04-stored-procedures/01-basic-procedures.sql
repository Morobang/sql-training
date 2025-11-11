-- ========================================
-- Basic Stored Procedures
-- ========================================

USE TechStore;
GO

-- Drop existing procedures
DROP PROCEDURE IF EXISTS usp_GetAllProducts;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory;
DROP PROCEDURE IF EXISTS usp_GetProductDetails;
DROP PROCEDURE IF EXISTS usp_InsertProduct;
DROP PROCEDURE IF EXISTS usp_UpdateProductPrice;
DROP PROCEDURE IF EXISTS usp_DeleteProduct;
DROP PROCEDURE IF EXISTS usp_GetCustomerSummary;
GO

-- =============================================
-- Example 1: Simple SELECT Procedure
-- =============================================

CREATE PROCEDURE usp_GetAllProducts
AS
BEGIN
    SET NOCOUNT ON;  -- Suppress "rows affected" messages
    
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        StockQuantity,
        IsActive
    FROM Products
    ORDER BY ProductName;
END;
GO

-- Execute the procedure
EXEC usp_GetAllProducts;
GO

-- =============================================
-- Example 2: Procedure with Input Parameter
-- =============================================

CREATE PROCEDURE usp_GetProductsByCategory
    @Category NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        StockQuantity
    FROM Products
    WHERE Category = @Category
        AND IsActive = 1
    ORDER BY Price DESC;
END;
GO

-- Execute with parameter (named)
EXEC usp_GetProductsByCategory @Category = 'Electronics';

-- Execute with parameter (positional)
EXEC usp_GetProductsByCategory 'Clothing';
GO

-- =============================================
-- Example 3: Procedure with Multiple Parameters
-- =============================================

CREATE PROCEDURE usp_GetProductDetails
    @ProductID INT,
    @IncludeSales BIT = 0  -- Optional parameter with default value
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get product info
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        Cost,
        StockQuantity,
        IsActive
    FROM Products
    WHERE ProductID = @ProductID;
    
    -- Optionally get sales data
    IF @IncludeSales = 1
    BEGIN
        SELECT 
            SaleID,
            CustomerID,
            Quantity,
            SaleDate,
            TotalAmount
        FROM Sales
        WHERE ProductID = @ProductID
        ORDER BY SaleDate DESC;
    END;
END;
GO

-- Execute without optional parameter (default = 0)
EXEC usp_GetProductDetails @ProductID = 1;

-- Execute with optional parameter
EXEC usp_GetProductDetails @ProductID = 1, @IncludeSales = 1;
GO

-- =============================================
-- Example 4: INSERT Procedure
-- =============================================

CREATE PROCEDURE usp_InsertProduct
    @ProductName NVARCHAR(100),
    @Category NVARCHAR(50),
    @Price DECIMAL(10,2),
    @Cost DECIMAL(10,2),
    @StockQuantity INT,
    @SupplierID INT = NULL  -- Optional
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert new product
    INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, SupplierID, IsActive)
    VALUES (@ProductName, @Category, @Price, @Cost, @StockQuantity, @SupplierID, 1);
    
    -- Return the new ProductID
    SELECT SCOPE_IDENTITY() AS NewProductID;
END;
GO

-- Execute INSERT procedure
DECLARE @NewID INT;
EXEC usp_InsertProduct 
    @ProductName = 'Wireless Keyboard',
    @Category = 'Electronics',
    @Price = 49.99,
    @Cost = 25.00,
    @StockQuantity = 100;
GO

-- =============================================
-- Example 5: UPDATE Procedure
-- =============================================

CREATE PROCEDURE usp_UpdateProductPrice
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if product exists
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        PRINT 'Error: Product not found';
        RETURN -1;  -- Return error code
    END;
    
    -- Update price
    UPDATE Products
    SET Price = @NewPrice
    WHERE ProductID = @ProductID;
    
    PRINT 'Price updated successfully';
    RETURN 0;  -- Return success
END;
GO

-- Execute UPDATE procedure
EXEC usp_UpdateProductPrice @ProductID = 1, @NewPrice = 129.99;

-- Test with non-existent product
EXEC usp_UpdateProductPrice @ProductID = 99999, @NewPrice = 100.00;
GO

-- =============================================
-- Example 6: DELETE Procedure with Validation
-- =============================================

CREATE PROCEDURE usp_DeleteProduct
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if product has sales
    IF EXISTS (SELECT 1 FROM Sales WHERE ProductID = @ProductID)
    BEGIN
        PRINT 'Error: Cannot delete product with existing sales';
        PRINT 'Consider deactivating instead';
        RETURN -1;
    END;
    
    -- Delete product
    DELETE FROM Products WHERE ProductID = @ProductID;
    
    PRINT 'Product deleted successfully';
    RETURN 0;
END;
GO

-- Try to delete a product (likely will fail if it has sales)
EXEC usp_DeleteProduct @ProductID = 1;
GO

-- =============================================
-- Example 7: Procedure with Multiple Result Sets
-- =============================================

CREATE PROCEDURE usp_GetCustomerSummary
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Result set 1: Customer info
    SELECT 
        CustomerID,
        CustomerName,
        State,
        JoinDate,
        TotalPurchases
    FROM Customers
    WHERE CustomerID = @CustomerID;
    
    -- Result set 2: Order history
    SELECT 
        s.SaleID,
        s.SaleDate,
        p.ProductName,
        s.Quantity,
        s.TotalAmount
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
    ORDER BY s.SaleDate DESC;
    
    -- Result set 3: Summary statistics
    SELECT 
        COUNT(s.SaleID) AS TotalOrders,
        SUM(s.TotalAmount) AS TotalSpent,
        AVG(s.TotalAmount) AS AvgOrderValue,
        MAX(s.SaleDate) AS LastPurchaseDate
    FROM Sales s
    WHERE s.CustomerID = @CustomerID;
END;
GO

-- Execute procedure (returns 3 result sets)
EXEC usp_GetCustomerSummary @CustomerID = 1;
GO

-- =============================================
-- Example 8: Procedure with Variables and Logic
-- =============================================

DROP PROCEDURE IF EXISTS usp_ApplyDiscount;
GO

CREATE PROCEDURE usp_ApplyDiscount
    @ProductID INT,
    @DiscountPercent DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentPrice DECIMAL(10,2);
    DECLARE @NewPrice DECIMAL(10,2);
    DECLARE @ProductName NVARCHAR(100);
    
    -- Get current price
    SELECT 
        @CurrentPrice = Price,
        @ProductName = ProductName
    FROM Products
    WHERE ProductID = @ProductID;
    
    -- Check if product exists
    IF @CurrentPrice IS NULL
    BEGIN
        PRINT 'Error: Product not found';
        RETURN -1;
    END;
    
    -- Validate discount
    IF @DiscountPercent <= 0 OR @DiscountPercent > 50
    BEGIN
        PRINT 'Error: Discount must be between 0 and 50 percent';
        RETURN -2;
    END;
    
    -- Calculate new price
    SET @NewPrice = @CurrentPrice * (1 - @DiscountPercent / 100.0);
    
    -- Update price
    UPDATE Products
    SET Price = @NewPrice
    WHERE ProductID = @ProductID;
    
    -- Show result
    PRINT 'Discount applied to: ' + @ProductName;
    PRINT 'Old Price: $' + CAST(@CurrentPrice AS NVARCHAR(20));
    PRINT 'New Price: $' + CAST(@NewPrice AS NVARCHAR(20));
    PRINT 'Savings: ' + CAST(@DiscountPercent AS NVARCHAR(10)) + '%';
    
    RETURN 0;
END;
GO

-- Apply 10% discount
EXEC usp_ApplyDiscount @ProductID = 1, @DiscountPercent = 10;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP PROCEDURE IF EXISTS usp_GetAllProducts;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory;
DROP PROCEDURE IF EXISTS usp_GetProductDetails;
DROP PROCEDURE IF EXISTS usp_InsertProduct;
DROP PROCEDURE IF EXISTS usp_UpdateProductPrice;
DROP PROCEDURE IF EXISTS usp_DeleteProduct;
DROP PROCEDURE IF EXISTS usp_GetCustomerSummary;
DROP PROCEDURE IF EXISTS usp_ApplyDiscount;
*/

-- 💡 Key Points:
-- - SET NOCOUNT ON prevents "rows affected" messages
-- - Parameters can have default values
-- - RETURN statement returns integer status code (0 = success)
-- - SCOPE_IDENTITY() returns last inserted identity value
-- - Procedures can return multiple result sets
-- - Use variables for complex logic
-- - Always validate input parameters
-- - PRINT for debugging and user messages
-- - Use meaningful names (usp_ prefix = user stored procedure)
