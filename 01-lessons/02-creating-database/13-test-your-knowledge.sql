-- ============================================================================
-- Lesson 13: Test Your Knowledge
-- ============================================================================
-- Comprehensive exercises covering all Chapter 02 concepts
-- Prerequisites: Complete Lessons 01-12

USE BookStore;
GO

PRINT 'Lesson 13: Test Your Knowledge';
PRINT '==============================';
PRINT '';
PRINT 'This lesson contains practice exercises covering:';
PRINT '  • Database creation and management';
PRINT '  • Data types (character, numeric, temporal)';
PRINT '  • Table creation and constraints';
PRINT '  • Data insertion, retrieval, updates, and deletion';
PRINT '';

-- ============================================================================
-- EXERCISE SET 1: Database and Table Creation
-- ============================================================================

PRINT 'Exercise Set 1: Database and Table Creation';
PRINT '===========================================';
PRINT '';
PRINT '1. Create a database named LibraryDB';
PRINT '2. Create Authors table: AuthorID (PK, IDENTITY), AuthorName (NOT NULL, UNIQUE)';
PRINT '3. Create Books table with:';
PRINT '   - BookID (PK, IDENTITY)';
PRINT '   - Title (NVARCHAR(200), NOT NULL)';
PRINT '   - ISBN (NVARCHAR(20), UNIQUE)';
PRINT '   - Price (DECIMAL(10,2), CHECK >= 0)';
PRINT '   - PublishDate (DATE)';
PRINT '   - AuthorID (FK to Authors)';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
CREATE DATABASE LibraryDB;
GO

USE LibraryDB;
GO

CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY IDENTITY(1,1),
    AuthorName NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    ISBN NVARCHAR(20) UNIQUE,
    Price DECIMAL(10,2) CHECK (Price >= 0),
    PublishDate DATE,
    AuthorID INT,
    CONSTRAINT FK_Books_Authors FOREIGN KEY (AuthorID) 
        REFERENCES Authors(AuthorID)
);
*/

-- ============================================================================
-- EXERCISE SET 2: Data Insertion
-- ============================================================================

PRINT 'Exercise Set 2: Data Insertion';
PRINT '==============================';
PRINT '';
PRINT '1. Insert 3 authors into Authors table';
PRINT '2. Insert 5 books into Books table (use different authors)';
PRINT '3. Insert 3 more books in a single INSERT statement';
PRINT '';

-- SOLUTIONS:
/*
INSERT INTO Authors (AuthorName) VALUES (N'George Orwell');
INSERT INTO Authors (AuthorName) VALUES (N'Jane Austen');
INSERT INTO Authors (AuthorName) VALUES (N'Mark Twain');

INSERT INTO Books (Title, ISBN, Price, PublishDate, AuthorID) VALUES
    (N'1984', N'978-0451524935', 15.99, '1949-06-08', 1),
    (N'Animal Farm', N'978-0451526342', 12.99, '1945-08-17', 1),
    (N'Pride and Prejudice', N'978-0141439518', 11.99, '1813-01-28', 2),
    (N'Emma', N'978-0141439587', 10.99, '1815-12-23', 2),
    (N'Tom Sawyer', N'978-0486400778', 8.99, '1876-06-01', 3);

INSERT INTO Books (Title, ISBN, Price, PublishDate, AuthorID) VALUES
    (N'Sense and Sensibility', N'978-0141439662', 11.99, '1811-10-30', 2),
    (N'Huckleberry Finn', N'978-0486280615', 9.99, '1884-12-10', 3),
    (N'Coming Up for Air', N'978-0156207508', 13.99, '1939-06-12', 1);
*/

-- ============================================================================
-- EXERCISE SET 3: Data Retrieval
-- ============================================================================

PRINT 'Exercise Set 3: Data Retrieval';
PRINT '==============================';
PRINT '';
PRINT '1. SELECT all books with their author names';
PRINT '2. SELECT books published after 1900';
PRINT '3. SELECT author name and count of books they wrote';
PRINT '4. SELECT books priced between $10 and $15';
PRINT '5. SELECT most expensive book';
PRINT '';

