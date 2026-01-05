# Security Notes (qtlog)

This repository is intentionally “GitHub-safe”:
- No secrets are required to read/understand the SOPs and architecture.
- Secrets must never be committed.

## Secrets policy
Store credentials locally (example):
- `~/.config/qt/.env` (recommend: `chmod 600 ~/.config/qt/.env`)
Never commit:
- API keys/tokens
- Notion page IDs if they are private
- any `.env` files

## Relevant docs
- Architecture rationale: `ARCHITECTURE.md`
- Notion ordering SOP: `docs/SOP_NOTION_LOG_ORDERING.md`
- Audit/change history: `CHANGELOG.md`

## Operational rule
If a failure happens:
- capture response once (HTTP + body)
- stop and fix root cause (avoid retry loops that spam Notion)
