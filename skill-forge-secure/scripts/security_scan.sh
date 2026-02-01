#!/usr/bin/env bash
# Lightweight security scanner for skills
# Usage: security_scan.sh /path/to/skill-folder

set -euo pipefail

DIR="${1:?Usage: security_scan.sh <skill-folder>}"

if [ ! -d "$DIR" ]; then
  echo "ERROR: not a directory: $DIR" >&2
  exit 2
fi

fail=0

say() { printf "%s\n" "$*"; }

say "Scanning: $DIR"

# NOTE: this scan is heuristic. We exclude reference docs because they may
# mention dangerous patterns in a checklist context.
EXCLUDES=(
  --glob '!**/.git/**'
  --glob '!**/references/**'
  --glob '!**/scripts/security_scan.sh'
)

# 1) Secrets patterns (actual tokens/keys)
say "\n[1/4] Secrets scan"
if rg -n --hidden --no-ignore "${EXCLUDES[@]}" \
  '(gho_[A-Za-z0-9_]{10,}|ghp_[A-Za-z0-9_]{10,}|github_pat_[A-Za-z0-9_]{10,}|AIza[0-9A-Za-z\-_]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH) PRIVATE KEY|-----BEGIN)' \
  "$DIR"; then
  say "❌ Potential secret material detected. Remove/redact."; fail=1
else
  say "✅ No obvious secrets patterns found"
fi

# 2) Dangerous commands (real executable snippets)
say "\n[2/4] Dangerous commands"
if rg -n --hidden --no-ignore "${EXCLUDES[@]}" \
  '(rm\s+-rf\b|\bsudo\b|curl\s+[^\n]*\|\s*(sh|bash)\b|wget\s+[^\n]*\|\s*(sh|bash)\b)' \
  "$DIR"; then
  say "❌ Dangerous command patterns found. Gate with confirmation or remove."; fail=1
else
  say "✅ No obvious dangerous command patterns"
fi

# 3) External side effects hints
say "\n[3/4] External side effects hints"
if rg -n --hidden --no-ignore --glob '!**/.git/**' \
  '(gh\s+repo\s+create|git\s+push|message\s+send|send email|deploy|production)' \
  "$DIR"; then
  say "⚠️  Side-effect hints found: ensure SKILL.md requires explicit user confirmation.";
else
  say "✅ No side-effect hints (or minimal)"
fi

# 4) Path hardcodes (heuristic)
say "\n[4/4] Hardcoded user paths"
if rg -n --hidden --no-ignore --glob '!**/.git/**' \
  '(/Users/[^/]+/)' \
  "$DIR"; then
  say "⚠️  Hardcoded /Users/<name>/ paths found: consider parameterizing.";
else
  say "✅ No hardcoded /Users/<name>/ paths"
fi

if [ "$fail" -ne 0 ]; then
  say "\nFAILED"; exit 1
fi

say "\nPASSED"
