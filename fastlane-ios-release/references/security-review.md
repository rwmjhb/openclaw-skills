# Security Review (MANDATORY) – fastlane-ios-release

Pass this before using the lanes for real releases.

## 1) Secrets
- [ ] `.p8` API key file is stored outside git (or gitignored) and provided via CI secret mount.
- [ ] No Apple ID password committed.
- [ ] `MATCH_PASSWORD` stored in env/secret store, not in repo.

## 2) Code signing risk
- [ ] Do NOT run `match nuke` unless explicitly requested.
- [ ] Ensure match storage repo is private and encrypted.

## 3) Side effects gating
- [ ] `beta` lane uploads to TestFlight only after explicit confirmation.
- [ ] `release` lane uploads to App Store only after explicit confirmation.
- [ ] `submit_for_review` is false by default unless explicitly enabled for that run.

## 4) Reproducibility
- [ ] Use Bundler (`Gemfile` + `Gemfile.lock`) to pin fastlane.
- [ ] Prefer API key auth to avoid 2FA prompts.

## 5) Verification coverage
- [ ] `verify` lane runs test suite and checks git clean state.
- [ ] Build is produced via `build_app` with explicit scheme/workspace.
