# Quantum Trek – Coding SOP
**Document Name:** `QT-Coding-SOP.md`  
**Version:** 1.0  
**Maintainer:** Quantum Trek CTO (Dave D’Silva)  
**Purpose:** Standard Operating Procedure for creating, maintaining, and executing the `qt-log-entry.sh` automation used to record timestamped log entries directly into the QT ▸ Log in Notion.

---

## 1. Scope
This SOP defines:
- Local file structure for Quantum Trek coding artifacts
- Installation and requirements
- Operational workflow to log entries into Notion
- Standard naming/timestamp conventions
- Repository and documentation structure

This SOP applies to all Quantum Trek projects using the logging automation:
1. QT SEC & Investor Filing
2. Master WBS & Systems Architecture

---

## 2. Local File Structure

Recommended folder layout (Linux / macOS):

```
~/projects/quantumtrek/
│
├── bin/
│   └── qt-log-entry.sh
│
├── docs/
│   └── QT-Coding-SOP.md
│   └── SEC-Filing-Notes.md
│   └── WBS-Master.md
│
├── env/
│   └── notion.env
│
└── repo/  (GitHub working directory)
```

**Paths referenced in this SOP:**
- Script: `~/projects/quantumtrek/bin/qt-log-entry.sh`
- SOP: `~/projects/quantumtrek/docs/QT-Coding-SOP.md`
- Environment file: `~/projects/quantumtrek/env/notion.env`

---

## 3. Environment Variables

The script requires two environment variables:

```
export NOTION_TOKEN="secret_XXXXX"
export NOTION_LOG_PAGE_ID="UUID"
```

Recommended storage: Create `~/projects/quantumtrek/env/notion.env`:

```
NOTION_TOKEN=secret_XXXXX
NOTION_LOG_PAGE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Load it from your shell profile:

```
source ~/projects/quantumtrek/env/notion.env
```

---

## 4. Log Format Standard

All log entries follow:
- **Date toggle:** `YYYY-MM-DD`  
- **Entry timestamp:** `YYYY-MM-DD HHMM — Description text`

Example:
```
2025-12-06
  └─ 2025-12-06 1432 — Submitted draft SEC filing outline
```

**Time standard:**  
- UTC: NOT used  
- Local timezone: **ET**  
- Format: **24-hour, 4-digit minute**  

This matches the Frontier Enterprise Standard used across Quantum Trek.

---

## 5. Execution Workflow

### 5.1 Create or Update the Script
Open the script:

```bash
nano ~/projects/quantumtrek/bin/qt-log-entry.sh
```

Paste the complete script from the SOP appendix (Section 9).

Save and exit:

```
Ctrl + O → Enter
Ctrl + X
```

Make executable:

```bash
chmod +x ~/projects/quantumtrek/bin/qt-log-entry.sh
```

---

### 5.2 Run a Log Entry

**Inline usage:**

```bash
~/projects/quantumtrek/bin/qt-log-entry.sh "Updated WBS structure"
```

OR interactive prompt:

```bash
~/projects/quantumtrek/bin/qt-log-entry.sh
# then type the log text when prompted
```

---

## 6. GitHub Version Control

### 6.1 Initial Commit

Navigate to repo:

```bash
cd ~/projects/quantumtrek/repo/
```

Copy SOP into repo docs:

```bash
cp ~/projects/quantumtrek/docs/QT-Coding-SOP.md ./docs/
```

Stage & commit:

```bash
git add docs/QT-Coding-SOP.md
git commit -m "Add Quantum Trek coding SOP for qt-log-entry"
git push origin main
```

---

### 6.2 Update Workflow

When modifying the script:
1. Update the script in `bin/`
2. Update revision notes at the bottom of this SOP
3. Commit both with a message:

```
git commit -am "Improve qt-log-entry.sh timestamp validation"
git push
```

---

## 7. Document Control

**Version numbering:**
- Increment **minor version** for script updates
- Increment **major version** when SOP structure changes

**Changelog format:**
```
## 1.1 – 2025-01-17
- Added error handling for missing env
```

---

## 8. Notion Integration

The script uses the Notion Blocks API:
- URL: `https://api.notion.com/v1`
- Version: `2022-06-28`

Parent block for QT log is referenced using:
- `NOTION_LOG_PAGE_ID`

Nested toggle creation logic:
- If date toggle exists → append child
- If not → create toggle, then child

---

## 9. Appendix – Full Script

*(Paste your final, current version here. It will be maintained and updated under this section.)*

---


## I Revision History

```
Version 1.0 – 2025-12-06
- Initial SOP created
```
