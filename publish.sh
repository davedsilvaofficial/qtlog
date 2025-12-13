#!/usr/bin/env bash
set -e

echo "🚫 Publish Guard active"
echo "This repository requires screened / redacted export."
echo "Direct public publish is blocked by policy."
exit 1
