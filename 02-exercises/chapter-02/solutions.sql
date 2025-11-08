-- ============================================================================
-- Chapter 02: Creating and Populating a Database - Exercise Solutions
-- ============================================================================
-- Complete solutions with explanations and alternative approaches

USE BookStore;
GO

PRINT '========================================';
PRINT 'Chapter 02 Exercise Solutions';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- EXERCISE SET 1: Database and Data Types
-- ============================================================================

PRINT 'Exercise Set 1: Database and Data Types';
PRINT '========================================';
PRINT '';

-- Exercise 1.1: Create a database for a movie rental system
PRINT 'Solution 1.1: Create MovieRental database';
GO

IF DB_ID('MovieRental') IS NOT NULL
BEGIN
    USE master;
    DROP DATABASE MovieRental;
END;
GO

CREATE DATABASE MovieRental
ON PRIMARY 
(
    NAME = MovieRental_Data,
    FILENAME = 'C:\SQLData\MovieRental_Data.mdf',
    SIZE = 100MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = MovieRental_Log,
    FILENAME = 'C:\SQLData\MovieRental_Log.ldf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 5MB
);
GO

PRINT '✓ MovieRental database created';
PRINT '';

-- Exercise 1.2: Choose appropriate data types
PRINT 'Solution 1.2: Data types for movie rental system';
GO

USE MovieRental;
GO

CREATE TABLE Movies (
    MovieID INT PRIMARY KEY IDENTITY(1,1),              -- Auto-incrementing ID
    Title NVARCHAR(200) NOT NULL,                       -- Unicode for international titles
    Director VARCHAR(100),                               -- ASCII sufficient for names
    ReleaseYear SMALLINT NOT NULL,                      -- Years fit in SMALLINT (saves space)
    Duration INT NOT NULL,                              -- Minutes as integer
    Rating CHAR(5),                                     -- Fixed: 'PG-13', 'R', 'G' etc
    Price DECIMAL(5, 2) NOT NULL,                       -- Exact decimal for money
    IsAvailable BIT DEFAULT 1,                          -- Boolean flag
    AddedDate DATETIME2 DEFAULT SYSDATETIME(),          -- High precision date/time
    Description NVARCHAR(MAX)                           -- Large text field
);
GO

PRINT '✓ Movies table created with appropriate data types';
PRINT '';
PRINT 'Explanation:';
PRINT '  - NVARCHAR for international text (titles)';
PRINT '  - VARCHAR for ASCII-only text (director names)';
PRINT '  - SMALLINT for years (range -32,768 to 32,767)';
PRINT '  - DECIMAL(5,2) for prices (exact values, max 999.99)';
PRINT '  - BIT for true/false flags';
PRINT '  - DATETIME2 for timestamps (better precision than DATETIME)';
PRINT '';

-- Exercise 1.3: Create supporting tables
PRINT 'Solution 1.3: Supporting tables';
GO

CREATE TABLE Members (
    MemberID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    JoinDate DATE DEFAULT CAST(GETDATE() AS DATE),
    MembershipType VARCHAR(20) CHECK (MembershipType IN ('Basic', 'Premium', 'VIP'))
);
GO

CREATE TABLE Rentals (
    RentalID INT PRIMARY KEY IDENTITY(1,1),
    MemberID INT NOT NULL,
    MovieID INT NOT NULL,
    RentalDate DATETIME2 DEFAULT SYSDATETIME(),
    DueDate DATE NOT NULL,
    ReturnDate DATETIME2 NULL,
    LateFee DECIMAL(6, 2) DEFAULT 0.00,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);
GO

PRINT '✓ Members and Rentals tables created';
PRINT '';

-- ============================================================================
-- EXERCISE SET 2: Table Design and Normalization
-- ============================================================================

PRINT 'Exercise Set 2: Table Design and Normalization';
PRINT '========================================';
PRINT '';

-- Exercise 2.1: Identify normalization issues
PRINT 'Solution 2.1: Unnormalized student schedule';
GO

