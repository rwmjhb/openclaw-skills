#!/usr/bin/env bash
# bootstrap_fastlane.sh
# Generate a safe fastlane skeleton (Gemfile + fastlane/*) with placeholders.
# Supports --dry-run and NEVER writes secrets.
#
# Usage:
#   bootstrap_fastlane.sh --project /path/to/ios/project --dry-run
#   bootstrap_fastlane.sh --project /path/to/ios/project --apply

set -euo pipefail

PROJECT=""
MODE="dry"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2;;
    --apply) MODE="apply"; shift;;
    --dry-run) MODE="dry"; shift;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

if [[ -z "$PROJECT" ]]; then
  echo "Usage: $0 --project <path> [--dry-run|--apply]" >&2
  exit 2
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "ERROR: project path not found: $PROJECT" >&2
  exit 2
fi

say() { printf "%s\n" "$*"; }
write_file() {
  local path="$1"; shift
  local content="$1"
  if [[ "$MODE" == "dry" ]]; then
    say "[dry-run] would write: $path"
    return
  fi
  mkdir -p "$(dirname "$path")"
  printf "%s" "$content" > "$path"
  say "[apply] wrote: $path"
}

say "Mode: $MODE"

# 1) Gemfile
GEMFILE_CONTENT=$'source "https://rubygems.org"\n\ngem "fastlane"\n'
write_file "$PROJECT/Gemfile" "$GEMFILE_CONTENT"

# 2) fastlane/Appfile
APPFILE_CONTENT=$'# Appfile (fill these in)\napp_identifier("com.example.app")\napple_id("you@example.com")\nteam_id("TEAMID")\n\n# Preferred auth: App Store Connect API key\n# Provide via CI secrets / local secure storage\n'
write_file "$PROJECT/fastlane/Appfile" "$APPFILE_CONTENT"

# 3) fastlane/Fastfile
FASTFILE_CONTENT=$'default_platform(:ios)\n\nplatform :ios do\n  desc "Preflight checks"\n  lane :verify do\n    ensure_git_status_clean\n    # scan(...)\n  end\n\n  desc "Build IPA"\n  lane :build do\n    match(type: "appstore")\n    build_app(\n      workspace: "YourApp.xcworkspace",\n      scheme: "YourApp",\n      configuration: "Release",\n      export_method: "app-store"\n    )\n  end\n\n  desc "Upload to TestFlight (CONFIRM before running)"\n  lane :beta do\n    verify\n    build\n    upload_to_testflight(skip_submission: true)\n  end\n\n  desc "Upload to App Store (CONFIRM before running)"\n  lane :release do\n    verify\n    build\n    deliver(force: true, submit_for_review: false)\n  end\nend\n'
write_file "$PROJECT/fastlane/Fastfile" "$FASTFILE_CONTENT"

say "Done. Next:" 
say "- bundle update && bundle exec fastlane verify"
say "- configure match storage (match init)"
