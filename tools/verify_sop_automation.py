#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import os, sys, json, re, datetime, shutil, subprocess, textwrap, urllib.request

REPO = Path(".").resolve()

def now_ts():
    return datetime.datetime.now().strftime("%Y-%m-%d %H%M ET")

def die(msg: str, code: int = 1):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(code)

def ok(msg: str):
    print(f"OK: {msg}")

def warn(msg: str):
    print(f"WARN: {msg}")

def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")

def write(p: Path, s: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

def backup(p: Path):
    if p.exists():
        ts = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S_ET")
        b = p.with_suffix(p.suffix + f".bak.{ts}")
        shutil.copy2(p, b)
        ok(f"backup: {p} -> {b}")

def rel_link(from_path: Path, to_path: Path) -> str:
    return os.path.relpath(to_path.resolve(), start=from_path.parent.resolve())

def make_alias_md(alias_path: Path, canonical_path: Path, title: str):
    # "Alias" doc: investor-safe pointer. No secrets.
    content = f"""# {title} (Data Room Alias)

_Last updated: {now_ts()}_

This is an **investor-safe alias** that points to the canonical source of truth:

- Canonical: `{canonical_path.as_posix()}`
- Link: [{canonical_path.name}]({rel_link(alias_path, canonical_path)})

Governance note:
- Notion explains the system; it does not define or enforce it.
- Enforcement lives in code and is traceable in Git history / CHANGELOG.

"""
    write(alias_path, content)
    ok(f"alias created: {alias_path} -> {canonical_path}")

def ensure_root_readme_pointer(fix: bool):
    p = REPO / "README.md"
    if not p.exists():
        warn("README.md missing (repo root). Skipping pointer check.")
        return True

    src = read(p)
    needle = "## Data Room"
    pointer_block = textwrap.dedent("""\
    ## Data Room

    Investor-facing, GitHub-safe external disclosure index:
    - [docs/Data_Room/README.md](docs/Data_Room/README.md)

    """)
    if needle in src and "docs/Data_Room/README.md" in src:
        ok("root README: Data Room pointer present")
        return True

    if not fix:
        warn("root README: Data Room pointer missing (run with --fix to add)")
        return False

    backup(p)
    # Append near end, avoiding complicated section parsing
    src2 = src.rstrip() + "\n\n" + pointer_block
    write(p, src2)
    ok("root README: added Data Room pointer")
    return True

def verify_data_room(fix: bool) -> bool:
    required = [
        "docs/Data_Room/README.md",
        "docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology/README.md",
        "docs/WBS_MASTER_FORMAT.md",
        "ARCHITECTURE.md",
        "SECURITY.md",
        "docs/SOP_NOTION_LOG_ORDERING.md",
        "docs/EXEC_SUMMARY.md",
        "qtlog.sh",
        "CHANGELOG.md",
    ]
    missing = [p for p in required if not (REPO / p).exists()]
    if missing:
        for m in missing:
            warn(f"missing required: {m}")
        return False

    ok("required files: all present")

    # Ensure Data Room "alias" docs exist in the methodology folder
    dr_dir = REPO / "docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology"
    aliases = [
        ("WBS_MASTER_FORMAT.md", REPO/"docs/WBS_MASTER_FORMAT.md", "WBS Master Format"),
        ("ARCHITECTURE.md",      REPO/"ARCHITECTURE.md",         "Architecture"),
        ("SOP_NOTION_LOG_ORDERING.md", REPO/"docs/SOP_NOTION_LOG_ORDERING.md", "Notion Log Ordering SOP"),
        ("EXEC_SUMMARY.md",      REPO/"docs/EXEC_SUMMARY.md",    "Executive Summary (Non-Technical)"),
    ]

    ok_all = True
    for fname, canonical, title in aliases:
        alias_path = dr_dir / fname
        if alias_path.exists():
            ok(f"alias present: {alias_path}")
        else:
            ok_all = False
            warn(f"alias missing: {alias_path}")
            if fix:
                make_alias_md(alias_path, canonical, title)

    # sanity: verify methodology README references canonical items
    pm_readme = dr_dir / "README.md"
    src = read(pm_readme)
    for s in ["docs/WBS_MASTER_FORMAT.md", "qtlog.sh", "CHANGELOG.md", "docs/EXEC_SUMMARY.md", "docs/SOP_NOTION_LOG_ORDERING.md", "ARCHITECTURE.md"]:
        if s not in src:
            ok_all = False
            warn(f"PM README missing reference: {s}")

    if ok_all:
        ok("Data Room completeness: PASS")
    else:
        warn("Data Room completeness: needs attention (use --fix where possible)")
    return ok_all

def notion_get_children(block_id: str, api_key: str, page_size: int = 200):
    url = f"https://api.notion.com/v1/blocks/{block_id}/children?page_size={page_size}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {api_key}",
        "Notion-Version": "2022-06-28",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8", errors="replace"))

def notion_titles_from_blocks(results):
    titles = []
    for b in results or []:
        t = b.get("type")
        if t in ("heading_1","heading_2","heading_3"):
            rt = b.get(t, {}).get("rich_text", [])
        elif t == "toggle":
            rt = b.get("toggle", {}).get("rich_text", [])
        else:
            continue
        txt = "".join([x.get("plain_text","") for x in rt]).strip()
        if txt:
            titles.append(txt)
    return titles

def verify_notion_github_drift() -> bool:
    api_key = os.getenv("NOTION_API_KEY","").strip()
    big_picture_id = os.getenv("QT_BIG_PICTURE_PAGE_ID","").strip()

    if not api_key or not big_picture_id:
        warn("Notion drift check: SKIP (set NOTION_API_KEY and QT_BIG_PICTURE_PAGE_ID to enable)")
        return True

    expected_notion = [
        "QT - Canon",
        "QT - Log",
        "QT - ToDo",
        "QT - WBS Crosswalk Dashboard",
        "QT - Due Diligence",
        "QT - Investors",
    ]
    expected_github = [
        "docs/00_Administration",
        "docs/01_Legal",
        "docs/02_Finance",
        "docs/03_Technical",
        "docs/04_Defense",
        "docs/Data_Room",
    ]

    # GitHub structure presence
    gh_ok = True
    for p in expected_github:
        if not (REPO / p).exists():
            gh_ok = False
            warn(f"GitHub drift: missing folder {p}")

    # Notion structure presence (titles under Big Picture page)
    try:
        payload = notion_get_children(big_picture_id, api_key)
        titles = notion_titles_from_blocks(payload.get("results", []))
    except Exception as e:
        warn(f"Notion drift: FAIL to read Big Picture children ({e})")
        return False

    notion_ok = True
    for t in expected_notion:
        if t not in titles:
            notion_ok = False
            warn(f"Notion drift: missing expected item '{t}' under QT Big Picture page")

    if gh_ok and notion_ok:
        ok("Notion↔GitHub drift: PASS (expected top-level items present)")
        return True

    warn("Notion↔GitHub drift: needs attention (missing items detected)")
    return False

def main():
    fix = "--fix" in sys.argv
    # repo sanity
    if not (REPO / ".git").exists():
        die("not a git repo (run from repo root)")

    ok(f"verify start: {now_ts()} (fix={fix})")

    pass1 = verify_data_room(fix)
    pass2 = ensure_root_readme_pointer(fix)
    pass3 = verify_notion_github_drift()

    if pass1 and pass2 and pass3:
        ok("ALL CHECKS PASSED")
        return 0
    warn("CHECKS FAILED (see WARN/FAIL above)")
    return 2

if __name__ == "__main__":
    raise SystemExit(main())