-- Unnormalized (bad design)
CREATE TABLE StudentSchedule_Unnormalized (
    StudentID INT,
    StudentName VARCHAR(100),
    Course1 VARCHAR(50),
    Course2 VARCHAR(50),
    Course3 VARCHAR(50),
    Professor1 VARCHAR(50),
    Professor2 VARCHAR(50),
    Professor3 VARCHAR(50)
);
GO

PRINT 'Issues with unnormalized design:';
PRINT '  ✗ Repeating groups (Course1, Course2, Course3)';
PRINT '  ✗ Fixed number of courses (what if student takes 4?)';
PRINT '  ✗ Data redundancy (student name repeated)';
PRINT '  ✗ Update anomalies (change name in many places)';
PRINT '  ✗ NULL values if student takes fewer courses';
PRINT '';

-- Exercise 2.2: Normalize to 3NF
PRINT 'Solution 2.2: Normalized design (3NF)';
GO

-- 1NF: Eliminate repeating groups
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    StudentName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Major VARCHAR(50)
);
GO

CREATE TABLE Professors (
    ProfessorID INT PRIMARY KEY IDENTITY(1,1),
    ProfessorName VARCHAR(100) NOT NULL,
    Department VARCHAR(50),
    Email VARCHAR(100) UNIQUE
);
GO

CREATE TABLE Courses (
    CourseID INT PRIMARY KEY IDENTITY(1,1),
    CourseCode VARCHAR(20) NOT NULL UNIQUE,
    CourseName VARCHAR(100) NOT NULL,
    ProfessorID INT NOT NULL,
    Credits INT NOT NULL,
    FOREIGN KEY (ProfessorID) REFERENCES Professors(ProfessorID)
);
GO

-- Junction table (many-to-many: students <-> courses)
CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Grade CHAR(2),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    UNIQUE (StudentID, CourseID)  -- Student can't enroll in same course twice
);
GO

PRINT '✓ Normalized database (3NF) created';
PRINT '';
PRINT 'Benefits of normalization:';
PRINT '  ✓ No repeating groups';
PRINT '  ✓ No limit on courses per student';
PRINT '  ✓ No data redundancy';
PRINT '  ✓ Easy to update/delete';
PRINT '  ✓ Referential integrity enforced';
PRINT '';

-- Exercise 2.3: Insert sample data
PRINT 'Solution 2.3: Insert sample data';
GO

INSERT INTO Professors (ProfessorName, Department, Email) VALUES 
    ('Dr. Smith', 'Computer Science', 'smith@university.edu'),
    ('Dr. Johnson', 'Mathematics', 'johnson@university.edu');
GO

INSERT INTO Students (StudentName, Email, Major) VALUES 
    ('Alice Brown', 'alice@student.edu', 'Computer Science'),
    ('Bob Wilson', 'bob@student.edu', 'Mathematics');
GO

INSERT INTO Courses (CourseCode, CourseName, ProfessorID, Credits) VALUES 
    ('CS101', 'Introduction to Programming', 1, 3),
    ('MATH201', 'Calculus I', 2, 4),
    ('CS201', 'Data Structures', 1, 3);
GO

INSERT INTO Enrollments (StudentID, CourseID, Grade) VALUES 
    (1, 1, 'A'),   -- Alice in CS101
    (1, 3, 'B+'),  -- Alice in CS201
    (2, 2, 'A-'),  -- Bob in MATH201
    (2, 1, 'B');   -- Bob in CS101
GO

-- Query to reconstruct student schedule
SELECT 
    s.StudentName,
    c.CourseCode,
    c.CourseName,
    p.ProfessorName,
    e.Grade
FROM Students s
INNER JOIN Enrollments e ON s.StudentID = e.StudentID
INNER JOIN Courses c ON e.CourseID = c.CourseID
INNER JOIN Professors p ON c.ProfessorID = p.ProfessorID
ORDER BY s.StudentName, c.CourseCode;
GO

