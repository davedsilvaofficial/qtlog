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

```
---

### Android / Termux Credential Capture SOP

When adding or rotating credentials (GitHub tokens, API keys, secrets) on Android using Termux, the order of operations is mandatory:

1. Copy the token from the source UI  
   (GitHub “Generate token” page, cloud console, etc.)

2. Use Android’s Copy action  
   Ensure the token is explicitly copied to the system clipboard.

3. Return to Termux and press Enter (keyboard Return key)  
   This commits clipboard state to the Termux session.

4. Only then run:
   export GH_TOKEN="$(termux-clipboard-get | tr -d '\r\n')"

5. Immediately validate:
   curl -sS -H "Authorization: Bearer \$GH_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/user | jq -r '.login // .message'

⚠️ Skipping step 3 can result in valid-looking tokens that fail authentication (“Bad credentials”).

---


---

### SOP References

- **Android / Termux Credential Capture SOP**
  - Canonical reference tag: `sop-fix-directory-structure-v1`
  - Use this tag when auditing, releasing, or rotating credentials on Android

---

