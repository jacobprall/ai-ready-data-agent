-- ============================================================
-- AI-Ready Data Demo: Support Knowledge Base — Load Data
-- ============================================================
-- Populates the 4 tables with ~300K rows of realistic data.
-- Each table is large enough to trigger clustering checks
-- (>10K rows).
--
-- The quality issues are intentional and tell a story:
--
--   ARTICLES:
--     30% null author    — legacy wiki import had no author field
--     40% null category  — imported articles were never categorized
--
--   ARTICLE_CHUNKS:
--     8% null chunk_text — chunking pipeline crashed on HTML content
--
--   CUSTOMERS:
--     15% null email     — phone-only leads from trade shows
--     20% null phone     — web signups only provided email
--     25% null address   — incomplete CRM records
--
--   SUPPORT_TICKETS:
--     50% null article_id  — most tickets were never linked to a KB article
--     ~40% null resolved_at — open/in-progress tickets (INTENTIONAL, not a bug)
--
-- Run after 01-create-tables.sql, then run 03-brownfield.sql.
-- ============================================================

USE ROLE SNOWFLAKE_LEARNING_ADMIN_ROLE;
USE SCHEMA SNOWFLAKE_LEARNING_DB.SUPPORT_KB;

-- ============================================================
-- ARTICLES — 50,000 rows
-- ============================================================
-- Backstory: bulk-imported from a Confluence wiki. The wiki
-- never enforced author or category fields, so older articles
-- are missing both. The engineering team added categories to
-- new articles but never backfilled the old ones.
INSERT INTO ARTICLES
SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ4()) AS article_id,
    'How to ' || DECODE(MOD(SEQ4(), 12),
        0, 'reset your password',
        1, 'configure SSO for your organization',
        2, 'set up billing alerts',
        3, 'export data to CSV',
        4, 'integrate with Slack',
        5, 'manage team permissions',
        6, 'troubleshoot connection errors',
        7, 'upgrade your subscription plan',
        8, 'enable two-factor authentication',
        9, 'use the REST API',
        10, 'configure webhooks',
        11, 'migrate from a legacy system')
      || ' (variant ' || SEQ4()::VARCHAR || ')' AS title,
    REPEAT('This article explains the detailed steps for completing this task. ', 20)
      || 'Last reviewed by the documentation team.' AS body,
    -- 30% null: legacy wiki articles had no author metadata
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 30 THEN NULL
         ELSE DECODE(MOD(SEQ4(), 5),
            0, 'alice@company.com',
            1, 'bob@company.com',
            2, 'carol@company.com',
            3, 'dave@company.com',
            4, 'eve@company.com')
    END AS author,
    -- 40% null: imported articles were never assigned a category
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN NULL
         ELSE DECODE(MOD(SEQ4(), 6),
            0, 'Account Management',
            1, 'Billing',
            2, 'Integrations',
            3, 'Security',
            4, 'API',
            5, 'Getting Started')
    END AS category,
    DECODE(MOD(SEQ4(), 4), 0, 'published', 1, 'published', 2, 'draft', 3, 'archived') AS status,
    DATEADD('day', -UNIFORM(30, 730, RANDOM()), CURRENT_TIMESTAMP()) AS created_at,
    DATEADD('day', -UNIFORM(1, 180, RANDOM()), CURRENT_TIMESTAMP()) AS updated_at
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- ============================================================
-- ARTICLE_CHUNKS — ~200,000 rows (4 chunks per article)
-- ============================================================
-- Backstory: a Python chunking pipeline ran over all articles.
-- It crashed on HTML-heavy articles and wrote NULL chunk_text
-- instead of failing. These empty chunks will produce garbage
-- embedding vectors if fed to a model.
INSERT INTO ARTICLE_CHUNKS
SELECT
    ROW_NUMBER() OVER (ORDER BY a.article_id, SEQ4()) AS chunk_id,
    a.article_id,
    -- 8% null: chunking pipeline crashed on HTML-heavy content
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 8 THEN NULL
         ELSE 'Chunk ' || SEQ4()::VARCHAR || ' of article ' || a.article_id::VARCHAR
              || ': ' || REPEAT('This section covers important details. ', 8)
    END AS chunk_text,
    SEQ4() AS chunk_index,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 8 THEN 0
         ELSE UNIFORM(50, 512, RANDOM())
    END AS token_count