PRINT '✓ Sample data inserted and queried';
PRINT '';

-- ============================================================================
-- EXERCISE SET 3: Constraints and Data Integrity
-- ============================================================================

PRINT 'Exercise Set 3: Constraints and Data Integrity';
PRINT '========================================';
PRINT '';

-- Exercise 3.1: Add constraints to existing tables
PRINT 'Solution 3.1: Add constraints to Movies table';
GO

USE MovieRental;
GO

ALTER TABLE Movies
ADD CONSTRAINT CK_Movies_ReleaseYear 
CHECK (ReleaseYear BETWEEN 1900 AND YEAR(GETDATE()) + 2);  -- Allow future releases
GO

ALTER TABLE Movies
ADD CONSTRAINT CK_Movies_Duration 
CHECK (Duration BETWEEN 1 AND 600);  -- 1 minute to 10 hours
GO

ALTER TABLE Movies
ADD CONSTRAINT CK_Movies_Price 
CHECK (Price BETWEEN 0.00 AND 99.99);
GO

ALTER TABLE Movies
ADD CONSTRAINT DF_Movies_IsAvailable 
DEFAULT 1 FOR IsAvailable;
GO

PRINT '✓ Constraints added to Movies table';
PRINT '';

-- Exercise 3.2: Test constraints
PRINT 'Solution 3.2: Test constraints';
GO

-- Test 1: Valid insert
BEGIN TRY
    INSERT INTO Movies (Title, Director, ReleaseYear, Duration, Rating, Price)
    VALUES ('Test Movie', 'Test Director', 2024, 120, 'PG-13', 4.99);
    PRINT '✓ Test 1 PASSED: Valid data accepted';
    DELETE FROM Movies WHERE Title = 'Test Movie';
END TRY
BEGIN CATCH
    PRINT '✗ Test 1 FAILED: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test 2: Invalid year (too old)
BEGIN TRY
    INSERT INTO Movies (Title, Director, ReleaseYear, Duration, Rating, Price)
    VALUES ('Ancient Movie', 'Unknown', 1850, 120, 'G', 1.99);
    PRINT '✗ Test 2 FAILED: Should have rejected invalid year';
END TRY
BEGIN CATCH
    PRINT '✓ Test 2 PASSED: Correctly rejected invalid year';
END CATCH;
GO

-- Test 3: Invalid price (negative)
BEGIN TRY
    INSERT INTO Movies (Title, Director, ReleaseYear, Duration, Rating, Price)
    VALUES ('Free Movie', 'Someone', 2024, 90, 'G', -1.00);
    PRINT '✗ Test 3 FAILED: Should have rejected negative price';
END TRY
BEGIN CATCH
    PRINT '✓ Test 3 PASSED: Correctly rejected negative price';
END CATCH;
GO

PRINT '';

-- Exercise 3.3: Create computed columns
PRINT 'Solution 3.3: Computed columns';
GO

ALTER TABLE Rentals
ADD DaysRented AS DATEDIFF(DAY, RentalDate, COALESCE(ReturnDate, GETDATE()));
GO

ALTER TABLE Rentals
ADD IsOverdue AS 
    CASE 
        WHEN ReturnDate IS NULL AND CAST(GETDATE() AS DATE) > DueDate THEN 1
        ELSE 0
    END;
GO

PRINT '✓ Computed columns added to Rentals';
PRINT '';

-- ============================================================================
-- EXERCISE SET 4: Inserting Data
-- ============================================================================

PRINT 'Exercise Set 4: Inserting Data';
PRINT '========================================';
PRINT '';

-- Exercise 4.1: Insert movie data
PRINT 'Solution 4.1: Insert movie catalog';
GO

