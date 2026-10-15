"""Read-only retro-specification workflow for the commercial project."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml


SOURCE_FILES = {
    "specification": ("specs/001-gestion-commerciale/spec.md", "Functional specification and documented business rules."),
    "business_model": ("specs/001-gestion-commerciale/data-model.yaml", "Conceptual model; not a deployable schema."),
    "implementation_plan": ("specs/001-gestion-commerciale/plan.md", "Planned architecture and sequencing."),
    "implementation_tasks": ("specs/001-gestion-commerciale/tasks.md", "Planned work items; not implementation evidence."),
    "customer_ddl": ("database/changelog/changesets/001_gc_customer_foundation.sql", "Analyzed Oracle customer changeset."),
    "apex_export": ("apex/exports/gestion-commerciale-v1/f100.sql", "Oracle APEX application export."),
    "prototype": ("public/app.js", "Browser-only prototype; demo data is not production evidence."),
    "ords_contract": ("ords/definitions/api-v1.yaml", "Proposed ORDS contract; not a deployed definition."),
}

ENTITY_DEFINITIONS = (
    ("client", "CLIENT", ("GC_PARTY", "GC_CUSTOMER", "GC_PARTY_ADDRESS", "GC_PARTY_CONTACT"), "customers"),
    ("produit", "PRODUIT", ("GC_PRODUCT",), "products"),
    ("commande", "COMMANDE", ("GC_SALES_ORDER",), "orders"),
    ("facture", "FACTURE", ("GC_CUSTOMER_INVOICE",), "invoices"),
)

MIGRATION_TASK_GROUPS = (
    ("catalogue-tarification", "Catalogue et tarification", ("T022", "T023", "T024", "T025", "T026", "T028", "T030")),
    ("devis-commandes", "Devis et commandes", ("T031", "T032", "T034", "T036", "T037", "T040")),
    ("livraisons", "Livraisons", ("T051", "T052", "T053", "T054", "T055", "T057")),
    ("facturation-client", "Facturation client", ("T058", "T059", "T061", "T062", "T065", "T067")),
)

ARTIFACT_FILENAMES = (
    "inventory.yaml",
    "evidence.yaml",
    "business-rules.yaml",
    "business-model.yaml",
    "migration-proposal.yaml",
    "target-architecture.md",
    "validation-plan.yaml",
    "modernization-report.md",
)

RULE_PATTERN = re.compile(r"^\s*-\s+\*\*(BR-\d{3})\*\*\s*(.*)$")
REFERENCE_PATTERN = re.compile(r"\b(?:FR|TEST)-\d{3}\b")
TEST_CASE_PATTERN = re.compile(r"^\s*\|\s*(TEST-\d{3})\s*\|\s*(.*?)\s*\|\s*$")
TASK_PATTERN = re.compile(r"^\s*-\s+\[[ xX]\]\s+(T\d{3})\s+(.*)$")
CREATED_TABLE_PATTERN = re.compile(r"CREATE\s+TABLE\s+GC_APP\.(GC_[A-Z0-9_]+)", re.IGNORECASE)
PROTOTYPE_ARRAY_PATTERN = re.compile(r"^\s{2}(customers|products|orders|invoices):\s*\[", re.MULTILINE)


class AnalysisError(Exception):
    """Raised when an allowlisted input or output path is unsafe or invalid."""


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def _read_sources(repo_root: Path) -> tuple[Path, dict[str, str], list[dict[str, Any]]]:
    try:
        root = repo_root.resolve(strict=True)
    except OSError as error:
        raise AnalysisError(f"Repository root is not accessible: {repo_root}") from error
    if not root.is_dir():
        raise AnalysisError(f"Repository root is not a directory: {root}")

    sources: dict[str, str] = {}
    manifest: list[dict[str, Any]] = []
    for source_id, (relative_name, purpose) in SOURCE_FILES.items():
        relative_path = Path(relative_name)
        if any(part == ".git" or part.lower().startswith(".env") for part in relative_path.parts):
            raise AnalysisError(f"Protected path is not allowed as an input: {relative_name}")
        try:
            source_path = (root / relative_path).resolve(strict=True)
            source_path.relative_to(root)
            if not source_path.is_file():
                raise AnalysisError(f"Allowlisted input is not a file: {relative_name}")
            content = source_path.read_bytes()
            text = content.decode("utf-8-sig")
        except AnalysisError:
            raise
        except (OSError, UnicodeError, ValueError) as error:
            raise AnalysisError(f"Cannot read allowlisted input {relative_name}: {error}") from error
        sources[source_id] = text
        manifest.append(
            {
                "source_id": source_id,
                "path": relative_path.as_posix(),
                "purpose": purpose,
                "size_bytes": len(content),
                "sha256": hashlib.sha256(content).hexdigest(),
            }
        )
    return root, sources, manifest


def _load_yaml(source: str, source_name: str) -> dict[str, Any]:
    try:
        document = yaml.safe_load(source)
    except yaml.YAMLError as error:
        raise AnalysisError(f"Invalid YAML in {source_name}: {error}") from error
    if not isinstance(document, dict):
        raise AnalysisError(f"Expected a YAML mapping in {source_name}.")
    return document


def _line_number(source: str, needle: str) -> int | None:
    for line_number, line in enumerate(source.splitlines(), start=1):
        if needle in line:
            return line_number
    return None


def _extract_rules(specification: str) -> list[dict[str, Any]]:
    rules: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for line_number, line in enumerate(specification.splitlines(), start=1):
        match = RULE_PATTERN.match(line)
        if not match:
            continue
        rule_id, remainder = match.groups()
        if rule_id in seen_ids:
            raise AnalysisError(f"Duplicate business rule identifier: {rule_id}")
        seen_ids.add(rule_id)
        metadata = re.match(r"\(([^)]*)\):\s*(.*)$", remainder)
        if metadata:
            references = REFERENCE_PATTERN.findall(metadata.group(1))
            text = metadata.group(2)
        else:
            references = REFERENCE_PATTERN.findall(remainder)
            text = remainder
        rules.append(
            {
                "id": rule_id,
                "text": text.strip(),
                "references": sorted(set(references)),
                "evidence": {
                    "source_path": SOURCE_FILES["specification"][0],
                    "locator": f"{SOURCE_FILES['specification'][0]}:L{line_number}",
                    "line": line_number,
                    "classification": "specified",
                },
            }
        )
    return rules


def _extract_test_cases(specification: str, rules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rules_by_test: dict[str, set[str]] = {}
    for rule in rules:
        for reference in rule["references"]:
            if reference.startswith("TEST-"):
                rules_by_test.setdefault(reference, set()).add(rule["id"])

    cases: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for line_number, line in enumerate(specification.splitlines(), start=1):
        match = TEST_CASE_PATTERN.match(line)
        if not match:
            continue
        test_id, description = match.groups()
        if test_id in seen_ids:
            raise AnalysisError(f"Duplicate test case identifier: {test_id}")
        seen_ids.add(test_id)
        linked_rules = sorted(rules_by_test.get(test_id, set()))
        cases.append(
            {
                "id": test_id,
                "description": description.strip(),
                "related_business_rules": linked_rules,
                "coverage_status": "linked" if linked_rules else "missing_rule_links",
                "execution_status": "not_run",
                "evidence": {
                    "source_path": SOURCE_FILES["specification"][0],
                    "locator": f"{SOURCE_FILES['specification'][0]}:L{line_number}",
                    "line": line_number,
                    "classification": "specified",
                },
            }
        )
    return cases


def _extract_model_tables(model_document: dict[str, Any]) -> set[str]:
    domains = model_document.get("domains")
    if not isinstance(domains, list):
        raise AnalysisError("The conceptual model must contain a domains list.")
    table_names: set[str] = set()
    for domain in domains:
        if not isinstance(domain, dict):
            continue
        for table in domain.get("tables", []):
            if isinstance(table, dict) and isinstance(table.get("name"), str):
                table_names.add(table["name"].upper())
    return table_names


def _extract_tasks(task_source: str) -> dict[str, dict[str, Any]]:
    tasks: dict[str, dict[str, Any]] = {}
    for line_number, line in enumerate(task_source.splitlines(), start=1):
        match = TASK_PATTERN.match(line)
        if match:
            task_id, description = match.groups()
            tasks[task_id] = {"id": task_id, "description": description.strip(), "line": line_number}
    return tasks


def _build_entities(
    model_tables: set[str],
    physical_tables: set[str],
    model_source: str,
    ddl_source: str,
    apex_export: str,
    prototype: str,
) -> list[dict[str, Any]]:
    prototype_arrays = set(PROTOTYPE_ARRAY_PATTERN.findall(prototype))
    client_page_line = _line_number(apex_export, "p_name=>'Clients'")
    client_view_line = _line_number(apex_export, "VW_GC_CUSTOMER_LIST")
    entities: list[dict[str, Any]] = []

    for entity_id, name, expected_tables, prototype_array in ENTITY_DEFINITIONS:
        conceptual_tables = sorted(set(expected_tables) & model_tables)
        implemented_tables = sorted(set(expected_tables) & physical_tables)
        evidence: list[dict[str, Any]] = []

        for table_name in conceptual_tables:
            line = _line_number(model_source, f"name: {table_name}")
            evidence.append(
                {
                    "source_path": SOURCE_FILES["business_model"][0],
                    "locator": f"{SOURCE_FILES['business_model'][0]}:L{line}",
                    "classification": "specified",
                    "detail": f"Conceptual table {table_name}",
                }
            )
        for table_name in implemented_tables:
            evidence.append(
                {
                    "source_path": SOURCE_FILES["customer_ddl"][0],
                    "locator": f"{SOURCE_FILES['customer_ddl'][0]}:CREATE TABLE GC_APP.{table_name}",
                    "classification": "implemented",
                    "detail": f"Physical table {table_name} is created by the analyzed changeset.",
                }
            )

        apex_present = entity_id == "client" and bool(client_page_line and client_view_line)
        if apex_present:
            evidence.append(
                {
                    "source_path": SOURCE_FILES["apex_export"][0],
                    "locator": f"{SOURCE_FILES['apex_export'][0]}:L{client_page_line}, view at L{client_view_line}",
                    "classification": "implemented",
                    "detail": "The APEX export contains a Clients page and references the customer list view.",
                }
            )

        if prototype_array in prototype_arrays:
            line = _line_number(prototype, f"{prototype_array}: [")
            evidence.append(
                {
                    "source_path": SOURCE_FILES["prototype"][0],
                    "locator": f"{SOURCE_FILES['prototype'][0]}:L{line}",
                    "classification": "prototype_demo",
                    "detail": f"Static browser demo array: {prototype_array}.",
                }
            )

        has_implementation_evidence = bool(implemented_tables or apex_present)
        entities.append(
            {
                "id": entity_id,
                "name": name,
                "evidence_status": "implemented" if has_implementation_evidence else "specified",
                "implementation_status": "partial" if has_implementation_evidence else "absent",
                "conceptual_tables": conceptual_tables,
                "observed_database_tables": implemented_tables,
                "prototype_demo_array": prototype_array if prototype_array in prototype_arrays else None,
                "evidence": evidence,
                "assumptions": [],
            }
        )
    return entities


def _build_migration_proposal(
    tasks: dict[str, dict[str, Any]], metadata: dict[str, Any]
) -> dict[str, Any]:
    steps: list[dict[str, Any]] = []
    for step_id, title, task_ids in MIGRATION_TASK_GROUPS:
        sourced_tasks = [tasks[task_id] for task_id in task_ids if task_id in tasks]
        if not sourced_tasks:
            continue
        steps.append(
            {
                "id": step_id,
                "title": title,
                "status": "proposed_from_existing_plan",
                "source_path": SOURCE_FILES["implementation_tasks"][0],
                "tasks": [
                    {
                        **task,
                        "locator": f"{SOURCE_FILES['implementation_tasks'][0]}:L{task['line']}",
                        "classification": "proposed",
                    }
                    for task in sourced_tasks
                ],
            }
        )
    return {
        "metadata": metadata,
        "status": "proposal_only",
        "execution_allowed": False,
        "limitation": "Steps are extracted from existing planned tasks; no Forms conversion or migration execution is performed.",
        "steps": steps,
    }


def _review_artifacts(artifacts: dict[str, Any]) -> dict[str, Any]:
    inventory = artifacts["inventory"]
    manifest_paths = {source["path"] for source in inventory["sources"]}
    metadata = inventory["metadata"]
    metadata_artifacts = (
        artifacts["evidence"],
        artifacts["business_rules"],
        artifacts["business_model"],
        artifacts["migration_proposal"],
        artifacts["validation_plan"],
    )
    metadata_consistent = all(item.get("metadata") == metadata for item in metadata_artifacts)

    evidence_items = list(artifacts["evidence"]["items"])
    evidence_items.extend(rule["evidence"] for rule in artifacts["business_rules"]["rules"])
    evidence_items.extend(
        evidence
        for entity in artifacts["business_model"]["entities"]
        for evidence in entity["evidence"]
    )
    evidence_items.extend(case["evidence"] for case in artifacts["validation_plan"]["cases"])
    evidence_items.extend(
        {"source_path": step["source_path"]}
        for step in artifacts["migration_proposal"]["steps"]
    )
    source_paths_in_manifest = all(item["source_path"] in manifest_paths for item in evidence_items)

    rule_ids = {rule["id"] for rule in artifacts["business_rules"]["rules"]}
    test_cases = artifacts["validation_plan"]["cases"]
    test_links_resolve = all(
        case["coverage_status"] == "linked"
        and set(case["related_business_rules"]).issubset(rule_ids)
        for case in test_cases
    )
    test_count_consistent = artifacts["validation_plan"]["case_count"] == len(test_cases)
    execution_gates_closed = (
        metadata["approval_status"] == "pending_human_review"
        and artifacts["migration_proposal"]["execution_allowed"] is False
        and artifacts["validation_plan"]["execution_allowed"] is False
        and "Exécution autorisée : `false`" in artifacts["target_architecture"]
    )

    checks = [
        {"id": "metadata_consistency", "status": "passed" if metadata_consistent else "failed"},
        {"id": "evidence_sources_allowlisted", "status": "passed" if source_paths_in_manifest else "failed"},
        {"id": "test_rule_traceability", "status": "passed" if test_links_resolve else "failed"},
        {"id": "test_case_count", "status": "passed" if test_count_consistent else "failed"},
        {"id": "execution_gates", "status": "passed" if execution_gates_closed else "failed"},
    ]
    findings = [
        {
            "id": f"REV-{index:03d}",
            "severity": "high",
            "status": "open",
            "summary": f"Automatic consistency check failed: {check['id']}.",
            "evidence": [check["id"]],
        }
        for index, check in enumerate((item for item in checks if item["status"] == "failed"), start=1)
    ]
    findings.extend(
        [
            {
                "id": "REV-101",
                "severity": "medium",
                "status": "open",
                "summary": "No Oracle Forms source is in the analyzed manifest; Forms conversion cannot be reviewed.",
                "evidence": ["migration-proposal.yaml:limitation", "inventory.yaml:sources"],
            },
            {
                "id": "REV-102",
                "severity": "medium",
                "status": "open",
                "summary": "Specified test scenarios have not been executed; behavioral conformance remains unverified.",
                "evidence": ["validation-plan.yaml:cases[].execution_status"],
            },
            {
                "id": "REV-103",
                "severity": "medium",
                "status": "open",
                "summary": "Target platform versions and hosting topology remain unresolved.",
                "evidence": ["target-architecture.md:Contraintes non résolues"],
            },
        ]
    )
    severity_order = {"high": 0, "medium": 1, "low": 2, "info": 3}
    findings.sort(key=lambda finding: (severity_order[finding["severity"]], finding["id"]))
    consistency_passed = all(check["status"] == "passed" for check in checks)
    return {
        "status": "incomplete",
        "consistency_status": "passed" if consistency_passed else "failed",
        "recommendation": "block_promotion",
        "checks": checks,
        "findings": findings,
    }


def _render_report(artifacts: dict[str, Any]) -> str:
    inventory = artifacts["inventory"]
    rules = artifacts["business_rules"]["rules"]
    proposal = artifacts["migration_proposal"]
    validation_plan = artifacts["validation_plan"]
    review = artifacts["review"]
    rows = [
        "| Entité | Tables conceptuelles | Tables du DDL analysé | Démo navigateur | État constaté |",
        "|---|---|---|---|---|",
    ]
    gaps: list[str] = []
    for entity in artifacts["business_model"]["entities"]:
        concepts = ", ".join(entity["conceptual_tables"]) or "non observé"
        physical = ", ".join(entity["observed_database_tables"]) or "aucune dans le changeset analysé"
        demo = entity["prototype_demo_array"] or "aucune"
        rows.append(
            f"| {entity['name']} | {concepts} | {physical} | {demo} | {entity['implementation_status']} |"
        )
        if not entity["observed_database_tables"]:
            gaps.append(
                f"- **{entity['name']}** : le concept est spécifié, mais aucun DDL correspondant n'est présent dans le changeset analysé. La liste du prototype est classée comme démonstration uniquement."
            )
        else:
            gaps.append(
                f"- **{entity['name']}** : un socle physique/APEX est observé ; les sources analysées ne démontrent pas le cycle métier complet."
            )

    source_lines = [f"- `{source['path']}` (SHA-256 `{source['sha256']}`)" for source in inventory["sources"]]
    migration_lines = [
        f"- **{step['title']}** : tâches existantes {', '.join(task['id'] for task in step['tasks'])}."
        for step in proposal["steps"]
    ] or ["- Aucune tâche correspondante n'a été trouvée dans le plan de tâches autorisé."]
    review_check_lines = [
        f"- `{check['id']}` : {check['status']}." for check in review["checks"]
    ]
    review_finding_lines = [
        f"- **{finding['id']} ({finding['severity'].upper()})** : {finding['summary']} Preuves : {', '.join(finding['evidence'])}."
        for finding in review["findings"]
    ]
    return "\n".join(
        [
            "# Rapport de rétro-spécification",
            "",
            f"- Workflow : `{inventory['metadata']['workflow_id']}`",
            f"- Exécution : `{inventory['metadata']['run_id']}`",
            f"- Créé le : `{inventory['metadata']['created_at']}`",
            f"- Approbation : `{inventory['metadata']['approval_status']}`",
            f"- Manifeste source SHA-256 : `{inventory['metadata']['source_manifest_sha256']}`",
            "",
            "## Sources lues",
            *source_lines,
            "",
            "## Entités demandées",
            *rows,
            "",
            "## Règles métier",
            f"{len(rules)} règles BR extraites de la spécification avec références FR/TEST et lignes source. Leur extraction ne signifie pas qu'elles sont implémentées.",
            "",
            "## Écarts observés",
            *gaps,
            f"- **ORDS** : statut documentaire `{artifacts['ords_status']}` ; ce statut ne prouve pas qu'une API est déployée.",
            "- **Oracle Forms** : aucune conversion n'est évaluée ; le workflow ne lit que les chemins allowlistés du manifeste.",
            "",
            "## Étapes APEX proposées",
            "Les éléments ci-dessous reprennent les IDs du plan de tâches existant et restent soumis à ses gates.",
            *migration_lines,
            "",
            "## Validation proposée",
            f"{validation_plan['case_count']} scénarios TEST sont liés aux règles métier; aucun n'a été exécuté par ce workflow.",
            "Le plan reste partiel jusqu'à la définition des préconditions et à l'approbation d'un environnement isolé.",
            "",
            "## Revue automatique",
            f"- Cohérence : `{review['consistency_status']}`.",
            f"- Revue : `{review['status']}`; recommandation : `{review['recommendation']}`.",
            *review_check_lines,
            "",
            "### Findings ouverts",
            *review_finding_lines,
            "",
            "## Limites et validation",
            "Les absences sont limitées au changeset et aux artefacts explicitement analysés. Les données du prototype sont des exemples statiques, pas des faits métier. Aucune base n'a été interrogée et aucune migration n'a été exécutée.",
            "",
        ]
    )


def _render_architecture_proposal(
    specification: str, implementation_plan: str, metadata: dict[str, Any]
) -> str:
    validated_line = _line_number(specification, "**Validated**")
    summary_line = _line_number(implementation_plan, "## Summary")
    project_type_line = _line_number(implementation_plan, "**Project Type**")
    target_platform_line = _line_number(implementation_plan, "**Target Platform**")
    design_available = all((summary_line, project_type_line, target_platform_line))
    status = "draft_from_existing_design" if design_available else "blocked_missing_architecture_design"
    spec_locator = f"{SOURCE_FILES['specification'][0]}:L{validated_line}" if validated_line else SOURCE_FILES["specification"][0]
    plan_locator = f"{SOURCE_FILES['implementation_plan'][0]}:L{summary_line}" if summary_line else SOURCE_FILES["implementation_plan"][0]
    type_locator = f"{SOURCE_FILES['implementation_plan'][0]}:L{project_type_line}" if project_type_line else SOURCE_FILES["implementation_plan"][0]
    platform_locator = f"{SOURCE_FILES['implementation_plan'][0]}:L{target_platform_line}" if target_platform_line else SOURCE_FILES["implementation_plan"][0]

    if design_available:
        architecture_section = "\n".join(
            [
                "## Architecture proposée pour revue",
                "",
                f"- **Style** : monolithe modulaire Oracle, comme défini dans le plan (`{plan_locator}`).",
                f"- **Métier** : les packages PL/SQL portent les règles et transitions métier; APEX reste la présentation et ORDS l'adaptateur REST (`{type_locator}`).",
                f"- **Évolution** : livrer par modules, avec changements de schéma versionnés et tests utPLSQL/Playwright, selon le plan (`{plan_locator}`).",
                "- **Alternative** : aucune cible non-Oracle n'est comparée, car le plan impose Oracle; une comparaison nécessiterait une demande de changement de contrainte.",
                "",
                "## Contraintes non résolues",
                f"- Les versions Oracle, APEX et ORDS, ainsi que la topologie d'hébergement, restent à confirmer (`{platform_locator}`).",
                "- Les gates réglementaires, de sécurité et d'exploitation restent à lever avant toute implémentation, selon le plan.",
                f"- L'approbation de la spécification (`{spec_locator}`) ne vaut pas levée des gates d'implémentation.",
                "",
            ]
        )
    else:
        architecture_section = "\n".join(
            [
                "## Architecture proposée",
                "",
                "- **Statut** : bloquée; les sources autorisées ne contiennent pas les marqueurs de conception requis.",
                f"- Plan consulté : `{SOURCE_FILES['implementation_plan'][0]}`.",
                "- Aucune cible, frontière ou technologie n'est inférée en l'absence de conception sourcée.",
                "",
            ]
        )

    return "\n".join(
        [
            "# Proposition d'architecture cible",
            "",
            f"- Workflow : `{metadata['workflow_id']}`",
            f"- Exécution : `{metadata['run_id']}`",
            f"- Créé le : `{metadata['created_at']}`",
            f"- Approbation : `{metadata['approval_status']}`",
            f"- Manifeste source SHA-256 : `{metadata['source_manifest_sha256']}`",
            f"- Statut : `{status}`",
            "- Exécution autorisée : `false`",
            "",
            "## Base de conception",
            "",
            f"La spécification est marquée validée dans `{spec_locator}`. Cela ne constitue pas une autorisation d'implémenter.",
            "",
            architecture_section,
            "## Gate humain",
            "",
            "Un responsable d'architecture doit confirmer la cible, les versions, les frontières de données, la sécurité et l'impact sur l'application Oracle existante avant toute promotion.",
            "",
        ]
    )


def analyze_repository(repo_root: Path, run_id: str | None = None) -> dict[str, Any]:
    """Analyze fixed, allowlisted sources and return drafts without writing files."""
    chosen_run_id = run_id or datetime.now(timezone.utc).strftime("run-%Y%m%dT%H%M%S%fZ")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", chosen_run_id) or ".." in chosen_run_id:
        raise AnalysisError("Run ID must be a simple name without path separators or '..'.")

    _, sources, source_manifest = _read_sources(Path(repo_root))
    model_document = _load_yaml(sources["business_model"], SOURCE_FILES["business_model"][0])
    ords_document = _load_yaml(sources["ords_contract"], SOURCE_FILES["ords_contract"][0])
    model_tables = _extract_model_tables(model_document)
    physical_tables = set(CREATED_TABLE_PATTERN.findall(sources["customer_ddl"]))
    rules = _extract_rules(sources["specification"])
    test_cases = _extract_test_cases(sources["specification"], rules)
    task_index = _extract_tasks(sources["implementation_tasks"])
    manifest_bytes = yaml.safe_dump(source_manifest, sort_keys=True, allow_unicode=True).encode("utf-8")
    manifest_hash = hashlib.sha256(manifest_bytes).hexdigest()
    metadata = {
        "workflow_id": "reverse-specification",
        "run_id": chosen_run_id,
        "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "approval_status": "pending_human_review",
        "source_manifest_sha256": manifest_hash,
    }
    entities = _build_entities(
        model_tables,
        physical_tables,
        sources["business_model"],
        sources["customer_ddl"],
        sources["apex_export"],
        sources["prototype"],
    )
    evidence = [
        {"entity_id": entity["id"], **item}
        for entity in entities
        for item in entity["evidence"]
    ]
    migration_proposal = _build_migration_proposal(task_index, metadata)
    artifacts: dict[str, Any] = {
        "inventory": {
            "metadata": metadata,
            "sources": source_manifest,
            "excluded_inputs": [".env*", ".git/**", "logs", "dumps", "dependency folders", "paths outside the fixed allowlist"],
        },
        "evidence": {"metadata": metadata, "items": evidence},
        "business_rules": {"metadata": metadata, "rule_count": len(rules), "rules": rules},
        "business_model": {"metadata": metadata, "status": "draft", "entities": entities},
        "migration_proposal": migration_proposal,
        "target_architecture": _render_architecture_proposal(
            sources["specification"], sources["implementation_plan"], metadata
        ),
        "validation_plan": {
            "metadata": metadata,
            "status": "partial",
            "execution_allowed": False,
            "execution_prerequisites": [
                "Approve synthetic test data and fixtures.",
                "Confirm an isolated test environment before service or database execution.",
            ],
            "case_count": len(test_cases),
            "cases": test_cases,
        },
        "ords_status": ords_document.get("api", {}).get("status", "not_observed"),
    }
    artifacts["review"] = _review_artifacts(artifacts)
    artifacts["modernization_report"] = _render_report(artifacts)
    return artifacts


def write_run(repo_root: Path, artifacts: dict[str, Any]) -> Path:
    """Write known artifacts to a unique folder beneath generated/runs only."""
    try:
        root = Path(repo_root).resolve(strict=True)
        runs_root = (root / "generated" / "runs").resolve()
        runs_root.relative_to(root)
    except (OSError, ValueError) as error:
        raise AnalysisError("Generated output root must remain beneath the repository.") from error

    run_id = artifacts["inventory"]["metadata"]["run_id"]
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", run_id) or ".." in run_id:
        raise AnalysisError("Run ID must be a simple name without path separators or '..'.")
    output_dir = runs_root / run_id
    if not _is_within(output_dir.resolve(), runs_root) or output_dir.exists():
        raise AnalysisError("Generated output path is unsafe or already exists; refusing to overwrite.")

    payloads = {
        "inventory.yaml": artifacts["inventory"],
        "evidence.yaml": artifacts["evidence"],
        "business-rules.yaml": artifacts["business_rules"],
        "business-model.yaml": artifacts["business_model"],
        "migration-proposal.yaml": artifacts["migration_proposal"],
        "target-architecture.md": artifacts["target_architecture"],
        "validation-plan.yaml": artifacts["validation_plan"],
        "modernization-report.md": artifacts["modernization_report"],
    }
    output_dir.mkdir(parents=True, exist_ok=False)
    for filename in ARTIFACT_FILENAMES:
        content = payloads[filename]
        rendered = content if isinstance(content, str) else yaml.safe_dump(content, sort_keys=False, allow_unicode=True)
        (output_dir / filename).write_text(rendered, encoding="utf-8", newline="\n")
    return output_dir


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Create an evidence-linked, read-only modernization report.")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--run-id", help="Optional unique output folder name; path separators are rejected.")
    arguments = parser.parse_args(argv)
    try:
        artifacts = analyze_repository(arguments.repo_root, arguments.run_id)
        output_dir = write_run(arguments.repo_root, artifacts)
    except (AnalysisError, OSError, yaml.YAMLError) as error:
        print(f"Analyse bloquée : {error}", file=sys.stderr)
        return 2

    relative_output = output_dir.relative_to(arguments.repo_root.resolve())
    print(
        f"Rapport créé sous {relative_output} ({artifacts['business_rules']['rule_count']} règles, "
        f"{len(artifacts['business_model']['entities'])} entités); validation humaine requise."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())