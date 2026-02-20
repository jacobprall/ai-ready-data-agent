# Workflow: Assess

Run checks, compare against use case thresholds, present results grouped by stage.

---

## Purpose

Execute `check-*.sql` operations for each requirement in the active use case, compare measured values to thresholds, and produce a stage-by-stage assessment.

---

## Step 1: Load Configuration

1. Load the use case file: `use-cases/{use_case}.yaml` — contains stages, requirements, and thresholds
2. Load the requirement index: `requirements/index.yaml` — contains workload and description. Load direction from `requirements/{key}/meta.yaml` per requirement.
3. Read `reference/gotchas.md` for Snowflake pitfalls before executing any SQL

---

## Step 2: Run Check Operations

For each stage in the use case, for each requirement in that stage:

1. Find `check-*.sql` files in `requirements/{requirement}/`
3. Read the SQL file, substitute `{{ }}` placeholders with actual values:
   - `{{ container }}` → database name
   - `{{ namespace }}` → schema name
   - `{{ asset }}` → table name
   - `{{ field }}` → column name
   - Other placeholders as needed from the SQL context
4. Execute the SQL
5. Read the `value` column from the result
6. Compare against the threshold from the use case file:
   - If direction is `lte`: value must be ≤ `max` threshold to pass
   - If direction is `gte`: value must be ≥ `min` threshold to pass

### Scope-Dependent Execution

Some checks run once per schema (e.g., `check-clustering-coverage.sql`), others run per table or per column (e.g., `check-null-rate.sql`). Infer the scope from the SQL's `{{ }}` placeholders:

- **Schema-scoped** (placeholders: `container`, `namespace` only): run once
- **Table-scoped** (includes `asset`): run per table, aggregate results
- **Column-scoped** (includes `field`): run per column, aggregate results

For multi-run checks, the requirement's value is the aggregate (e.g., worst value across tables/columns).

---

## Step 3: Present Results

Group results by stage using the use case's stage names and `why` explanations.

### Assessment Output Template

```
{Use Case Name} Assessment — {DATABASE}.{SCHEMA}

{Stage Name}                                          {PASS/FAIL}
  "{why}"
  {requirement_1}    {value}  (need {op} {threshold})    {PASS/FAIL}
  {requirement_2}    {value}  (need {op} {threshold})    {PASS/FAIL}

{Stage Name}                                          {PASS/FAIL}
  "{why}"
  ...

Summary: {N} of {total} stages passing ({M} of {R} requirements passing)
```

### Example

```
RAG Service Assessment — SNOWFLAKE_LEARNING_DB.SUPPORT_KB

Data Quality                                          FAIL
  "Dirty data means empty chunks and garbage retrieval results"
  data_completeness    0.15  (need ≤ 0.01)            FAIL
  uniqueness           0.00  (need ≤ 0.01)            PASS

Schema Understanding                                  FAIL
  "Semantic models enable Text-to-SQL and help the LLM understand your data"
  semantic_documentation  0.00  (need ≥ 1.00)         FAIL

Retrieval Performance                                 FAIL
  "Optimized access keeps retrieval latency low at scale"
  access_optimization  0.00  (need ≥ 0.80)            FAIL
  search_optimization  0.00  (need ≥ 0.80)            FAIL

Change Management                                     FAIL
  "Enables incremental re-indexing instead of full rebuilds"
  change_detection     0.00  (need ≥ 1.00)            FAIL
  data_freshness       1.00  (need ≥ 1.00)            PASS

Data Governance                                       FAIL
  "Prevents PII from leaking into RAG responses"
  classification       0.00  (need ≥ 0.50)            FAIL
  field_masking        0.00  (need ≥ 1.00)            FAIL

Summary: 0 of 5 stages passing (2 of 9 requirements passing)
```

**STOP:** Present results and wait for user direction.

---

## Step 4: Offer Next Steps

```
What would you like to do?
[Fix the issues] [Tell me more about a stage] [Export results] [Done for now]
```

- **Fix the issues** → Proceed to [remediate.md](remediate.md)
- **Tell me more** → Run `diagnostic-*.sql` for the requested stage's requirements and present detail
- **Export results** → Output structured JSON (see below)
- **Done for now** → End session

---

## Structured Output Format (JSON)

For integration with other tools, CI/CD pipelines, or programmatic consumption, output assessment results as structured JSON when requested:

```json
{
  "assessment": {
    "use_case": "rag",
    "use_case_name": "RAG Service",
    "timestamp": "2026-02-19T10:30:00Z",
    "scope": {
      "database": "SNOWFLAKE_LEARNING_DB",
      "schema": "SUPPORT_KB",
      "tables": ["ARTICLES", "ARTICLE_CHUNKS"]
    },
    "summary": {
      "stages_passing": 0,
      "stages_total": 5,
      "requirements_passing": 2,
      "requirements_total": 9
    },
    "stages": [
      {
        "name": "Data Quality",
        "why": "Dirty data means empty chunks and garbage retrieval results",
        "status": "FAIL",
        "requirements": [
          {
            "key": "data_completeness",
            "value": 0.15,
            "direction": "lte",
            "threshold": 0.01,
            "threshold_type": "max",
            "status": "FAIL"
          },
          {
            "key": "uniqueness",
            "value": 0.00,
            "direction": "lte",
            "threshold": 0.01,
            "threshold_type": "max",
            "status": "PASS"
          }
        ]
      },
      {
        "name": "Schema Understanding",
        "why": "Semantic models enable Text-to-SQL and help the LLM understand your data",
        "status": "FAIL",
        "requirements": [
          {
            "key": "semantic_documentation",
            "value": 0.00,
            "direction": "gte",
            "threshold": 1.00,
            "threshold_type": "min",
            "status": "FAIL"
          }
        ]
      }
    ]
  }
}
```

### JSON Schema Fields

| Field | Type | Description |
|-------|------|-------------|
| `use_case` | string | Use case key (e.g., `rag`) |
| `use_case_name` | string | Human-readable use case name |
| `timestamp` | string | ISO 8601 timestamp of assessment |
| `scope.database` | string | Assessed database |
| `scope.schema` | string | Assessed schema |
| `scope.tables` | array | List of assessed tables |
| `summary.stages_passing` | int | Number of stages that passed |
| `summary.stages_total` | int | Total number of stages |
| `stages[].name` | string | Stage name from use case |
| `stages[].why` | string | Stage rationale from use case |
| `stages[].status` | string | `PASS` or `FAIL` |
| `stages[].requirements[].key` | string | Requirement key |
| `stages[].requirements[].value` | float | Measured value (0.0-1.0) |
| `stages[].requirements[].direction` | string | `lte` or `gte` |
| `stages[].requirements[].threshold` | float | Required threshold |
| `stages[].requirements[].status` | string | `PASS` or `FAIL` |

---

## Notes

- Always check warnings in `requirements/{key}/meta.yaml` before running check SQL
- Some checks use `SHOW TABLES` + `RESULT_SCAN` — both statements must run in the same session
- `account_usage` views have ~2 hour latency for new objects — warn the user if results seem stale