FROM ARTICLES a,
     TABLE(GENERATOR(ROWCOUNT => 4))
WHERE a.article_id <= 50000;

-- ============================================================
-- CUSTOMERS — 30,000 rows
-- ============================================================
-- Backstory: synced nightly from the CRM. Trade show leads
-- were entered with phone only; web signups with email only.
-- PII columns (email, phone, address) have no masking — any
-- RAG response could accidentally surface customer data.
INSERT INTO CUSTOMERS
SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ4()) AS customer_id,
    'Customer ' || SEQ4()::VARCHAR AS full_name,
    -- 15% null: phone-only leads from trade shows
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 15 THEN NULL
         ELSE 'user' || SEQ4()::VARCHAR || '@example.com'
    END AS email,
    -- 20% null: web signups only provided email
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 20 THEN NULL
         ELSE '+1-555-' || LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0')
              || '-' || LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0')
    END AS phone,
    -- 25% null: incomplete CRM records
    DECODE(MOD(SEQ4(), 4),
        0, '123 Main St, Springfield, IL 62701',
        1, '456 Oak Ave, Portland, OR 97201',
        2, '789 Pine Rd, Austin, TX 78701',
        3, NULL) AS address,
    'Company ' || UNIFORM(1, 500, RANDOM())::VARCHAR AS company,
    DECODE(MOD(SEQ4(), 4), 0, 'free', 1, 'starter', 2, 'pro', 3, 'enterprise') AS plan_tier,
    DATEADD('day', -UNIFORM(1, 1095, RANDOM()), CURRENT_TIMESTAMP()) AS created_at
FROM TABLE(GENERATOR(ROWCOUNT => 30000));

-- ============================================================
-- SUPPORT_TICKETS — 20,000 rows
-- ============================================================
-- Backstory: from the ticketing system. Half were never linked
-- to a KB article. Open and in-progress tickets have null
-- resolved_at — this is CORRECT behavior, not a quality issue.
-- A smart agent should recognize this and not try to fill it.
INSERT INTO SUPPORT_TICKETS
SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ4()) AS ticket_id,
    DECODE(MOD(SEQ4(), 8),
        0, 'Cannot log in after password reset',
        1, 'Billing discrepancy on last invoice',
        2, 'API rate limit exceeded unexpectedly',
        3, 'SSO not working with Okta',
        4, 'Need to export 2 years of data',
        5, 'Webhook delivery failures',
        6, 'Cannot add team members',
        7, 'Slow dashboard performance') AS subject,
    'Detailed description of the issue reported by the customer. '
      || 'Includes reproduction steps and environment details.' AS description,
    UNIFORM(1, 30000, RANDOM()) AS customer_id,
    -- 50% null: most tickets were never linked to a KB article
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN NULL
         ELSE UNIFORM(1, 50000, RANDOM())
    END AS article_id,
    DECODE(MOD(SEQ4(), 5), 0, 'open', 1, 'open', 2, 'in_progress', 3, 'resolved', 4, 'closed') AS status,
    DECODE(MOD(SEQ4(), 4), 0, 'low', 1, 'medium', 2, 'high', 3, 'critical') AS priority,
    DATEADD('day', -UNIFORM(1, 365, RANDOM()), CURRENT_TIMESTAMP()) AS created_at,
    -- ~40% null: open and in-progress tickets (intentional — NOT a quality issue)
    CASE WHEN MOD(SEQ4(), 5) IN (0, 1, 2) THEN NULL
         ELSE DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_TIMESTAMP())
    END AS resolved_at
FROM TABLE(GENERATOR(ROWCOUNT => 20000));

-- ============================================================
-- Verify row counts
-- ============================================================
SELECT 'ARTICLES' AS table_name, COUNT(*) AS row_count FROM ARTICLES
UNION ALL
SELECT 'ARTICLE_CHUNKS', COUNT(*) FROM ARTICLE_CHUNKS
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL
SELECT 'SUPPORT_TICKETS', COUNT(*) FROM SUPPORT_TICKETS
ORDER BY table_name;
