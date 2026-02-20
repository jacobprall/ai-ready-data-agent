# Workflow: Remediate

Interactive stage-by-stage remediation with user approval.

---

## Purpose

Walk the user through fixing failing requirements **one stage at a time**, with explicit approval before each operation.

> **Never dump all SQL at once.** Present one stage, get approval, execute, verify, then proceed.

---

## Prerequisites

1. **Assessment completed** — results available from [assess.md](assess.md)
2. **Use case loaded** — stages and thresholds from `use-cases/{use_case}.yaml`
3. **Reference read** — `reference/gotchas.md` reviewed for Snowflake pitfalls

---

## Remediation Flow

### Step 1: Present Assessment Summary

Show the full assessment results so the user sees the starting point:

```
Assessment Summary for {DATABASE}.{SCHEMA}
Use case: {use_case}

{Stage Name}              {PASS/FAIL}  ({N}/{M} requirements passing)
{Stage Name}              {PASS/FAIL}
...

Stages passing: {X}/{total}
```

### Step 2: For Each Failing Stage (In Order)

Loop through failing stages in the order they appear in the use case file (this is the priority order):

#### 2a. Present Stage Context

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Stage: {Stage Name}
Why:   {why from use case}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Failing requirements:
  {requirement}: {value} (need {op} {threshold})
```

#### 2b. Load Operations

For each failing requirement in the stage:

1. Load `requirements/{requirement}/meta.yaml`
2. Identify `apply-*` operations and their warnings
3. Read the corresponding `apply-*.sql` files
4. Substitute `{{ }}` placeholders with actual values

#### 2c. Present Remediation Plan

Show the operations for this stage:

```
Proposed changes for {Stage Name}:
─────────────────────────────────

{requirement_1}:
  Operations:
    1. {operation}: {brief description}
    2. {operation}: {brief description}

  Objects affected:
    - {table_1}
    - {table_2}

  SQL:
    {Substituted SQL statements}
```

Surface all warnings from meta.yaml:

```
Warnings:
  - {warning from meta.yaml}
  - {warning from meta.yaml}
```

#### 2d. Request Approval

```
Apply these changes to fix {Stage Name}?
[Yes] [Skip] [Modify] [Tell me more] [Stop]
```

- **Yes** → Execute, then verify
- **Skip** → Move to next stage
- **Modify** → Let user edit the SQL, then execute
- **Tell me more** → Run `diagnostic-*.sql` for context, then return to prompt
- **Stop** → End remediation

#### 2e. Execute and Verify

After approval:

1. For non-idempotent operations (`idempotent: false` in meta.yaml), run the idempotency guard first (see Idempotency section below)
2. Execute the `apply-*.sql` operations
3. Re-run the `check-*.sql` for each requirement in this stage
4. Compare against use case threshold
5. Present results:

```
{Stage Name} — remediation complete

  {requirement}:
    Before: {old_value}
    After:  {new_value}
    Status: {PASS/FAIL}

Progress: {completed}/{total_failing} stages addressed
```

#### 2f. Proceed to Next Stage

```
Proceeding to next failing stage...
───────────────────────────────────
```

### Step 3: Final Summary

After all stages processed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Remediation Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stage                          Before    After
─────                          ──────    ─────
{Stage Name}                   FAIL      PASS
{Stage Name}                   FAIL      PASS
{Stage Name}                   PASS      PASS (already passing)
...

Stages passing: {X}/{total}

What we changed:
  {Stage}: {one-line summary}
  {Stage}: {one-line summary}
  ...
```

### Step 4: Next Steps

```
What would you like to do?
[Re-assess to confirm] [Done for now]
```

- **Re-assess** → Run [verify.md](verify.md)
- **Done** → End session

---

## Idempotency

Some apply operations are not idempotent (`idempotent: false` in meta.yaml). Re-running them will fail if the object already exists. This matters during retries or re-runs.

### Rule

Before executing any `apply-*` operation:
1. Check the `idempotent` field in meta.yaml
2. If `true` — execute directly
3. If `false` — run the guard query first, skip if the object exists

### Guard Patterns

**CREATE TAG** (`apply-create-tag`):
```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ namespace }};
```
If result has rows → tag exists → skip.

**CREATE MASKING POLICY** (`apply-create-masking-policy`):
```sql
SHOW MASKING POLICIES LIKE '{{ policy_name }}' IN SCHEMA {{ namespace }};
```
If result has rows → policy exists → skip.

**CREATE STREAM** (`apply-create-stream`):
```sql
SHOW STREAMS LIKE '{{ stream_name }}' IN SCHEMA {{ namespace }};
```
If result has rows → stream exists → skip.

**ALTER TABLE ADD NOT NULL** (`apply-add-not-null`):
```sql
DESCRIBE TABLE {{ asset }};
```
Check the `null?` column for the target field. If `N` → already NOT NULL → skip.

### Principles

- **Check-then-skip is the default.** Run the guard, skip if object exists.
- **Skipping a create does NOT skip dependents.** If `CREATE TAG` is skipped because the tag exists, `apply-table-tags` should still run (it's idempotent).
- **Skipped guards are not failures.** The desired state already exists — that's success.
- **Never use `CREATE OR REPLACE`** unless explicitly appropriate. Replacing existing policies or tags could break other objects that reference them.

---

## Failure & Recovery

When an operation fails:

1. Present the error to the user
2. Offer options: `[Retry] [Skip and continue] [Stop]`
3. On retry, run idempotency guards first — some operations in the stage may have succeeded
4. On skip, move to the next stage
5. On stop, end the session

---

## Notes

- Always surface warnings from meta.yaml **before** the user approves
- Stage order from the use case file is the remediation priority
- Quantify impact using data from the assessment (row counts, table counts, before/after values)
