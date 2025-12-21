import os
import subprocess
from pathlib import Path
import re

def test_qtday_status_format_contract(tmp_path):
    # Fake HOME
    home = tmp_path / "home"
    (home / ".config/qt").mkdir(parents=True)
    (home / "qt/bin").mkdir(parents=True)

    repo_root = Path(__file__).resolve().parents[1]
    qtday_src = repo_root / "qt/bin/qtday"
    qtday_dst = home / "qt/bin/qtday"
    qtday_dst.write_text(qtday_src.read_text(encoding="utf-8"), encoding="utf-8")
    qtday_dst.chmod(0o755)

    # Set stamp
    (home / ".config/qt/qtday.last").write_text("2099-01-01", encoding="utf-8")

    env = os.environ.copy()
    env["HOME"] = str(home)
    env["PATH"] = f"{home}/qt/bin:" + env.get("PATH", "")

    # Force all file paths into tmp
    env["QTDAY_SESS_FILE"] = str(tmp_path / "qtday.session")
    env["QTDAY_STAMP_FILE"] = str(home / ".config/qt/qtday.last")
    env["QTDAY_REPO_DIR"] = str(tmp_path / "repo")
    env["QTDAY_ENV_FILE"] = str(tmp_path / "env")
    env["QTDAY_TZ"] = "America/Toronto"

    p = subprocess.run(["qtday", "--status"], env=env, text=True, capture_output=True)
    assert p.returncode == 0, p.stderr

    out = p.stdout.splitlines()

    # Contract: stable keys must exist exactly once
    keys = [
        "today:",
        "qtday.last:",
        "session marker:",
        "qtday path:",
        "repo dir:",
        "env file:",
        "decision:",
    ]
    text = "\n".join(out)
    for k in keys:
        assert text.count(k) == 1, f"missing/duplicate key: {k}"

    # Contract: decision line begins with one of allowed prefixes
    decision_line = next(line for line in out if line.startswith("decision:"))
    assert re.search(r"(skip -|would run -)", decision_line), decision_line
