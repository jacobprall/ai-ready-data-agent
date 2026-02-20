# Demo Quick Start

Takes ~10 minutes. Uses `SNOWFLAKE_LEARNING_DB` (pre-provisioned in every Snowflake account).

**Prerequisite:** `SNOWFLAKE_LEARNING_ADMIN_ROLE` granted to your Snowflake user.

---

## 1. Set up the brownfield environment

Run these three scripts in order to create the demo's starting state — a knowledge base with data quality issues and partial, inconsistent governance:

> Run projects/demo-rag/setup/01-create-tables.sql, then 02-load-data.sql, then 03-brownfield.sql

After setup you have: 4 tables, ~300K rows, some clustering, some change tracking, lots of gaps.

## 2. Make it AI-ready

> Make my data AI-ready for RAG. Start with projects/demo-rag/context.yaml.

The agent reads the pre-filled `context.yaml`, loads the RAG use case definition, and runs checks against your Snowflake connection. It discovers the brownfield state — partial clustering, partial change tracking — and presents results by stage.

**Expected:** 0/5 stages pass, but 2/9 requirements already pass (`uniqueness` and `data_freshness`). Some metrics are non-zero because of existing governance (`access_optimization` at 0.25, `change_detection` at ~0.12).

## 3. Walk through remediation

> Fix the issues

The agent works through each failing stage in order:

1. **Data Quality** — fills nulls with defaults, deletes empty chunks (recognizes that `resolved_at` nulls on open tickets are intentional)
2. **Schema Understanding** — creates a semantic view covering all 4 tables
3. **Retrieval Performance** — adds clustering to the 3 unclustered tables (skips ARTICLE_CHUNKS — already done), enables search optimization
4. **Change Management** — enables change tracking on 3 remaining tables (skips ARTICLES — already done), creates streams
5. **Data Governance** — creates tags, applies to tables, creates masking policies for email/phone/address

Each stage: explains why it matters for RAG, shows SQL, surfaces warnings, waits for approval, executes, verifies.

## 4. Verify

> Re-check — did it work?

**Expected:** 5/5 stages pass, 9/9 requirements pass.

## 5. Clean up

**Full teardown** (removes everything):

> Run projects/demo-rag/setup/05-teardown.sql

**Reset to brownfield** (strips remediation, keeps data, re-applies partial governance — for re-running the demo):

> Run projects/demo-rag/setup/04-reset.sql

---

## How It Works

The agent reads files from this repo — no packages, no infrastructure:

1. **`AGENTS.md`** points to **`SKILL.md`** — the skill definition with conventions and workflow routing
2. **`projects/demo-rag/context.yaml`** — pre-filled scope (database, schema, tables, use case)
3. **`use-cases/rag.yaml`** — 5 stages with thresholds and `why` explanations
4. **`requirements/index.yaml`** — requirement definitions with workload scoping (direction lives in each requirement's `meta.yaml`)
5. **`requirements/*/meta.yaml`** — per-requirement operation metadata and warnings
6. **`requirements/*/*.sql`** — the SQL the agent reads, substitutes, and executes