INSERT INTO Movies (Title, Director, ReleaseYear, Duration, Rating, Price)
VALUES 
    ('The Matrix', 'Wachowski Brothers', 1999, 136, 'R', 3.99),
    ('Inception', 'Christopher Nolan', 2010, 148, 'PG-13', 4.99),
    ('The Shawshank Redemption', 'Frank Darabont', 1994, 142, 'R', 3.99),
    ('Pulp Fiction', 'Quentin Tarantino', 1994, 154, 'R', 3.99),
    ('The Dark Knight', 'Christopher Nolan', 2008, 152, 'PG-13', 4.99);
GO

PRINT '✓ ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' movies inserted';
GO

-- Exercise 4.2: Insert members
PRINT 'Solution 4.2: Insert members';
GO

INSERT INTO Members (FirstName, LastName, Email, Phone, MembershipType)
VALUES 
    ('John', 'Doe', 'john.doe@email.com', '555-0101', 'Premium'),
    ('Jane', 'Smith', 'jane.smith@email.com', '555-0102', 'Basic'),
    ('Bob', 'Johnson', 'bob.j@email.com', '555-0103', 'VIP');
GO

PRINT '✓ ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' members inserted';
GO

-- Exercise 4.3: Insert rentals with OUTPUT
PRINT 'Solution 4.3: Insert rentals with OUTPUT';
GO

DECLARE @NewRentals TABLE (
    RentalID INT,
    MemberName VARCHAR(100),
    MovieTitle NVARCHAR(200),
    RentalDate DATETIME2
);

-- Insert and capture details
INSERT INTO Rentals (MemberID, MovieID, DueDate)
OUTPUT 
    INSERTED.RentalID,
    (SELECT FirstName + ' ' + LastName FROM Members WHERE MemberID = INSERTED.MemberID),
    (SELECT Title FROM Movies WHERE MovieID = INSERTED.MovieID),
    INSERTED.RentalDate
INTO @NewRentals
VALUES 
    (1, 1, DATEADD(DAY, 7, GETDATE())),  -- John rents The Matrix
    (2, 2, DATEADD(DAY, 7, GETDATE()));  -- Jane rents Inception
GO

PRINT '✓ Rentals inserted with OUTPUT clause';
PRINT '';

-- ============================================================================
-- EXERCISE SET 5: Updating Data
-- ============================================================================

PRINT 'Exercise Set 5: Updating Data';
PRINT '========================================';
PRINT '';

-- Exercise 5.1: Update movie prices
PRINT 'Solution 5.1: Update prices based on release year';
GO

UPDATE Movies
SET Price = CASE 
    WHEN ReleaseYear >= 2020 THEN Price * 1.20  -- 20% increase for new movies
    WHEN ReleaseYear >= 2010 THEN Price * 1.10  -- 10% increase for recent
    ELSE Price * 1.00                            -- Keep old prices same
END;
GO

PRINT '✓ ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' movie prices updated';
GO

-- Exercise 5.2: Process returns
PRINT 'Solution 5.2: Process movie returns';
GO

UPDATE Rentals
SET 
    ReturnDate = SYSDATETIME(),
    LateFee = CASE 
        WHEN CAST(GETDATE() AS DATE) > DueDate 
        THEN DATEDIFF(DAY, DueDate, CAST(GETDATE() AS DATE)) * 2.00  -- $2/day late
        ELSE 0.00
    END
WHERE RentalID = 1;
GO

PRINT '✓ Return processed with late fee calculation';
GO

-- Exercise 5.3: Update availability
PRINT 'Solution 5.3: Update movie availability';
GO

-- Mark as unavailable if currently rented
UPDATE m
SET m.IsAvailable = 0
FROM Movies m
INNER JOIN Rentals r ON m.MovieID = r.MovieID
WHERE r.ReturnDate IS NULL;
GO

PRINT '✓ Movie availability updated based on rentals';
PRINT '';

-- ============================================================================
-- EXERCISE SET 6: Deleting Data
-- ============================================================================

PRINT 'Exercise Set 6: Deleting Data';
PRINT '========================================';
PRINT '';

-- Exercise 6.1: Delete old rentals
PRINT 'Solution 6.1: Archive and delete old rentals';
GO

