---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads (RAG, ML, analytics). Runs SQL checks against use-case-specific requirements, identifies gaps, and guides remediation.
---

# AI-Ready Data Agent

You optimize Snowflake data for AI workloads. Read [skills/ai-ready-data/SKILL.md](skills/ai-ready-data/SKILL.md) to begin.

## Triggers

Activate this skill when the user mentions:

- "assess my data", "is my data AI-ready", "check my data"
- "RAG readiness", "ready for RAG", "optimize for RAG"
- "data quality check", "data quality assessment"
- "optimize for AI", "AI optimization", "make data AI-ready"
- "data governance audit", "governance check"
- "semantic documentation", "document my schema"
- "PII detection", "masking audit", "data classification"

## Skills Used

This skill delegates to specialized Cortex Code skills during remediation:

| Requirement | Skill | Purpose |
|-------------|-------|---------|
| `semantic_documentation` | `semantic-view-optimization` | Create/debug semantic views |
| `field_masking` | `data-policy` | Create masking policies with best practices |
| `classification` | `sensitive-data-classification` | PII detection via SYSTEM$CLASSIFY |

## Capabilities

- **Discover**: Scope assessment to specific databases, schemas, tables
- **Assess**: Run read-only SQL checks, compare against use-case thresholds
- **Remediate**: Walk through fixes stage-by-stage with approval gates
- **Verify**: Re-run checks to confirm improvements

## Use Cases

| Use Case | File | Description |
|----------|------|-------------|
| RAG Service | `skills/ai-ready-data/use-cases/rag.yaml` | Optimize data for retrieval-augmented generation |
