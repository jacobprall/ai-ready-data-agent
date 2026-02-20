-- ============================================================
-- AI-Ready Data Demo: Support Knowledge Base — Teardown
-- ============================================================
-- Removes everything created by the demo.
-- Drops the SUPPORT_KB schema from SNOWFLAKE_LEARNING_DB.
-- This removes all tables, views, tags, and masking policies
-- created during setup and remediation. Run when done.
-- ============================================================

USE ROLE SNOWFLAKE_LEARNING_ADMIN_ROLE;
DROP SCHEMA IF EXISTS SNOWFLAKE_LEARNING_DB.SUPPORT_KB CASCADE;