-- Create archive table
IF OBJECT_ID('RentalsArchive', 'U') IS NOT NULL
    DROP TABLE RentalsArchive;
GO

SELECT * INTO RentalsArchive 
FROM Rentals
WHERE ReturnDate < DATEADD(YEAR, -1, GETDATE());
GO

-- Delete archived records
DELETE FROM Rentals
WHERE ReturnDate < DATEADD(YEAR, -1, GETDATE());
GO

PRINT '✓ Old rentals archived and deleted';
GO

-- Exercise 6.2: Implement soft delete
PRINT 'Solution 6.2: Soft delete for members';
GO

-- Add soft delete column
ALTER TABLE Members
ADD IsDeleted BIT DEFAULT 0;
GO

-- Soft delete instead of hard delete
UPDATE Members
SET IsDeleted = 1
WHERE MemberID = 3;
GO

PRINT '✓ Member soft-deleted (can be restored)';
PRINT '';

-- ============================================================================
-- EXERCISE SET 7: Complex Queries
-- ============================================================================

PRINT 'Exercise Set 7: Complex Queries';
PRINT '========================================';
PRINT '';

-- Exercise 7.1: Most popular movies
PRINT 'Solution 7.1: Find most rented movies';
GO

SELECT TOP 5
    m.Title,
    m.Director,
    COUNT(r.RentalID) AS TimesRented,
    AVG(DATEDIFF(DAY, r.RentalDate, COALESCE(r.ReturnDate, GETDATE()))) AS AvgRentalDays
FROM Movies m
LEFT JOIN Rentals r ON m.MovieID = r.MovieID
GROUP BY m.MovieID, m.Title, m.Director
ORDER BY TimesRented DESC;
GO

-- Exercise 7.2: Member rental history
PRINT 'Solution 7.2: Complete rental history for members';
GO

SELECT 
    mem.FirstName + ' ' + mem.LastName AS MemberName,
    mem.MembershipType,
    m.Title,
    r.RentalDate,
    r.DueDate,
    r.ReturnDate,
    CASE 
        WHEN r.ReturnDate IS NULL AND CAST(GETDATE() AS DATE) > r.DueDate THEN 'OVERDUE'
        WHEN r.ReturnDate IS NULL THEN 'Rented'
        ELSE 'Returned'
    END AS Status,
    r.LateFee
FROM Members mem
LEFT JOIN Rentals r ON mem.MemberID = r.MemberID
LEFT JOIN Movies m ON r.MovieID = m.MovieID
WHERE mem.IsDeleted = 0
ORDER BY mem.MemberID, r.RentalDate DESC;
GO

-- Exercise 7.3: Revenue report
PRINT 'Solution 7.3: Revenue report';
GO

SELECT 
    YEAR(r.RentalDate) AS RentalYear,
    MONTH(r.RentalDate) AS RentalMonth,
    COUNT(r.RentalID) AS TotalRentals,
    SUM(m.Price) AS RentalRevenue,
    SUM(r.LateFee) AS LateFeeRevenue,
    SUM(m.Price) + SUM(r.LateFee) AS TotalRevenue
FROM Rentals r
INNER JOIN Movies m ON r.MovieID = m.MovieID
GROUP BY YEAR(r.RentalDate), MONTH(r.RentalDate)
ORDER BY RentalYear DESC, RentalMonth DESC;
GO

PRINT '';

-- ============================================================================
-- EXERCISE SET 8: Advanced Challenges
-- ============================================================================

PRINT 'Exercise Set 8: Advanced Challenges';
PRINT '========================================';
PRINT '';

-- Exercise 8.1: Create view for available movies
PRINT 'Solution 8.1: Available movies view';
GO

CREATE VIEW vw_AvailableMovies AS
SELECT 
    m.MovieID,
    m.Title,
    m.Director,
    m.ReleaseYear,
    m.Rating,
    m.Price,
    COUNT(r.RentalID) AS TotalRentals
