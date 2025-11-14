/*============================================================================
  Script:   sakila-schema-setup.sql
  Purpose:  Create the Sakila sample database schema
  Database: Sakila (Film Rental Store)
  
  Description:
  The Sakila database is a normalized schema representing a DVD rental store.
  It's commonly used for learning SQL joins, subqueries, and normalization.
  
  This script creates the core tables and relationships. For full sample data,
  use the official MySQL Sakila database dump and convert to SQL Server.
  
  Tables Created:
  - actor, film, film_actor (many-to-many)
  - category, film_category
  - customer, address, city, country
  - rental, inventory, payment
  - staff, store
  
  Author:       SQL Training Team
  Created:      2025-11-14
  Modified:     2025-11-14
  Version:      1.0
============================================================================*/

-- Create database
IF DB_ID('Sakila') IS NOT NULL
BEGIN
    PRINT 'Dropping existing Sakila database...';
    USE master;
    ALTER DATABASE Sakila SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Sakila;
END
GO

CREATE DATABASE Sakila;
GO

USE Sakila;
GO

PRINT 'Creating Sakila database schema...';
PRINT '';

/*----------------------------------------------------------------------------
  ACTOR & FILM TABLES (Core Content)
----------------------------------------------------------------------------*/

-- Actors in films
CREATE TABLE actor (
    actor_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    last_update DATETIME DEFAULT GETDATE()
);

-- Film catalog
CREATE TABLE film (
    film_id INT PRIMARY KEY IDENTITY(1,1),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    release_year INT,
    language_id INT NOT NULL,
    rental_duration INT DEFAULT 3,
    rental_rate DECIMAL(4,2) DEFAULT 4.99,
    length INT,  -- Duration in minutes
    replacement_cost DECIMAL(5,2) DEFAULT 19.99,
    rating VARCHAR(10) DEFAULT 'G',  -- G, PG, PG-13, R, NC-17
    special_features VARCHAR(255),
    last_update DATETIME DEFAULT GETDATE()
);

-- Many-to-many: Actors in Films
CREATE TABLE film_actor (
    actor_id INT NOT NULL,
    film_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (actor_id, film_id),
    FOREIGN KEY (actor_id) REFERENCES actor(actor_id),
    FOREIGN KEY (film_id) REFERENCES film(film_id)
);

-- Film categories
CREATE TABLE category (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(25) NOT NULL,
    last_update DATETIME DEFAULT GETDATE()
);

