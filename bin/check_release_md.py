#!/usr/bin/env python3
from __future__ import annotations
import re
import sys
from pathlib import Path
from typing import List, Tuple

HDR_RE = re.compile(r"^##\s+v(\d+)\.(\d+)\.(\d+)\s+—\s+(\d{4}-\d{2}-\d{2})\s*$")

def semver_tuple(m: re.Match) -> Tuple[int,int,int]:
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)))

def die(msg: str) -> None:
    print(f"RELEASE.md CHECK FAILED: {msg}", file=sys.stderr)
    sys.exit(1)

def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "RELEASE.md")
    if not path.exists():
        die(f"{path} not found")

    text = path.read_text(encoding="utf-8", errors="ignore")

    # Must end with newline
    if not text.endswith("\n"):
        die("file must end with a newline")

    lines = text.splitlines()
    headers: List[Tuple[Tuple[int,int,int], str, int]] = []  # (ver, date, line_index)

    for i, line in enumerate(lines):
        m = HDR_RE.match(line)
        if m:
            headers.append((semver_tuple(m), m.group(4), i))

    if not headers:
        die("no release headers found. Expected lines like: ## v1.3.5 — 2025-12-23")

    # Headers must be unique and strictly increasing by semver; dates non-decreasing
    seen = set()
    last_ver = None
    last_date = None
    for ver, date, idx in headers:
        if ver in seen:
            die(f"duplicate version v{ver[0]}.{ver[1]}.{ver[2]} (line {idx+1})")
        seen.add(ver)

        if last_ver is not None and not (ver > last_ver):
            die(f"versions must be strictly increasing (line {idx+1})")
        if last_date is not None and date < last_date:
            die(f"dates must be non-decreasing (line {idx+1})")

        last_ver = ver
        last_date = date

    # Formatting rules inside each block:
    # - blank line after header
    # - no leading indentation before ### headings or list bullets
    for n, (_, _, idx) in enumerate(headers):
        start = idx
        end = headers[n+1][2] if n+1 < len(headers) else len(lines)
        block = lines[start:end]

        # blank line after header
        if len(block) < 2 or block[1].strip() != "":
            die(f"missing blank line after header at line {start+1}")

        # scan for bad indentation in headings and bullets
        for j, ln in enumerate(block[2:], start=start+3):
            if ln.startswith("### "):
                continue
            if ln.lstrip().startswith("### ") and not ln.startswith("### "):
                die(f"heading must not be indented (line {j})")
            if ln.lstrip().startswith("- ") and not ln.startswith("- "):
                die(f"bullet must not be indented (line {j})")

    # Also ensure there are no stray CR characters
    if any("\r" in l for l in lines):
        die("CRLF detected; please use LF endings")

    print("OK: RELEASE.md format + ordering checks passed.")

if __name__ == "__main__":
    main()