FROM Movies m
LEFT JOIN Rentals r ON m.MovieID = r.MovieID
WHERE m.IsAvailable = 1
GROUP BY m.MovieID, m.Title, m.Director, m.ReleaseYear, m.Rating, m.Price;
GO

SELECT * FROM vw_AvailableMovies;
GO

-- Exercise 8.2: Create stored procedure
PRINT 'Solution 8.2: Rent movie stored procedure';
GO

CREATE PROCEDURE sp_RentMovie
    @MemberID INT,
    @MovieID INT,
    @DaysToRent INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Check if movie is available
            IF NOT EXISTS (SELECT 1 FROM Movies WHERE MovieID = @MovieID AND IsAvailable = 1)
            BEGIN
                RAISERROR('Movie is not available', 16, 1);
                RETURN;
            END;
            
            -- Check if member exists
            IF NOT EXISTS (SELECT 1 FROM Members WHERE MemberID = @MemberID AND IsDeleted = 0)
            BEGIN
                RAISERROR('Invalid member', 16, 1);
                RETURN;
            END;
            
            -- Create rental
            DECLARE @DueDate DATE = DATEADD(DAY, @DaysToRent, CAST(GETDATE() AS DATE));
            
            INSERT INTO Rentals (MemberID, MovieID, DueDate)
            VALUES (@MemberID, @MovieID, @DueDate);
            
            -- Update movie availability
            UPDATE Movies SET IsAvailable = 0 WHERE MovieID = @MovieID;
            
            -- Return rental details
            SELECT 
                r.RentalID,
                mem.FirstName + ' ' + mem.LastName AS MemberName,
                m.Title AS MovieTitle,
                r.RentalDate,
                r.DueDate,
                m.Price
            FROM Rentals r
            INNER JOIN Members mem ON r.MemberID = mem.MemberID
            INNER JOIN Movies m ON r.MovieID = m.MovieID
            WHERE r.RentalID = SCOPE_IDENTITY();
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

PRINT '✓ sp_RentMovie procedure created';
GO

-- Test the procedure
-- EXEC sp_RentMovie @MemberID = 1, @MovieID = 3, @DaysToRent = 7;
-- GO

-- Exercise 8.3: Create trigger for audit
PRINT 'Solution 8.3: Audit trigger';
GO

CREATE TABLE MoviePriceAudit (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    MovieID INT NOT NULL,
    OldPrice DECIMAL(5,2),
    NewPrice DECIMAL(5,2),
    ChangedBy VARCHAR(50) DEFAULT SUSER_NAME(),
    ChangedDate DATETIME2 DEFAULT SYSDATETIME()
);
GO

CREATE TRIGGER trg_Movies_PriceChange
ON Movies
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Price)
    BEGIN
        INSERT INTO MoviePriceAudit (MovieID, OldPrice, NewPrice)
        SELECT 
            i.MovieID,
            d.Price,
            i.Price
        FROM INSERTED i
        INNER JOIN DELETED d ON i.MovieID = d.MovieID
        WHERE i.Price != d.Price;
    END;
END;
GO

PRINT '✓ Price audit trigger created';
PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'All Exercises Completed!';
PRINT '========================================';
PRINT '';
PRINT 'Topics Covered:';
PRINT '  ✓ Database creation';
PRINT '  ✓ Data type selection';
PRINT '  ✓ Table design and normalization';
PRINT '  ✓ Constraints and integrity';
PRINT '  ✓ INSERT operations';
PRINT '  ✓ UPDATE operations';
PRINT '  ✓ DELETE operations';
PRINT '  ✓ Complex queries';
PRINT '  ✓ Views and procedures';
PRINT '  ✓ Triggers and auditing';
PRINT '';
PRINT 'Next Steps:';
PRINT '  → Practice these patterns with your own data';
PRINT '  → Experiment with different scenarios';
PRINT '  → Move on to Chapter 03: Query Primer';
PRINT '';