-- Many-to-many: Films in Categories
CREATE TABLE film_category (
    film_id INT NOT NULL,
    category_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (film_id, category_id),
    FOREIGN KEY (film_id) REFERENCES film(film_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Languages
CREATE TABLE language (
    language_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(20) NOT NULL,
    last_update DATETIME DEFAULT GETDATE()
);

ALTER TABLE film
ADD CONSTRAINT FK_film_language FOREIGN KEY (language_id) REFERENCES language(language_id);

/*----------------------------------------------------------------------------
  LOCATION TABLES (Address Hierarchy)
----------------------------------------------------------------------------*/

-- Countries
CREATE TABLE country (
    country_id INT PRIMARY KEY IDENTITY(1,1),
    country VARCHAR(50) NOT NULL,
    last_update DATETIME DEFAULT GETDATE()
);

-- Cities
CREATE TABLE city (
    city_id INT PRIMARY KEY IDENTITY(1,1),
    city VARCHAR(50) NOT NULL,
    country_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

-- Addresses
CREATE TABLE address (
    address_id INT PRIMARY KEY IDENTITY(1,1),
    address VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    district VARCHAR(20) NOT NULL,
    city_id INT NOT NULL,
    postal_code VARCHAR(10),
    phone VARCHAR(20) NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);

/*----------------------------------------------------------------------------
  STORE & STAFF TABLES
----------------------------------------------------------------------------*/

-- Stores
CREATE TABLE store (
    store_id INT PRIMARY KEY IDENTITY(1,1),
    manager_staff_id INT NOT NULL,
    address_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (address_id) REFERENCES address(address_id)
);

-- Staff (employees)
CREATE TABLE staff (
    staff_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    address_id INT NOT NULL,
    email VARCHAR(50),
    store_id INT NOT NULL,
    active BIT DEFAULT 1,
    username VARCHAR(16) NOT NULL,
    password VARCHAR(40),
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (address_id) REFERENCES address(address_id),
    FOREIGN KEY (store_id) REFERENCES store(store_id)
);

-- Add FK after staff table exists
ALTER TABLE store
ADD CONSTRAINT FK_store_staff FOREIGN KEY (manager_staff_id) REFERENCES staff(staff_id);

/*----------------------------------------------------------------------------
  CUSTOMER TABLE
----------------------------------------------------------------------------*/

CREATE TABLE customer (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    store_id INT NOT NULL,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    email VARCHAR(50),
    address_id INT NOT NULL,
    active BIT DEFAULT 1,
    create_date DATETIME DEFAULT GETDATE(),
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (store_id) REFERENCES store(store_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id)
);

/*----------------------------------------------------------------------------
  INVENTORY & RENTAL TABLES (Operational)
----------------------------------------------------------------------------*/

-- Film inventory (physical copies at stores)
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY IDENTITY(1,1),
    film_id INT NOT NULL,
    store_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (film_id) REFERENCES film(film_id),
    FOREIGN KEY (store_id) REFERENCES store(store_id)
);

-- Rental transactions
CREATE TABLE rental (
    rental_id INT PRIMARY KEY IDENTITY(1,1),
    rental_date DATETIME NOT NULL,
    inventory_id INT NOT NULL,
    customer_id INT NOT NULL,
    return_date DATETIME,
    staff_id INT NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

-- Payments
CREATE TABLE payment (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT NOT NULL,
    staff_id INT NOT NULL,
    rental_id INT,
    amount DECIMAL(5,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id)
);

/*----------------------------------------------------------------------------
  INDEXES FOR PERFORMANCE
----------------------------------------------------------------------------*/

PRINT 'Creating indexes...';

-- Commonly joined columns
CREATE INDEX idx_film_title ON film(title);
CREATE INDEX idx_film_language ON film(language_id);
CREATE INDEX idx_customer_last_name ON customer(last_name);
CREATE INDEX idx_customer_store ON customer(store_id);
CREATE INDEX idx_rental_customer ON rental(customer_id);
CREATE INDEX idx_rental_inventory ON rental(inventory_id);
CREATE INDEX idx_rental_date ON rental(rental_date);
CREATE INDEX idx_payment_customer ON payment(customer_id);
CREATE INDEX idx_payment_rental ON payment(rental_id);
CREATE INDEX idx_inventory_film ON inventory(film_id);
CREATE INDEX idx_inventory_store ON inventory(store_id);

PRINT 'Indexes created successfully.';
PRINT '';

/*----------------------------------------------------------------------------
  SAMPLE DATA (Minimal)
----------------------------------------------------------------------------*/

PRINT 'Inserting sample data...';

-- Languages
SET IDENTITY_INSERT language ON;
INSERT INTO language (language_id, name) VALUES
(1, 'English'),
(2, 'Spanish'),
(3, 'French');
SET IDENTITY_INSERT language OFF;

-- Categories
SET IDENTITY_INSERT category ON;
INSERT INTO category (category_id, name) VALUES
(1, 'Action'),
(2, 'Comedy'),
(3, 'Drama'),
(4, 'Horror'),
(5, 'Sci-Fi'),
(6, 'Documentary');
SET IDENTITY_INSERT category OFF;

-- Countries
INSERT INTO country (country) VALUES
('United States'),
('Canada'),
('Mexico'),
('United Kingdom'),
('France');

-- Cities
INSERT INTO city (city, country_id) VALUES
('Los Angeles', 1),
('New York', 1),
('Toronto', 2),
('London', 4),
('Paris', 5);

-- Sample Actors
INSERT INTO actor (first_name, last_name) VALUES
('Tom', 'Hanks'),
('Meryl', 'Streep'),
('Leonardo', 'DiCaprio'),
('Emma', 'Stone'),
('Denzel', 'Washington');

-- Sample Films
SET IDENTITY_INSERT film ON;
INSERT INTO film (film_id, title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating) VALUES
(1, 'The Matrix', 'A computer hacker learns about the true nature of reality', 1999, 1, 7, 4.99, 136, 19.99, 'R'),
(2, 'Forrest Gump', 'The presidencies of Kennedy and Johnson unfold through the perspective of an Alabama man', 1994, 1, 5, 2.99, 142, 19.99, 'PG-13'),
(3, 'The Shawshank Redemption', 'Two imprisoned men bond over a number of years', 1994, 1, 7, 4.99, 142, 19.99, 'R'),
(4, 'Inception', 'A thief who steals corporate secrets through dream-sharing technology', 2010, 1, 5, 4.99, 148, 19.99, 'PG-13'),
(5, 'Pulp Fiction', 'The lives of two mob hitmen, a boxer, and a pair of diner bandits intertwine', 1994, 1, 5, 4.99, 154, 19.99, 'R');
SET IDENTITY_INSERT film OFF;

-- Film Categories
INSERT INTO film_category (film_id, category_id) VALUES
(1, 1),  -- Matrix: Action
(1, 5),  -- Matrix: Sci-Fi
(2, 3),  -- Forrest Gump: Drama
(3, 3),  -- Shawshank: Drama
(4, 1),  -- Inception: Action
(4, 5),  -- Inception: Sci-Fi
(5, 3);  -- Pulp Fiction: Drama

-- Film Actors
INSERT INTO film_actor (actor_id, film_id) VALUES
(1, 2),  -- Tom Hanks in Forrest Gump
(3, 4),  -- DiCaprio in Inception
(5, 1);  -- Denzel (example)

PRINT 'Sample data inserted successfully.';
PRINT '';

/*----------------------------------------------------------------------------
  SUMMARY
----------------------------------------------------------------------------*/

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║          SAKILA DATABASE SCHEMA CREATED SUCCESSFULLY            ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Tables Created: 16';
PRINT '- Content: actor, film, film_actor, category, film_category, language';
PRINT '- Location: country, city, address';
PRINT '- Business: store, staff, customer';
PRINT '- Operations: inventory, rental, payment';
PRINT '';
PRINT 'Sample Data:';
PRINT '- 3 languages, 6 categories, 5 countries, 5 cities';
PRINT '- 5 actors, 5 films';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Review schema: SELECT * FROM INFORMATION_SCHEMA.TABLES;';
PRINT '2. Explore relationships: SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS;';
PRINT '3. Practice queries in lessons/exercises';
PRINT '';
PRINT 'Common Queries to Try:';
PRINT '- Find all films by an actor';
PRINT '- Calculate total rentals per customer';
PRINT '- List top-grossing films';
PRINT '- Find overdue rentals';
PRINT '';

/*============================================================================
  END OF SCRIPT
============================================================================*/
