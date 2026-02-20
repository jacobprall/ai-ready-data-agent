-- ============================================================
-- AI-Ready Data Demo: Support Knowledge Base — Brownfield State
-- ============================================================
-- Applies partial, inconsistent governance to simulate what a
-- real team might have done before asking "make my data AI-ready."
--
-- What this creates:
--   - ARTICLE_CHUNKS has a clustering key (someone set it up
--     for chunk lookups, but didn't touch the other 3 tables)
--   - ARTICLES has change tracking enabled (an engineer started
--     enabling CDC but never finished the rollout)
--   - ARTICLES has a table comment (one table got documented,
--     the rest didn't)
--
-- This is the "starting state" for the demo. The agent should
-- discover this partial governance and only fix what's missing.
--
-- Run after 02-load-data.sql.
-- ============================================================

USE ROLE SNOWFLAKE_LEARNING_ADMIN_ROLE;
USE SCHEMA SNOWFLAKE_LEARNING_DB.SUPPORT_KB;

-- Someone on the data team clustered ARTICLE_CHUNKS for
-- chunk lookups by article_id. The other 3 tables were
-- never touched because "we'll get to it later."
ALTER TABLE ARTICLE_CHUNKS CLUSTER BY (article_id);

-- An engineer started enabling CDC for an incremental
-- pipeline prototype. They got ARTICLES done but moved
-- to another project before finishing the other tables.
ALTER TABLE ARTICLES SET CHANGE_TRACKING = TRUE;

-- The tech lead added a comment to the main articles table
-- during a documentation push. Nobody followed up on the rest.
COMMENT ON TABLE ARTICLES IS 'Knowledge base articles for support portal. Source: legacy wiki migration + manual authoring.';

-- ============================================================
-- Verify brownfield state
-- ============================================================
SHOW TABLES IN SCHEMA SUPPORT_KB;
SELECT
    "name" AS table_name,
    "change_tracking" AS change_tracking,
    "search_optimization" AS search_optimization,
    "cluster_by" AS cluster_by,
    "comment" AS comment
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
