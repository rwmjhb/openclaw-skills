# Security Review (MANDATORY)

This review must pass before packaging or publishing a skill.

## 0. Scope & permissions

- [ ] Skill does not require secrets (API keys, tokens) embedded in files.
- [ ] Skill does not instruct exfiltration of private data.
- [ ] External side effects (GitHub push, send messages, email, deploy) are **explicitly gated** with user confirmation.

## 1. Least privilege tools

- [ ] Skill instructions prefer read-only tools when possible.
- [ ] If file edits are needed, scope to specific paths.
- [ ] Avoid broad `exec` examples like `rm -rf`, `curl | sh`, `sudo`.

## 2. Dangerous commands

Reject or rewrite if present:
- `rm -rf`, destructive deletes without confirmation.
- `sudo`, system-wide installs without confirmation.
- piping remote code into shell: `curl ... | bash`.

## 3. Secrets & credentials

- [ ] No tokens/keys in SKILL.md, scripts, examples.
- [ ] If environment variables are required, document **where to set** them.
- [ ] If logs may contain secrets, instruct redaction.

## 4. Data handling

- [ ] Avoid printing full tokens; print prefix only.
- [ ] Any extracted tokens are used locally only and not written to git.

## 5. Reproducibility

- [ ] Paths are parameterized (don’t hardcode personal paths unless truly required).
- [ ] Provide a “dry run” mode for scripts when possible.

## 6. Compliance with user rules

- [ ] Do not modify user’s project source code unless explicitly allowed.
- [ ] Use separate test scripts where required.

## 7. Final sign-off

- [ ] Automated scan passes: `scripts/security_scan.sh <skill-folder>`
- [ ] Human review: read SKILL.md end-to-end for side effects and leakage.
