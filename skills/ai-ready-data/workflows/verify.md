# Workflow: Verify

Re-run checks to confirm improvements after remediation.

---

## Purpose

Re-run all `check-*.sql` operations and compare against use case thresholds to confirm that remediation improved the results. Also useful for drift detection on previously-passing data.

---

## Step 1: Load Configuration

1. Load the use case file: `use-cases/{use_case}.yaml`
2. Load the requirement index: `requirements/index.yaml`; direction from `requirements/{key}/meta.yaml`

---

## Step 2: Run All Check Operations

For each stage in the use case, for each requirement:

1. Find `check-*.sql` files in `requirements/{requirement}/`
2. Substitute placeholders and execute
3. Compare `value` against the threshold using direction from `meta.yaml`

Use the same execution logic as [assess.md](assess.md) Step 2.

---

## Step 3: Present Results

If prior assessment results are available (from the same session), show before/after:

```
Verification Results — {DATABASE}.{SCHEMA}
Use case: {use_case}

Stage                    Before    After     Status
─────                    ──────    ─────     ──────
Data Quality             FAIL      PASS
  data_completeness      0.15      0.001     PASS
  uniqueness             0.00      0.00      PASS

Schema Understanding     FAIL      PASS
  semantic_documentation 0.00      1.00      PASS

...

Summary: {N}/{total} stages passing
```

If no prior results exist, show current state only (omit Before column).

---

## Step 4: Remaining Gaps

If any stages still fail:

```
Remaining Gaps:
───────────────
{Stage Name}: {requirement} at {value} (need {op} {threshold})
  Fix: {brief guidance}
```

If all stages pass:

```
All stages pass for use case: {use_case}
No remaining gaps detected.
```

---

## Step 5: Drift Detection

When comparing against prior results, flag any regression:

```
Drift Detected:
  {requirement}: was PASS ({previous_value}), now FAIL ({current_value})
  Possible cause: {e.g., "New data loaded with NULL values"}
```

---

## Next Steps

```
What would you like to do?
[Fix remaining gaps] [Done for now]
```

- **Fix remaining gaps** → Return to [remediate.md](remediate.md) for unfixed stages
- **Done** → End session
