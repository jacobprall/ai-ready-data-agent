# AI-Ready Data Agent

Optimize Snowflake data for AI workloads. Assesses your data against use-case-specific requirements and walks you through fixes — all in SQL.

## Installation

### Via npx skills (Recommended)

Install to your preferred coding agent with a single command:

```bash
# Install to Cortex Code
npx skills add owner/ai-ready-data-agent -a cortex

# Install to Claude Code
npx skills add owner/ai-ready-data-agent -a claude-code

# Install globally (available in all projects)
npx skills add owner/ai-ready-data-agent -g

# List available agents
npx skills add owner/ai-ready-data-agent --list
```

### Manual Installation

Clone or add this repo as workspace context in your coding agent. The agent reads `AGENTS.md` automatically, which points to the skill in `skills/ai-ready-data/`.

## What It Does

Point Cortex Code at this repo and tell it to assess your data. The agent:

1. **Discovers** your schema (database, tables, row counts)
2. **Assesses** data against a use case (e.g., RAG) — runs read-only SQL checks, compares to thresholds
3. **Remediates** failing requirements stage-by-stage with your approval
4. **Verifies** improvements by re-running checks

Every check returns a value between 0 and 1. Pass/fail is determined by the use case's thresholds. All operations are SQL — no Python, no packages, no infrastructure.

## Quick Start

**1. Add this repo as workspace context in Cortex Code.**

Cortex Code reads `AGENTS.md` automatically, which points to `SKILL.md`.

**2. Tell the agent what to assess:**

> Assess my database for RAG readiness. I'm connected to MY_DB.MY_SCHEMA.

The agent asks scoping questions, runs checks, presents results by stage, and offers to fix what's failing.

---

## Use Cases

Use cases define what "AI-ready" means for a specific workload. Each use case has **stages** — ordered groups of requirements with thresholds.

| Use Case | File | Stages |
|----------|------|--------|
| **RAG Service** | [skills/ai-ready-data/use-cases/rag.yaml](skills/ai-ready-data/use-cases/rag.yaml) | Data Quality, Schema Understanding, Retrieval Performance, Change Management, Data Governance |

## Requirements

Requirements are the measurable dimensions of data readiness, organized by six factors. Each has SQL checks, diagnostics, and remediation operations. Every requirement declares a `workload` (serving, training, or both) and a `description` in `index.yaml`. The `direction` (`lte` or `gte`) lives in each requirement's `meta.yaml`.

| Factor | Examples |
|--------|----------|
| **Clean** | `data_completeness`, `uniqueness`, `schema_conformity`, `value_range_validity`, `outlier_prevalence` |
| **Contextual** | `semantic_documentation`, `relationship_declaration`, `schema_type_coverage`, `business_glossary_linkage` |
| **Consumable** | `access_optimization`, `search_optimization`, `serving_latency_compliance`, `embedding_coverage` |
| **Current** | `change_detection`, `data_freshness`, `propagation_latency_compliance`, `point_in_time_correctness` |
| **Correlated** | `data_provenance`, `lineage_completeness`, `data_version_coverage`, `agent_attribution` |
| **Compliant** | `classification`, `field_masking`, `access_audit_coverage`, `bias_testing_coverage` |

Full definitions (54 requirements): [skills/ai-ready-data/requirements/index.yaml](skills/ai-ready-data/requirements/index.yaml).

---

## Repo Structure

```
AGENTS.md                              Entry point (points to skills/)
README.md                              This file
CONTRIBUTING.md                        Contribution guidelines
skills/
  ai-ready-data/                       Main skill directory
    SKILL.md                           Skill definition: role, conventions, workflows
    use-cases/                         Use case definitions (stages + thresholds)
    requirements/                      One directory per requirement (SQL + metadata)
      index.yaml                    All requirement definitions
    workflows/                         Step-by-step workflow guides
    reference/                         Snowflake gotchas and permissions
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and [CONTRIBUTORS.md](CONTRIBUTORS.md) to add your name.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
