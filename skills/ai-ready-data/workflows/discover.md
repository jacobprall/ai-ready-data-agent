# Workflow: Discover

Scope the assessment — identify the database, schema, tables, and use case.

---

## Purpose

Before running checks, establish:
1. What database and schema to assess
2. Which tables are in scope
3. What use case drives the thresholds

---

## Pre-flight: Cortex CLI Validation

Before starting discovery, validate the environment using Cortex CLI:

### Verify Active Connection

```bash
cortex connections list
```

Confirm the active connection points to the correct Snowflake account. If the user needs a different connection:

```bash
cortex connections set <connection_name>
```

### Check for Existing Semantic Views

Before assessing semantic documentation, check if semantic views already exist for the target schema:

```bash
cortex semantic-views search "{database}" --limit=10
```

If matches are found, describe them to understand existing coverage:

```bash
cortex semantic-views describe {DATABASE}.{SCHEMA}.{VIEW_NAME}
```

### Check for Existing Cortex Agents

See if a Cortex Agent already covers this domain (may indicate existing AI readiness work):

```bash
cortex agents search "{use_case}" --limit=5
```

---

## Step 1: Ask Scoping Questions

Ask these questions. Use progressive disclosure (1-2 at a time).

1. **Database** (required): "Which database should I assess?"
2. **Schema** (required): "Which schema?"
3. **Use case** (required): "What are you building? (e.g., RAG service, ML training pipeline, analytics)" — maps to a use case file in `use-cases/`. If no exact match, default to `rag`.
4. **Tables** (optional): "Should I assess all tables in the schema, or specific ones?" — if omitted, assess all base tables.

**STOP:** Wait for user responses before proceeding.

---

## Step 2: Run Discovery Queries

Verify connectivity and discover what's available:

```sql
-- List tables with row counts and sizes
SELECT
    table_name,
    row_count,
    bytes / (1024*1024) AS size_mb
FROM {database}.information_schema.tables
WHERE table_schema = '{schema}'
    AND table_type = 'BASE TABLE'
ORDER BY row_count DESC
```

Present as a simple inventory:

```
| Table | Rows | Size (MB) |
|-------|------|-----------|
| ARTICLES | 50,000 | 0.5 |
| ARTICLE_CHUNKS | 184,122 | 1.3 |
```

---

## Step 3: Confirm Scope

Present the scope and get explicit confirmation:

```
Assessment scope:
  Database: {database}
  Schema:   {schema}
  Tables:   {table_list}
  Use case: {use_case} (use-cases/{name}.yaml)

Proceed with assessment?
```

**STOP:** Get confirmation before running checks.

---

## Output

- Confirmed scope (database, schema, tables, use case)
- Loaded use case file with stages and thresholds
- Ready to proceed to [assess.md](assess.md)
