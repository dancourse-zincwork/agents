#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
f="$REPO_ROOT/studio-operations/n8n-workflow-consultant.md"
test -f "$f" || { echo "FAIL: subagent doc missing at $f"; exit 1; }
grep -q "n8n-consultant" "$f" || { echo "FAIL: subagent doesn't mention plugin at $f"; exit 1; }
echo "OK"
