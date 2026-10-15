---
description: "Use when producing modernization reports, business models, mappings, or other generated analysis artifacts. Requires provenance, status labels, and secret-safe output."
applyTo: "generated/**"
---
# Generated artifact rules

- Include workflow/run ID, source manifest reference, creation time, and approval status.
- Separate evidence-backed facts, proposed mappings, hypotheses, and unresolved conflicts.
- Link findings to repository-relative paths and stable requirement/rule/test identifiers where available.
- Do not copy credentials, environment values, raw logs, or unnecessary personal data into outputs.
- Keep unreviewed runs local; only human-approved artifacts may be promoted for version control.