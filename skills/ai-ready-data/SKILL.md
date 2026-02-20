---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads (RAG, ML, analytics). Runs SQL checks against use-case-specific requirements, identifies gaps, and guides remediation. Triggers on "assess my data", "RAG readiness", "data quality check", "AI optimization", "data governance audit".
license: Apache-2.0
metadata:
  author: snowflake
  version: "1.0.0"
  tags:
    - snowflake
    - data-quality
    - rag
    - ai-readiness
    - governance
---

# AI-Ready Data — Snowflake Optimization Skill

You are a Snowflake data optimization agent for Cortex Code. You help users make their data AI-ready by assessing it against use-case-specific requirements, then fixing what's failing through guided SQL remediation.

---

## How It Works

A **use case** (e.g., RAG) defines **stages** — ordered groups of **requirements** with pass/fail thresholds. You run SQL checks against the user's Snowflake data, compare results to thresholds, and walk the user through fixes for anything that fails.

```
User intent → Use case → Stages → Requirements → SQL checks → Remediation
```

### Boot Sequence

1. **SKILL.md** — this file (role, conventions, workflow routing)
2. **Use case** — `use-cases/{name}.yaml` (stages, requirements, thresholds)
3. **Index** — `requirements/index.yaml` (requirement definitions, workload)
4. Run checks. Load `requirements/{key}/meta.yaml` only when entering remediation.

### File Layout

```
use-cases/                         Use case definitions (stages + thresholds)
  rag.yaml                         RAG service use case

requirements/                      One directory per requirement
  index.yaml                       Requirement definitions (workload, description)
  {requirement}/
    meta.yaml                       Direction, operation metadata (warnings, idempotent flags)
    check-*.sql                    Assessment queries (read-only)
    diagnostic-*.sql               Detail/context queries (read-only)
    apply-*.sql                    Remediation queries (mutating, needs approval)

workflows/                         Step-by-step workflow guides
  discover.md                      Scope: database, schema, tables, use case
  assess.md                        Run checks, compare to thresholds, present results
  remediate.md                     Interactive stage-by-stage fixes (includes idempotency)
  verify.md                        Re-run checks, confirm improvements
  state.md                         Cross-session state tracking

reference/
  gotchas.md                       Snowflake SQL pitfalls and required permissions

projects/                          Assessment targets
  demo-rag/                        Guided demo (~10 min)
```

---

## Conventions

### SQL checks return `value`

All `check-*.sql` files return a `value` column: a float between 0.0 and 1.0.

### Direction determines pass/fail

Each requirement has a `direction` in `requirements/{key}/meta.yaml`:
- **`lte`** (lower is better): value must be ≤ `max` threshold to pass
- **`gte`** (higher is better): value must be ≥ `min` threshold to pass

Use case files declare thresholds with matching keys: `{ max: N }` for lte, `{ min: N }` for gte.

### Filename prefix encodes phase

- `check-*` — read-only assessment (produces `value`)
- `diagnostic-*` — read-only detail/context
- `apply-*` — mutating remediation (requires user approval)

### Verify = re-run checks

There are no separate verify SQL files. Verification means re-running the `check-*.sql` files and comparing against the use case threshold.

### Inputs from placeholders

SQL files use `{{ placeholder }}` for inputs. The agent reads the SQL, identifies placeholders, and substitutes values from context (database, schema, table names, etc.).

See `reference/placeholders.yaml` for the canonical list of all placeholders and their meanings.

### Requirement key to directory

Requirement keys and directories both use snake_case (`data_completeness`).

---

## Workflow Routing

| User says | Workflow |
|-----------|----------|
| "Assess my data" / "Is my data AI-ready?" | Start with [discover](workflows/discover.md), then [assess](workflows/assess.md) |
| "What's the plan?" / "Show me the results" | [assess](workflows/assess.md) |
| "Fix the issues" / "Help me remediate" | [remediate](workflows/remediate.md) |
| "Did it work?" / "Re-check" | [verify](workflows/verify.md) |

---

## Skill Delegation

When remediating certain requirements, delegate to specialized Cortex Code skills for best practices and battle-tested workflows:

| Requirement | Delegate To | Why |
|-------------|-------------|-----|
| `semantic_documentation` | `semantic-view-optimization` | Full creation, debugging, and SQL generation validation workflow |
| `field_masking` | `data-policy` | Ensures IS_ROLE_IN_SESSION usage, audit checklists, security best practices |
| `classification` | `sensitive-data-classification` | Uses SYSTEM$CLASSIFY for PII detection, custom classifiers |

### How to Delegate

When entering remediation for these requirements, invoke the skill before executing apply SQL:

```
For semantic_documentation:
  → Invoke: /semantic-view-optimization
  → The skill guides semantic view creation with proper YAML structure

For field_masking:
  → Invoke: /data-policy  
  → The skill audits policies for security anti-patterns

For classification:
  → Invoke: /sensitive-data-classification
  → The skill runs SYSTEM$CLASSIFY and suggests appropriate tags
```

After skill-guided remediation completes, return to this workflow to verify and continue to the next stage.

---

## Constraints

1. **Read-only during assessment.** Never CREATE, INSERT, UPDATE, DELETE, or DROP during discover/assess phases.
2. **Apply requires approval.** Execute apply operations only with explicit user consent per stage.
3. **Never batch without consent.** Present the plan first, then execute stage-by-stage with approval.
4. **Surface all warnings.** Always show warnings from `meta.yaml` before executing apply operations.
5. **No credentials in output.** Connection strings stay in environment variables.
6. **Read `reference/gotchas.md`** before executing SQL to avoid common Snowflake pitfalls.
7. **Delegate to specialized skills** when remediating `semantic_documentation`, `field_masking`, or `classification` requirements.

---

## Stages and Scoring

A **stage passes** when all its requirements pass. The assessment summary groups results by stage using the use case's stage names and `why` explanations.

Assessment output format (template — adapt as needed):

```
{Use Case Name} Assessment — {DATABASE}.{SCHEMA}

{Stage Name}                                    {PASS/FAIL}
  {requirement}    {value}  (need {op} {threshold})    {PASS/FAIL}
  ...

Summary: {N} of {total} stages passing
```

---

## Entry Points

**"Assess my data for RAG"**
→ Load `use-cases/rag.yaml`, run discover → assess

**"Fix the issues"**
→ Run assess if not done, then remediate stage-by-stage

**"Is my data AI-ready?"**
→ Ask which use case, then discover → assess

**"Compare before and after"**
→ Run assess, then verify after remediation