-- SOLUTIONS:
/*
-- Query 1
SELECT 
    b.Title,
    b.ISBN,
    b.Price,
    a.AuthorName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID;

-- Query 2
SELECT Title, PublishDate
FROM Books
WHERE PublishDate > '1900-01-01'
ORDER BY PublishDate;

-- Query 3
SELECT 
    a.AuthorName,
    COUNT(b.BookID) AS BookCount
FROM Authors a
LEFT JOIN Books b ON a.AuthorID = b.AuthorID
GROUP BY a.AuthorName;

-- Query 4
SELECT Title, Price
FROM Books
WHERE Price BETWEEN 10 AND 15
ORDER BY Price;

-- Query 5
SELECT TOP 1 Title, Price
FROM Books
ORDER BY Price DESC;
*/

-- ============================================================================
-- EXERCISE SET 4: Data Updates
-- ============================================================================

PRINT 'Exercise Set 4: Data Updates';
PRINT '============================';
PRINT '';
PRINT '1. Increase all book prices by 10%';
PRINT '2. Update specific book ISBN';
PRINT '3. Update books published before 1850 - add "Classic" to title';
PRINT '';

-- SOLUTIONS:
/*
-- Update 1
UPDATE Books
SET Price = Price * 1.10;

SELECT Title, Price FROM Books;

-- Update 2
UPDATE Books
SET ISBN = N'978-NEW-ISBN-123'
WHERE BookID = 1;

-- Update 3
UPDATE Books
SET Title = N'[Classic] ' + Title
WHERE PublishDate < '1850-01-01' AND Title NOT LIKE '[Classic]%';

SELECT Title, PublishDate FROM Books;
*/

-- ============================================================================
-- EXERCISE SET 5: Table Modification
-- ============================================================================

PRINT 'Exercise Set 5: Table Modification';
PRINT '==================================';
PRINT '';
PRINT '1. Add InStock column (BIT, DEFAULT 1) to Books';
PRINT '2. Add PageCount column (INT) to Books';
PRINT '3. Add CHECK constraint: PageCount > 0';
PRINT '4. Update some books to set PageCount';
PRINT '';

-- SOLUTIONS:
/*
-- Modification 1
ALTER TABLE Books
ADD InStock BIT DEFAULT 1;

-- Modification 2
ALTER TABLE Books
ADD PageCount INT;

-- Modification 3
ALTER TABLE Books
ADD CONSTRAINT CK_Books_PageCount CHECK (PageCount > 0);

-- Modification 4
UPDATE Books SET PageCount = 328 WHERE Title LIKE '%1984%';
UPDATE Books SET PageCount = 112 WHERE Title LIKE '%Animal Farm%';
UPDATE Books SET PageCount = 279 WHERE Title LIKE '%Pride%';

SELECT Title, PageCount, InStock FROM Books;
*/

-- ============================================================================
-- EXERCISE SET 6: Data Deletion
-- ============================================================================

PRINT 'Exercise Set 6: Data Deletion';
PRINT '=============================';
PRINT '';
PRINT '1. Create a Members table (MemberID, Name, JoinDate, Status)';
PRINT '2. Insert 5 members with various join dates and statuses';
PRINT '3. DELETE members who joined before 2020';
PRINT '4. DELETE members with Status = ''Inactive''';
PRINT '';

-- SOLUTIONS:
/*
CREATE TABLE Members (
    MemberID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100),
    JoinDate DATE,
    Status NVARCHAR(20)
);

INSERT INTO Members (Name, JoinDate, Status) VALUES
    (N'Alice Johnson', '2018-05-15', N'Active'),
    (N'Bob Smith', '2020-07-20', N'Active'),
    (N'Carol Williams', '2019-03-10', N'Inactive'),
    (N'David Brown', '2021-09-05', N'Active'),
    (N'Eve Davis', '2022-01-12', N'Inactive');

SELECT * FROM Members;

-- Delete old members
DELETE FROM Members WHERE JoinDate < '2020-01-01';
SELECT * FROM Members;

-- Delete inactive members
DELETE FROM Members WHERE Status = N'Inactive';
SELECT * FROM Members;

DROP TABLE Members;
*/

