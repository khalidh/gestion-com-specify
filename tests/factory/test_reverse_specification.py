from __future__ import annotations

from pathlib import Path

import pytest
import yaml

from orchestrator.reverse_specification import AnalysisError, _review_artifacts, analyze_repository, write_run


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


def _make_fixture(root: Path) -> Path:
    fixture_files = {
        "specs/001-gestion-commerciale/spec.md": (
            "# Specification\n"
            "- **BR-001** (FR-001; TEST-001): Le code client doit etre unique.\n"
            "| TEST-001 | Creer un client et verifier son code unique. |\n"
        ),
        "specs/001-gestion-commerciale/data-model.yaml": (
            "model:\n  name: fixture\ndomains:\n  - name: Parties\n    tables:\n"
            "      - name: GC_PARTY\n      - name: GC_CUSTOMER\n"
            "      - name: GC_PARTY_ADDRESS\n      - name: GC_PARTY_CONTACT\n"
            "      - name: GC_PRODUCT\n      - name: GC_SALES_ORDER\n"
            "      - name: GC_CUSTOMER_INVOICE\n"
        ),
        "specs/001-gestion-commerciale/plan.md": "# Plan\n",
        "specs/001-gestion-commerciale/tasks.md": (
            "- [ ] T024 [US1] Creer le catalogue produit.\n"
            "- [ ] T028 [US1] Construire les pages APEX produit.\n"
        ),
        "database/changelog/changesets/001_gc_customer_foundation.sql": (
            "CREATE TABLE GC_APP.GC_PARTY (PARTY_ID NUMBER);\n"
            "CREATE TABLE GC_APP.GC_CUSTOMER (PARTY_ID NUMBER);\n"
        ),
        "apex/exports/gestion-commerciale-v1/f100.sql": (
            ",p_name=>'Clients'\nSELECT * FROM GC_APP.VW_GC_CUSTOMER_LIST;\n"
        ),
        "public/app.js": (
            "const state = {\n  customers: [],\n  products: [],\n  orders: [],\n  invoices: [],\n};\n"
        ),
        "ords/definitions/api-v1.yaml": "api:\n  status: proposed-not-published\n",
    }
    for relative_name, content in fixture_files.items():
        file_path = root / relative_name
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8")
    (root / ".env.local").write_text("DO_NOT_EXPORT=fixture-secret\n", encoding="utf-8")
    return root


def test_actual_workspace_facts_are_classified_from_allowlisted_sources() -> None:
    artifacts = analyze_repository(REPOSITORY_ROOT, "test-read-only")
    entities = {entity["id"]: entity for entity in artifacts["business_model"]["entities"]}

    assert artifacts["business_rules"]["rule_count"] == 50
    assert len(artifacts["inventory"]["sources"]) == 8
    assert artifacts["validation_plan"]["case_count"] == 25
    assert artifacts["validation_plan"]["status"] == "partial"
    assert artifacts["validation_plan"]["execution_allowed"] is False
    test_case = artifacts["validation_plan"]["cases"][0]
    assert test_case["id"] == "TEST-001"
    assert test_case["related_business_rules"] == ["BR-001", "BR-002", "BR-003"]
    assert test_case["execution_status"] == "not_run"
    assert artifacts["migration_proposal"]["metadata"] == artifacts["inventory"]["metadata"]
    assert artifacts["review"]["consistency_status"] == "passed"
    assert artifacts["review"]["status"] == "incomplete"
    assert artifacts["review"]["recommendation"] == "block_promotion"
    assert [finding["severity"] for finding in artifacts["review"]["findings"]] == ["medium"] * 3
    assert set(entities["client"]["observed_database_tables"]) == {
        "GC_PARTY",
        "GC_CUSTOMER",
        "GC_PARTY_ADDRESS",
        "GC_PARTY_CONTACT",
    }
    assert entities["client"]["implementation_status"] == "partial"
    assert entities["produit"]["implementation_status"] == "absent"
    assert entities["commande"]["implementation_status"] == "absent"
    assert entities["facture"]["implementation_status"] == "absent"
    assert entities["produit"]["prototype_demo_array"] == "products"
    assert artifacts["ords_status"] == "proposed-not-published"
    assert "draft_from_existing_design" in artifacts["target_architecture"]
    assert "pending_human_review" in artifacts["target_architecture"]
    assert "plan.md:L" in artifacts["target_architecture"]


def test_fixture_creates_sourced_outputs_only_under_generated_runs(tmp_path: Path) -> None:
    repo_root = _make_fixture(tmp_path / "repo")
    artifacts = analyze_repository(repo_root, "fixture-run")
    output_dir = write_run(repo_root, artifacts)

    assert output_dir == repo_root / "generated" / "runs" / "fixture-run"
    assert {path.name for path in output_dir.iterdir()} == {
        "inventory.yaml",
        "evidence.yaml",
        "business-rules.yaml",
        "business-model.yaml",
        "migration-proposal.yaml",
        "target-architecture.md",
        "validation-plan.yaml",
        "modernization-report.md",
    }
    output_text = "\n".join(path.read_text(encoding="utf-8") for path in output_dir.iterdir())
    assert "fixture-secret" not in output_text
    assert "blocked_missing_architecture_design" in (output_dir / "target-architecture.md").read_text(encoding="utf-8")
    validation_plan = yaml.safe_load((output_dir / "validation-plan.yaml").read_text(encoding="utf-8"))
    assert validation_plan["case_count"] == 1
    assert validation_plan["cases"][0]["related_business_rules"] == ["BR-001"]
    assert validation_plan["cases"][0]["execution_status"] == "not_run"
    assert validation_plan["execution_allowed"] is False
    assert "Revue automatique" in (output_dir / "modernization-report.md").read_text(encoding="utf-8")
    assert "line: 2" in output_text
    assert "T024" in output_text and "T028" in output_text


def test_run_id_cannot_escape_generated_runs(tmp_path: Path) -> None:
    repo_root = _make_fixture(tmp_path / "repo")
    artifacts = analyze_repository(repo_root, "safe-run")
    artifacts["inventory"]["metadata"]["run_id"] = "../escape"

    with pytest.raises(AnalysisError, match="Run ID"):
        write_run(repo_root, artifacts)
    assert not (tmp_path / "escape").exists()


def test_review_blocks_unknown_rule_references(tmp_path: Path) -> None:
    repo_root = _make_fixture(tmp_path / "repo")
    artifacts = analyze_repository(repo_root, "invalid-review")
    artifacts["validation_plan"]["cases"][0]["related_business_rules"] = ["BR-999"]

    review = _review_artifacts(artifacts)

    assert review["consistency_status"] == "failed"
    assert review["recommendation"] == "block_promotion"
    assert review["findings"][0]["severity"] == "high"


def test_missing_allowlisted_input_blocks_without_writing(tmp_path: Path) -> None:
    repo_root = _make_fixture(tmp_path / "repo")
    (repo_root / "public/app.js").unlink()

    with pytest.raises(AnalysisError, match="Cannot read allowlisted input"):
        analyze_repository(repo_root, "missing-source")
    assert not (repo_root / "generated/runs").exists()