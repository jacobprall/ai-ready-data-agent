# Demo: Make My Data AI-Ready for RAG

Your company has a support knowledge base in Snowflake — 50K articles, 200K chunks, 30K customers, 20K tickets. The data has been there for months: migrated from a legacy wiki, augmented by a chunking pipeline, linked to a CRM and ticketing system. Some governance was started but never finished.

Now you want to build a RAG-powered search tool with Cortex Search. You open Cortex Code and say:

> **"Make my data AI-ready for RAG."**

This demo shows what happens next. Takes ~10 minutes.

---

## The Brownfield State

This isn't a greenfield setup. Before you even ask the agent, some work has already been done — inconsistently:

| What exists | What's missing |
|---|---|
| `ARTICLE_CHUNKS` has a clustering key on `article_id` (someone set it up for chunk lookups) | The other 3 tables have no clustering |
| `ARTICLES` has change tracking enabled (an engineer started a CDC rollout) | The other 3 tables have no change tracking, no streams |
| `ARTICLES` has a table comment from a documentation push | The other 3 tables and all columns are undocumented |
| Data is loaded and tables are queryable | No semantic views, no search optimization, no tags, no masking policies |

The agent's job: figure out what's already done, assess what's missing, and fix only the gaps.

---

## Expected Results

### Before (brownfield state)

```
RAG Service Assessment — SNOWFLAKE_LEARNING_DB.SUPPORT_KB

Data Quality                                          FAIL
  "Dirty data means empty chunks and garbage retrieval results"
  data_completeness    ~0.15  (need <= 0.01)          FAIL
  uniqueness            0.00  (need <= 0.01)          PASS

Schema Understanding                                  FAIL
  "Semantic models enable Text-to-SQL and help the LLM understand your data"
  semantic_documentation  0.00  (need >= 1.00)        FAIL

Retrieval Performance                                 FAIL
  "Optimized access keeps retrieval latency low at scale"
  access_optimization   0.25  (need >= 0.80)          FAIL
  search_optimization   0.00  (need >= 0.80)          FAIL

Change Management                                     FAIL
  "Enables incremental re-indexing instead of full rebuilds on every refresh"
  change_detection     ~0.12  (need >= 1.00)          FAIL
  data_freshness        1.00  (need >= 1.00)          PASS

Data Governance                                       FAIL
  "Prevents PII from leaking into RAG responses"
  classification        0.00  (need >= 0.50)          FAIL
  field_masking         0.00  (need >= 1.00)          FAIL

Summary: 0/5 stages passing (2/9 requirements passing)
```

Key brownfield signals the agent should notice:
- `access_optimization` at 0.25 — "ARTICLE_CHUNKS already has a clustering key"
- `change_detection` at ~0.12 — "ARTICLES already has change tracking enabled"
- `uniqueness` and `data_freshness` already pass — no action needed

### After (remediated)

All 9 requirements pass. All 5 stages pass.

---

## What This Means for RAG

| Before (brownfield) | After (remediated) | RAG Impact |
|---|---|---|
| ~16K chunks are empty (null text) | Empty chunks deleted, nulls filled | No more garbage embedding vectors in search results |
| LLM has no idea what columns mean | Semantic view explains the full schema | Cortex Analyst can generate accurate SQL |
| Only ARTICLE_CHUNKS is clustered | All 4 tables clustered for their access patterns | Retrieval queries scan fewer partitions |
| No search optimization | All tables have search optimization enabled | Substring and semantic search accelerated |
| Only ARTICLES has change tracking | All 4 tables tracked + streams created | Incremental re-indexing instead of full 200K-chunk rebuilds |
| Customer PII fully exposed | Email, phone, address masked by role | RAG responses can't accidentally leak customer data |
| No governance tags | Tables classified by domain and sensitivity | Cortex Search can index only knowledge-base-tagged tables |

---

## Demo Environment

| Setting | Value |
|---------|-------|
| **Role** | `SNOWFLAKE_LEARNING_ADMIN_ROLE` |
| **Database** | `SNOWFLAKE_LEARNING_DB` (pre-provisioned) |
| **Schema** | `SUPPORT_KB` (created by setup) |

| Table | Rows | Source Story |
|-------|------|-------------|
| ARTICLES | 50,000 | Migrated from legacy wiki — 30% missing authors, 40% uncategorized |
| ARTICLE_CHUNKS | ~200,000 | Chunking pipeline output — 8% empty chunks from HTML crashes |
| CUSTOMERS | 30,000 | CRM sync — mix of phone-only leads and email-only signups, PII exposed |
| SUPPORT_TICKETS | 20,000 | Ticketing system — half never linked to a KB article |

---

## Quick Start

See **[QUICKSTART.md](QUICKSTART.md)** for step-by-step instructions.

---

## File Index

```
projects/demo-rag/
├── README.md                        <- You are here
├── QUICKSTART.md                    <- Step-by-step guide
├── context.yaml                     <- Pre-filled assessment context
└── setup/
    ├── 01-create-tables.sql         <- Creates SUPPORT_KB schema + 4 tables
    ├── 02-load-data.sql             <- Loads ~300K rows with realistic quality issues
    ├── 03-brownfield.sql            <- Applies partial governance (the starting state)
    ├── 04-reset.sql                 <- Strips remediation, restores brownfield state
    └── 05-teardown.sql              <- DROP SCHEMA CASCADE (full cleanup)
```
