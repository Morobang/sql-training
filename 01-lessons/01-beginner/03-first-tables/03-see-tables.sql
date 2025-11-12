-- ============================================
-- Lesson 3.2: See All Your Tables
-- ============================================

USE TechStore;

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

-- ============================================
-- Shows all tables in TechStore
-- You should see: Products
-- ============================================
