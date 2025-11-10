-- ============================================
-- Lesson 2.2: See All Schemas
-- ============================================

USE TechStore;

SELECT name FROM sys.schemas
WHERE name NOT LIKE 'db_%';

-- ============================================
-- This shows schemas in TechStore
-- You'll see "dbo" - the default schema
-- ============================================