-- ============================================================================
-- CHALLENGE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Challenge Exercises';
PRINT '===================';
PRINT '';
PRINT 'CHALLENGE 1: Create a complete library checkout system';
PRINT '  - Members table (MemberID, Name, Email, JoinDate)';
PRINT '  - Checkouts table (CheckoutID, BookID, MemberID, CheckoutDate, ReturnDate)';
PRINT '  - Add appropriate constraints and relationships';
PRINT '  - Insert test data';
PRINT '  - Query: Find all overdue books (ReturnDate NULL and CheckoutDate > 14 days ago)';
PRINT '';
PRINT 'CHALLENGE 2: Create book ratings system';
PRINT '  - Add Ratings table (RatingID, BookID, MemberID, Rating 1-5, ReviewDate)';
PRINT '  - Query: Average rating per book';
PRINT '  - Query: Books with rating > 4.0';
PRINT '';
PRINT 'CHALLENGE 3: Inventory management';
PRINT '  - Add QuantityInStock column to Books';
PRINT '  - Create procedure to "checkout" book (decrease quantity)';
PRINT '  - Create procedure to "return" book (increase quantity)';
PRINT '  - Add CHECK constraint: QuantityInStock >= 0';
PRINT '';

-- SOLUTIONS:
/*
-- CHALLENGE 1
CREATE TABLE Members (
    MemberID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    JoinDate DATE DEFAULT CAST(GETDATE() AS DATE)
);

CREATE TABLE Checkouts (
    CheckoutID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT NOT NULL,
    MemberID INT NOT NULL,
    CheckoutDate DATE DEFAULT CAST(GETDATE() AS DATE),
    ReturnDate DATE NULL,
    CONSTRAINT FK_Checkouts_Books FOREIGN KEY (BookID) REFERENCES Books(BookID),
    CONSTRAINT FK_Checkouts_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

INSERT INTO Members (Name, Email) VALUES
    (N'Alice Johnson', N'alice@email.com'),
    (N'Bob Smith', N'bob@email.com');

INSERT INTO Checkouts (BookID, MemberID, CheckoutDate, ReturnDate) VALUES
    (1, 1, '2025-01-01', '2025-01-10'),
    (2, 1, '2025-01-20', NULL),  -- Still checked out
    (3, 2, '2024-12-15', NULL);  -- Overdue!

-- Overdue books query
SELECT 
    m.Name AS Member,
    b.Title AS Book,
    c.CheckoutDate,
    DATEDIFF(DAY, c.CheckoutDate, GETDATE()) AS DaysOut
FROM Checkouts c
JOIN Books b ON c.BookID = b.BookID
JOIN Members m ON c.MemberID = m.MemberID
WHERE c.ReturnDate IS NULL 
  AND DATEDIFF(DAY, c.CheckoutDate, GETDATE()) > 14;

-- CHALLENGE 2
CREATE TABLE Ratings (
    RatingID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT NOT NULL,
    MemberID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewDate DATE DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Ratings_Books FOREIGN KEY (BookID) REFERENCES Books(BookID),
    CONSTRAINT FK_Ratings_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

INSERT INTO Ratings (BookID, MemberID, Rating) VALUES
    (1, 1, 5), (1, 2, 4),
    (2, 1, 5), (2, 2, 5),
    (3, 1, 3);

-- Average rating per book
SELECT 
    b.Title,
    AVG(CAST(r.Rating AS DECIMAL(3,2))) AS AvgRating,
    COUNT(r.RatingID) AS RatingCount
FROM Books b
LEFT JOIN Ratings r ON b.BookID = r.BookID
GROUP BY b.Title
HAVING COUNT(r.RatingID) > 0
ORDER BY AvgRating DESC;

-- Books with rating > 4.0
SELECT 
    b.Title,
    AVG(CAST(r.Rating AS DECIMAL(3,2))) AS AvgRating
FROM Books b
JOIN Ratings r ON b.BookID = r.BookID
GROUP BY b.BookID, b.Title
HAVING AVG(CAST(r.Rating AS DECIMAL(3,2))) > 4.0;
*/

-- ============================================================================
-- CLEANUP
-- ============================================================================

PRINT '';
PRINT 'To clean up test database:';
PRINT '  USE master;';
PRINT '  DROP DATABASE IF EXISTS LibraryDB;';
PRINT '';

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 13 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Congratulations! You have completed Chapter 02: Creating Databases and Tables!';
PRINT '';
PRINT 'You have learned:';
PRINT '  ✓ Database creation and management';
PRINT '  ✓ Character, numeric, and temporal data types';
PRINT '  ✓ Table creation with constraints';
PRINT '  ✓ Primary and foreign keys';
PRINT '  ✓ INSERT, SELECT, UPDATE, DELETE operations';
PRINT '  ✓ Table modifications';
PRINT '  ✓ Best practices for data management';
PRINT '';
PRINT 'Next Chapter: Querying Data (Filtering, Joins, Aggregation)';
PRINT '';
