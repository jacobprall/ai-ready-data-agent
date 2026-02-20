# Contributing

Contributions are welcome. Please read this guide before submitting a PR.

To add yourself as a contributor, see [CONTRIBUTORS.md](CONTRIBUTORS.md).

## Repo Structure

```
ai-ready-data-agent/
├── AGENTS.md                            # Entry point for coding agents
├── README.md                            # Overview for humans
├── CONTRIBUTING.md                      # This file
├── skills/
│   └── ai-ready-data/                   # Main skill (npx skills compatible)
│       ├── SKILL.md                     # Skill definition (role, conventions, workflows)
│       ├── use-cases/
│       │   └── rag.yaml                 # RAG use case: stages, requirements, thresholds
│       ├── requirements/
│       │   ├── index.yaml            # All requirement definitions
│       │   └── {requirement}/           # One directory per requirement
│       │       ├── meta.yaml             #   Direction, operation metadata (warnings, idempotent flags)
│       │       ├── check-*.sql          #   Assessment queries (read-only)
│       │       ├── diagnostic-*.sql     #   Detail/context queries (read-only)
│       │       └── apply-*.sql          #   Remediation queries (mutating)
│       ├── workflows/
│       │   ├── discover.md              # Scope: database, schema, tables, use case
│       │   ├── assess.md                # Run checks, present results
│       │   ├── remediate.md             # Stage-by-stage fixes with approval
│       │   ├── verify.md                # Re-run checks, confirm improvements
│       │   └── state.md                 # Cross-session state tracking
│       └── reference/
│           ├── gotchas.md               # Snowflake SQL pitfalls + permissions
│           └── placeholders.yaml        # SQL placeholder reference
```

---

## Adding a Use Case

To add a new use case (e.g., ML training, analytics):

1. Create `skills/ai-ready-data/use-cases/{name}.yaml` following the format of `rag.yaml`
2. Define stages with `name`, `why`, and `requirements` (each with `min` or `max` threshold)
3. Reference only requirements that exist in `requirements/index.yaml`
4. Threshold keys must match requirement direction: `max` for `lte`, `min` for `gte`

---

## Adding a Requirement

To add a new measurable requirement:

1. Add the definition to `skills/ai-ready-data/requirements/index.yaml` with `workload` and `description`, and add `direction` to its `meta.yaml`
2. Create `skills/ai-ready-data/requirements/{requirement_key}/` directory (snake_case, matching the key in index.yaml)
3. Add at minimum one `check-*.sql` file that returns a `value` column (float, 0-1)
4. Add `meta.yaml` with operation metadata (warnings, idempotent flags)
5. Optionally add `diagnostic-*.sql` and `apply-*.sql` files
6. Reference the requirement in relevant use case files with appropriate thresholds

### SQL Conventions

- `check-*` files must return a `value` column (float, 0-1)
- Use `{{ placeholder }}` for inputs (e.g., `{{ container }}`, `{{ namespace }}`, `{{ asset }}`)
- See `reference/placeholders.yaml` for the full list of available placeholders
- All SQL is Snowflake-native
- Check `reference/gotchas.md` for known pitfalls

---

## Adding or Updating a Workflow

Workflow guides live in `skills/ai-ready-data/workflows/`. They describe *what* to do and *in what order*. SQL is loaded from `requirements/` at runtime.

---

## Adding a New Skill

This repo uses the `npx skills` format. To add a new skill:

1. Create `skills/{skill-name}/` directory
2. Add `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What this skill does
   ---
   ```
3. Add supporting files (workflows, references, etc.)
4. Update root `AGENTS.md` to reference the new skill
