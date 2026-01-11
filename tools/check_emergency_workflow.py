#!/usr/bin/env python3
import sys
from pathlib import Path

def warn(msg: str) -> None:
    # GitHub Actions warning annotation
    print(f"::warning title=Emergency Governance Preflight::{msg}")

def ok(msg: str) -> None:
    print(f"[emergency-preflight] {msg}")

def main() -> int:
    wf = Path(".github/workflows/emergency-auto-approve.yml")
    if not wf.exists():
        warn(f"{wf} not found. Emergency auto-approve safeguard is missing.")
        return 0  # warn-only

    try:
        import yaml  # pyyaml is available on ubuntu-latest runners
    except Exception:
        warn("PyYAML not available; cannot validate emergency workflow structure.")
        return 0

    try:
        data = yaml.safe_load(wf.read_text(encoding="utf-8"))
    except Exception as e:
        warn(f"{wf} is not valid YAML: {e}")
        return 0

    if not isinstance(data, dict):
        warn(f"{wf} YAML root is not a mapping/object.")
        return 0

    # Basic expected fields
    name = data.get("name")
    on = data.get("on")
    perms = data.get("permissions")
    jobs = data.get("jobs")

    if not name or "Emergency" not in str(name):
        warn("Emergency workflow: missing/odd top-level 'name' (expected to include 'Emergency').")

    if not isinstance(on, dict) or "workflow_run" not in on:
        warn("Emergency workflow: missing 'on.workflow_run' trigger.")
    else:
        wr = on.get("workflow_run", {})
        workflows = wr.get("workflows", [])
        types = wr.get("types", [])
        if "Compliance" not in workflows:
            warn("Emergency workflow: on.workflow_run.workflows does not include 'Compliance'.")
        if "completed" not in types:
            warn("Emergency workflow: on.workflow_run.types does not include 'completed'.")

    if not isinstance(perms, dict):
        warn("Emergency workflow: missing/invalid top-level 'permissions'.")
    else:
        if perms.get("pull-requests") != "write":
            warn("Emergency workflow: permissions.pull-requests should be 'write'.")

    if not isinstance(jobs, dict) or "approve" not in jobs:
        warn("Emergency workflow: missing jobs.approve.")
        return 0

    approve = jobs.get("approve", {})
    steps = approve.get("steps", [])
    if not isinstance(steps, list):
        warn("Emergency workflow: jobs.approve.steps is not a list.")
        return 0

    # Look for the emergency token usage to ensure it cannot run without the secret
    text = wf.read_text(encoding="utf-8")
    if "QT_EMERGENCY_REVIEW_TOKEN" not in text:
        warn("Emergency workflow: QT_EMERGENCY_REVIEW_TOKEN is not referenced.")
    if "EMERGENCY-MODE:" not in text:
        warn("Emergency workflow: EMERGENCY-MODE: gate is not present.")

    ok("Preflight completed (warn-only).")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
