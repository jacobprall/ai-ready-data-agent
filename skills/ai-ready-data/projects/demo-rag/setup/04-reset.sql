-- ============================================================
-- AI-Ready Data Demo: Support Knowledge Base — Reset
-- ============================================================
-- Strips ALL governance (both remediation additions and the
-- brownfield partial state), then re-applies the brownfield
-- layer. One script gets you back to the demo starting state.
--
-- Use this to re-run remediation without reloading ~300K rows.
-- Note: data quality fixes (filled nulls, deleted rows) persist.
-- For a full reset, re-run 01 + 02 + 03 instead.
--
-- Order matters:
--   1. Unset masking policies from columns before dropping them
--   2. Drop tags after untagging (tags are schema-level objects)
--   3. Re-apply brownfield layer last
-- ============================================================

USE ROLE SNOWFLAKE_LEARNING_ADMIN_ROLE;
USE DATABASE SNOWFLAKE_LEARNING_DB;

-- ============================================================
-- 1. Disable change tracking on all tables
-- ============================================================
ALTER TABLE SUPPORT_KB.ARTICLES SET CHANGE_TRACKING = FALSE;
ALTER TABLE SUPPORT_KB.ARTICLE_CHUNKS SET CHANGE_TRACKING = FALSE;
ALTER TABLE SUPPORT_KB.CUSTOMERS SET CHANGE_TRACKING = FALSE;
ALTER TABLE SUPPORT_KB.SUPPORT_TICKETS SET CHANGE_TRACKING = FALSE;

-- ============================================================
-- 2. Drop search optimization
-- ============================================================
ALTER TABLE SUPPORT_KB.ARTICLES DROP SEARCH OPTIMIZATION IF EXISTS;
ALTER TABLE SUPPORT_KB.ARTICLE_CHUNKS DROP SEARCH OPTIMIZATION IF EXISTS;
ALTER TABLE SUPPORT_KB.CUSTOMERS DROP SEARCH OPTIMIZATION IF EXISTS;
ALTER TABLE SUPPORT_KB.SUPPORT_TICKETS DROP SEARCH OPTIMIZATION IF EXISTS;

-- ============================================================
-- 3. Drop all clustering keys
-- ============================================================
ALTER TABLE SUPPORT_KB.ARTICLES DROP CLUSTERING KEY;
ALTER TABLE SUPPORT_KB.ARTICLE_CHUNKS DROP CLUSTERING KEY;
ALTER TABLE SUPPORT_KB.CUSTOMERS DROP CLUSTERING KEY;
ALTER TABLE SUPPORT_KB.SUPPORT_TICKETS DROP CLUSTERING KEY;

-- ============================================================
-- 4. Drop semantic view
-- ============================================================
DROP SEMANTIC VIEW IF EXISTS SUPPORT_KB.SUPPORT_KB_SEMANTIC;

-- ============================================================
-- 5. Remove masking policies (unset from columns first)
-- ============================================================
ALTER TABLE SUPPORT_KB.CUSTOMERS MODIFY COLUMN EMAIL UNSET MASKING POLICY;
ALTER TABLE SUPPORT_KB.CUSTOMERS MODIFY COLUMN PHONE UNSET MASKING POLICY;
ALTER TABLE SUPPORT_KB.CUSTOMERS MODIFY COLUMN ADDRESS UNSET MASKING POLICY;

DROP MASKING POLICY IF EXISTS SUPPORT_KB.email_mask;
DROP MASKING POLICY IF EXISTS SUPPORT_KB.phone_mask;
DROP MASKING POLICY IF EXISTS SUPPORT_KB.address_mask;

-- ============================================================
-- 6. Drop tags
-- ============================================================
DROP TAG IF EXISTS SUPPORT_KB.data_domain;
DROP TAG IF EXISTS SUPPORT_KB.sensitivity;

-- ============================================================
-- 7. Remove all table comments
-- ============================================================
COMMENT ON TABLE SUPPORT_KB.ARTICLES IS NULL;
COMMENT ON TABLE SUPPORT_KB.ARTICLE_CHUNKS IS NULL;
COMMENT ON TABLE SUPPORT_KB.CUSTOMERS IS NULL;
COMMENT ON TABLE SUPPORT_KB.SUPPORT_TICKETS IS NULL;

-- ============================================================
-- 8. Drop streams
-- ============================================================
DROP STREAM IF EXISTS SUPPORT_KB.ARTICLES_STREAM;
DROP STREAM IF EXISTS SUPPORT_KB.ARTICLE_CHUNKS_STREAM;
DROP STREAM IF EXISTS SUPPORT_KB.CUSTOMERS_STREAM;
DROP STREAM IF EXISTS SUPPORT_KB.SUPPORT_TICKETS_STREAM;

-- ============================================================
-- 9. Re-apply brownfield layer
-- ============================================================
-- Restore the partial governance that existed before remediation.
-- This matches what 03-brownfield.sql applies.

ALTER TABLE SUPPORT_KB.ARTICLE_CHUNKS CLUSTER BY (article_id);
ALTER TABLE SUPPORT_KB.ARTICLES SET CHANGE_TRACKING = TRUE;
COMMENT ON TABLE SUPPORT_KB.ARTICLES IS 'Knowledge base articles for support portal. Source: legacy wiki migration + manual authoring.';

-- ============================================================
-- Verify: confirm brownfield state is restored
-- ============================================================
SHOW TABLES IN SCHEMA SUPPORT_KB;
SELECT
    "name" AS table_name,
    "change_tracking" AS change_tracking,
    "search_optimization" AS search_optimization,
    "cluster_by" AS cluster_by,
    "comment" AS comment
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
