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

def notion_text_snippets_from_blocks(results):
    """
    Return text snippets visible on the QT Big Picture page as blocks.
    Big Picture often contains links inside paragraphs/callouts/lists, not just headings/toggles.
    We scan *all* common rich_text-bearing blocks plus child_page titles.
    """
    snippets = []
    for b in results or []:
        t = b.get("type")
        rt = None

        # Rich-text bearing block types
        if t in ("heading_1", "heading_2", "heading_3"):
            rt = b.get(t, {}).get("rich_text", [])
        elif t in ("paragraph", "bulleted_list_item", "numbered_list_item", "to_do", "toggle", "quote", "callout"):
            rt = b.get(t, {}).get("rich_text", [])
        elif t == "child_page":
            title = (b.get("child_page", {}) or {}).get("title", "").strip()
            if title:
                snippets.append(title)
            continue
        else:
            # ignore other block types for now
            continue

        txt = "".join([x.get("plain_text","") for x in (rt or [])]).strip()
        if txt:
            snippets.append(txt)

    return snippets
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
        "QT - WBS Crosswalk",
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
        payload_blocks = notion_walk_block_tree(big_picture_id, api_key, max_depth=4)
        snippets = notion_text_snippets_from_blocks(payload_blocks)
    except Exception as e:
        warn(f"Notion drift: FAIL to read Big Picture children ({e})")
        return False

    notion_ok = True
    def has_expected(label: str) -> bool:
        def norm(x: str) -> str:
            if x is None:
                return ""
            # normalize common unicode dashes to ASCII hyphen
            x = (x.replace("–","-").replace("—","-").replace("-","-").replace("−","-"))
            # drop common bullet prefixes / emoji markers without being too aggressive
            x = re.sub(r"^[\s\-•\*]+", "", x)
            # collapse whitespace
            x = " ".join(x.split())
            return x.lower()

        needle = norm(label)
        for s in snippets:
            if needle and needle in norm(s or ""):
                return True
        return False
    for t in expected_notion:
        if not has_expected(t):
            notion_ok = False
            warn(f"Notion drift: missing expected item '{t}' under QT Big Picture page (not found in visible block text)")
    if gh_ok and notion_ok:
        ok("Notion<->GitHub drift: PASS (expected top-level items present)")
        return True

    warn("Notion<->GitHub drift: needs attention (missing items detected)")
    return False

def notion_walk_block_tree(root_block_id: str, api_key: str, max_depth: int = 4):
    """
    BFS crawl of Notion block tree starting at root_block_id, returning a flat list of blocks.
    Includes nested blocks (toggles, callouts, synced sections, etc.) up to max_depth.
    """
    all_blocks = []
    seen = set([root_block_id])
    q = [(root_block_id, 0)]
    while q:
        bid, depth = q.pop(0)
        if depth > max_depth:
            continue
        payload = notion_get_children(bid, api_key)
        blocks = payload.get("results", []) or []
        all_blocks.extend(blocks)
        for b in blocks:
            if b.get("has_children") and b.get("id") and b["id"] not in seen:
                seen.add(b["id"])
                q.append((b["id"], depth + 1))
    return all_blocks

def verify_expected_page_ids():
    required = {
        "QT_CANON_PAGE_ID",
        "QT_LOG_PAGE_ID",
        "QT_TODO_PAGE_ID",
        "QT_WBS_CROSSWALK_PAGE_ID",
        "QT_DUE_DILIGENCE_PAGE_ID",
        "QT_INVESTORS_PAGE_ID",
    }
    missing = [k for k in required if not os.getenv(k,"").strip()]
    if missing:
        for k in missing:
            warn(f"Notion drift: missing env {k}")
        return False
    ok("Notion page-id mapping: PASS")
    return True



