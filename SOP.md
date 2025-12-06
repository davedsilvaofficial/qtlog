# qtlog.sh Upgrade SOP

**Version:** v1.2.x  
**Last Updated:** 2025-12-06  
**Owner:** Dave D’Silva  
**Environment:** Android (Termux) → GitHub

---

## PURPOSE

This Standard Operating Procedure (SOP) ensures every upgrade of `qtlog.sh` is:

- Predictable  
- Reversible  
- Testable  
- Safely synced to GitHub  
- Documented with consistent timestamps

No code is upgraded without:

1. Preview Phase  
2. Execute Phase  
3. Archive of previous version  
4. Verified test entry  

---

## PREVIEW → EXECUTE DISCIPLINE

**Preview Phase**

- Show the plan only  
- No commands executed  
- Dave responds using:  
  - **A** = Approve & Execute  
  - **B** = Modify Preview  
  - **C** = Abort  
  - **D** = Approve + include Operator Cheatsheet  

**Execute Phase**

- Real commands only  
- One clean copy block per phase  
- No numbering inside command lines  
- No commentary injected into commands  
- No combining steps into long chains  

---

## DIRECTORY STRUCTURE

```text
$HOME
 └─ qtlog_repo/
     ├─ qtlog.sh
     ├─ Log/
     │   └─ YYYY-MM-DD.log
     ├─ SOP.md
     └─ qtlog_archives/
         └─ qtlog_YYYY-MM-DD_HHMM.sh
