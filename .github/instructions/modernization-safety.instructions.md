---
description: "Use when analyzing or designing enterprise modernization workflows, adapters, agents, or generated artifacts. Enforces read-only source handling, evidence, and human approval gates."
applyTo: ["agents/**", "orchestrator/**", "adapters/**", "models/**", "knowledge/**", "workflows/**", "generated/**", "tests/factory/**"]
---
# Modernization safety

- Treat existing application sources as read-only; write drafts only to the designated generated run area.
- Exclude `.env*`, `.git`, logs, dumps, dependency/build folders, and production data from discovery and outputs.
- Cite source paths and locators for every extracted fact. Mark hypotheses, demo data, conflicts, and missing evidence explicitly.
- Do not invent business rules or silently resolve contradictions.
- Never connect to or mutate a database, deploy an API, publish code, or run a migration without explicit human approval and an isolated environment.
- Keep generated proposals separate from source. Require review before promotion to specifications, knowledge, or implementation.