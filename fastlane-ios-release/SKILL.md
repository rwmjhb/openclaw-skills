---
name: fastlane-ios-release
description: "Automate the full iOS App pre-release pipeline with fastlane for Pope's projects: code signing (match), build/archive (build_app/gym), TestFlight upload (pilot), App Store metadata/screenshots upload & optional submission (deliver), plus preflight checks (tests, lint, versioning, changelog). Use when setting up or running a repeatable iOS release workflow."
---

# fastlane iOS Release Pipeline (Secure)

This skill helps you set up and run a **repeatable iOS release workflow** using fastlane.

## Safety & rules (must follow)

- **No secrets in git**: never commit `.p8`, passwords, tokens, `MATCH_PASSWORD`, or API key JSON.
- **No destructive ops by default**: avoid `match nuke`, deleting profiles, or revoking certs unless explicitly requested.
- **External side effects must be confirmed** before executing:
  - uploading to TestFlight/App Store
  - submitting for review
  - pushing tags/commits

## What fastlane can automate (high level)

From fastlane docs:
- Install/setup via Bundler + `fastlane init`
- **Codesigning** with `match` (shared certs/profiles stored encrypted in your repo/storage)
- **Build** with `build_app` (gym) to produce `.ipa` and dSYMs
- **TestFlight** upload/distribution with `pilot` / `upload_to_testflight`
- **App Store** upload of metadata/screenshots/binary with `deliver` / `upload_to_app_store` (optionally `submit_for_review`)

## Inputs to collect (one-time)

You (Pope) should provide:
1. iOS project path (Xcode workspace/project)
2. Scheme name(s) + configuration (Release)
3. Bundle ID(s) (main app + extensions, if any)
4. Team ID
5. Signing strategy:
   - match git repo URL (private) OR S3/GCS
   - match type(s): `appstore`, `development`, `adhoc` (optional)
6. App Store Connect auth method (preferred):
   - **API Key** (issuer_id, key_id, .p8 path) OR Apple ID (2FA)
7. Release policy:
   - TestFlight only vs App Store submission
   - phased release, automatic release
   - metadata/screenshots management

## Recommended structure in Fastfile

Create lanes that separate **verification** from **upload**:

- `lane :verify` (no side effects)
  - run tests (e.g. `scan`)
  - ensure clean git state
  - ensure version/build numbers
  - optional: `deliver` precheck only

- `lane :build` (local build only)
  - `match(type: "appstore")` (or `sync_code_signing`)
  - `build_app(...)` (`export_method: "app-store"`)

- `lane :beta` (TestFlight)
  - `verify`
  - `build`
  - `upload_to_testflight` (pilot)

- `lane :release` (App Store)
  - `verify`
  - `build`
  - `deliver(...)` (upload metadata/screenshots/binary)
  - optional: `submit_for_review: true` only if confirmed

## Implementation guide (setup)

### 1) Install via Bundler (recommended)

From fastlane docs (preferred approach):

```bash
# in repo root
cat > Gemfile <<'EOF'
source "https://rubygems.org"

gem "fastlane"
EOF
bundle update
```

Run fastlane via:
```bash
bundle exec fastlane <lane>
```

### 2) Initialize

```bash
bundle exec fastlane init
```

This generates `fastlane/Fastfile`, `Appfile`, etc.

### 3) Configure code signing with match

Docs: https://docs.fastlane.tools/actions/match/

```bash
bundle exec fastlane match init
bundle exec fastlane match appstore
```

Set match passphrase via env var (do NOT commit; set in your shell/CI secrets):

```bash
export MATCH_PASSWORD="<your-passphrase>"  # do not commit
```

### 4) Build (gym/build_app)

Docs: https://docs.fastlane.tools/actions/build_app/

Example:
```ruby
build_app(
  workspace: "YourApp.xcworkspace",
  scheme: "YourApp",
  configuration: "Release",
  export_method: "app-store"
)
```

### 5) Upload to TestFlight (pilot)

Docs: https://docs.fastlane.tools/actions/pilot/

Prefer App Store Connect API Key auth.

### 6) Upload to App Store (deliver)

Docs: https://docs.fastlane.tools/actions/deliver/

Use `deliver init` to pull metadata templates.

## Supporting files

- `references/fastfile-template.md`: opinionated Fastfile skeleton with safe lanes
- `references/env-vars.md`: required environment variables (no secrets in repo)
- `references/security-review.md`: mandatory review for release automation
- `scripts/bootstrap_fastlane.sh`: generate fastlane files with placeholders (supports --dry-run)
- `scripts/security_scan.sh`: scan the skill itself for secrets/dangerous commands

## Mandatory security review

Before packaging or using this workflow for real releases, run:

1) Read & satisfy: `references/security-review.md`
2) Scan: `bash scripts/security_scan.sh .`

