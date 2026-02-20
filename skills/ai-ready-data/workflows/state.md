# Workflow: State Tracking

Optional persistent state for cross-session remediation. Per decision 7.4, state is not persisted by default — the agent re-runs checks to determine current state. This file documents the state format for agents that choose to persist progress.

---

## When to Use

State tracking is optional. It's useful when:
- Remediation spans multiple sessions
- The user wants to resume where they left off
- Audit trail of what was applied is needed

For most sessions, re-running checks at the start is sufficient and always accurate.

---

## Schema

```yaml
timestamp: "2026-02-18T14:30Z"
use_case: rag
stages:
  Data Quality:
    status: applied
    at: "2026-02-18T14:31Z"
  Schema Understanding:
    status: applied
    at: "2026-02-18T14:33Z"
  Retrieval Performance:
    status: failed
    error: "Permission denied on ALTER TABLE"
    at: "2026-02-18T14:35Z"
  Change Management:
    status: pending
  Data Governance:
    status: pending
```

### Status Values

| Status | Meaning |
|--------|---------|
| `pending` | Not yet attempted |
| `applied` | Remediation succeeded and verified |
| `failed` | Remediation encountered an error |
| `skipped` | User chose to skip this stage |

### Status Transitions

```
pending  → applied     (remediate + verify succeeded)
pending  → failed      (remediate or verify failed)
pending  → skipped     (user chose "Skip")
failed   → applied     (retry succeeded)
failed   → skipped     (user chose to skip on retry)
```

---

## Lifecycle

### Initialize

When remediation starts, create the state file with all failing stages set to `pending`. Stages that already pass are omitted.

### Update

After each stage's remediate+verify cycle, update the state file immediately.

### Resume

When the state file already exists at remediation start:
1. Load it and present progress summary
2. Skip `applied` stages
3. Offer retry for `failed` stages
4. Continue with `pending` stages

### Finalize

When no `pending` stages remain, the state file persists for audit purposes.