def verify_big_picture_hub_links(big_picture_id: str, api_key: str) -> bool:
    """
    STRICT: Validate ONLY the newest navigation hub section in QT - Big Picture.

    We locate the LAST occurrence of the marker text:
        "New Navigation Block"
    and only scan blocks from that point onward.

    Links may be either:
      - link_to_page blocks, OR
      - inline rich_text href links (your format)

    If the marker is missing OR there are no links after it -> FAIL.
    """
    required = {
        "QT_CANON_PAGE_ID": os.getenv("QT_CANON_PAGE_ID", "").strip(),
        "QT_LOG_PAGE_ID": os.getenv("QT_LOG_PAGE_ID", "").strip(),
        "QT_TODO_PAGE_ID": os.getenv("QT_TODO_PAGE_ID", "").strip(),
        "QT_WBS_CROSSWALK_PAGE_ID": os.getenv("QT_WBS_CROSSWALK_PAGE_ID", "").strip(),
        "QT_DUE_DILIGENCE_PAGE_ID": os.getenv("QT_DUE_DILIGENCE_PAGE_ID", "").strip(),
        "QT_INVESTORS_PAGE_ID": os.getenv("QT_INVESTORS_PAGE_ID", "").strip(),
    }
    missing_env = [k for k, v in required.items() if not v]
    if missing_env:
        for k in missing_env:
            warn(f"Notion hub link verify: missing env {k}")
        return False

    def uuid32_from_any(x: str) -> str:
        hx = re.sub(r"[^0-9a-fA-F]", "", x or "").lower()
        if len(hx) != 32:
            return ""
        return f"{hx[0:8]}-{hx[8:12]}-{hx[12:16]}-{hx[16:20]}-{hx[20:32]}"

    def block_any_text(b) -> str:
        pts = []
        def walk(x):
            if isinstance(x, dict):
                pt = x.get("plain_text")
                if isinstance(pt, str):
                    pts.append(pt)
                for v in x.values():
                    walk(v)
            elif isinstance(x, list):
                for v in x:
                    walk(v)
        walk(b)
        return " ".join(pts).strip()

    def collect_link_targets(block_list):
        linked = set()
        rich_types = {
            "paragraph","heading_1","heading_2","heading_3",
            "bulleted_list_item","numbered_list_item","to_do",
            "toggle","quote","callout"
        }

        # link_to_page targets
        for b in block_list:
            if b.get("type") == "link_to_page":
                lp = b.get("link_to_page", {}) or {}
                pid = uuid32_from_any(lp.get("page_id") or "")
                if pid:
                    linked.add(pid)

        # inline href targets inside rich_text
        for b in block_list:
            t = b.get("type")
            if t in rich_types:
                rt = (b.get(t, {}) or {}).get("rich_text", []) or []
                for r in rt:
                    href = (r or {}).get("href") or ""
                    pid = uuid32_from_any(href)
                    if pid:
                        linked.add(pid)

        return linked

    blocks = notion_walk_block_tree(big_picture_id, api_key, max_depth=8)

    # STRICT marker slicing: last "New Navigation Block"
    marker = "new navigation block"
    marker_idx = None
    for i, b in enumerate(blocks):
        if marker in (block_any_text(b) or "").lower():
            marker_idx = i

    if marker_idx is None:
        warn("Notion hub links: FAIL (marker 'New Navigation Block' not found).")
        return False

    blocks = blocks[marker_idx:]
    linked_page_ids = collect_link_targets(blocks)

    if not linked_page_ids:
        warn("Notion hub links: FAIL (no links detected after 'New Navigation Block' marker).")
        return False

    ok_all = True
    for k, expected_pid in required.items():
        expected_pid = uuid32_from_any(expected_pid)
        if expected_pid not in linked_page_ids:
            ok_all = False
            warn(f"Notion hub link drift: missing hub link for {k} (expected page_id={expected_pid})")

    if ok_all:
        ok("Notion hub links: PASS (STRICT bottom-only; targets match env IDs)")
        return True

    warn("Notion hub links: FAIL (see missing hub link warnings above)")
    return False


def main():
    fix = "--fix" in sys.argv
    # repo sanity
    if not (REPO / ".git").exists():
        die("not a git repo (run from repo root)")

    ok(f"verify start: {now_ts()} (fix={fix})")

    pass1 = verify_data_room(fix)
    pass2 = ensure_root_readme_pointer(fix)
    pass3 = verify_notion_github_drift() and verify_expected_page_ids() and verify_big_picture_hub_links(os.getenv('QT_BIG_PICTURE_PAGE_ID','').strip(), os.getenv('NOTION_API_KEY','').strip())

    if pass1 and pass2 and pass3:
        ok("ALL CHECKS PASSED")
        return 0
    warn("CHECKS FAILED (see WARN/FAIL above)")
    return 2

if __name__ == "__main__":
    raise SystemExit(main())



