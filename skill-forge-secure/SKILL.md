---
name: skill-forge-secure
description: Create new AgentSkills from Pope's requirements or from a provided GitHub open-source project, following Claude/AgentSkills conventions. Generates SKILL.md + supporting scripts/references, and performs a mandatory security review (no secrets, no destructive commands, least-privilege tools, explicit confirmation for external side effects) before packaging.
---

# Skill Forge (Secure)

## What this skill does

Turn a request like:
- “给我做一个 skill：能用这个 GitHub 项目自动生成 XXX”
- “把我这套 iOS Simulator 调试流程做成 skill”

into a **new skill folder** with:
- `SKILL.md` (frontmatter + minimal but complete workflow)
- optional `scripts/` (deterministic utilities)
- optional `references/` (docs, checklists, examples)

Then run a **security review** and only after passing, package the skill.

> This skill is **manual-invocation only** (`disable-model-invocation: true`) because it can write files and run packaging scripts.

---

## Inputs (what to ask the user)

Collect:
1. **Goal**: what the skill should do (one sentence)
2. **Triggers**: example user prompts that should activate it
3. **Scope**: what it must do / must not do
4. **Target repo (optional)**: GitHub URL or local path
5. **Side effects**: is it allowed to send messages/emails, post to GitHub, deploy, etc.

---

## Output location & naming

- Skill folder name: lowercase, digits, hyphens, ≤64 chars.
- Create under: `/Users/pope/.openclaw/workspace/skills/<skill-name>/`
- Only create new skills or modify files inside that new skill folder.

---

## Workflow

### Step 1 — Plan the skill (small)

Write a short plan:
- Name + description (triggering keywords)
- Required tools (least privilege)
- Primary workflow steps
- Supporting files needed

Prefer: **SKILL.md ≤ 500 lines**, push big docs to `references/`.

### Step 2 — Initialize the skill directory

Use OpenClaw’s skill-creator scripts:

```bash
python3 /Users/pope/.nvm/versions/node/v24.7.0/lib/node_modules/openclaw/skills/skill-creator/scripts/init_skill.py <skill-name> \
  --path /Users/pope/.openclaw/workspace/skills \
  --resources scripts,references
```

### Step 3 — Implement

- Write `SKILL.md` with:
  - clear **when to use** in `description`
  - explicit constraints (no secrets, no destructive ops)
  - command snippets (parameterized)
  - references to supporting files

- Add scripts if they prevent repeated manual work.

### Step 4 — Mandatory security review (blocker)

Run **all** checks in `references/security-review.md`.

Additionally, run the automated scanner:

```bash
bash scripts/security_scan.sh /path/to/skill-folder
```

If any check fails → do not package; fix first.

### Step 5 — Validate & package

```bash
python3 /Users/pope/.nvm/versions/node/v24.7.0/lib/node_modules/openclaw/skills/skill-creator/scripts/quick_validate.py <skill-folder>
python3 /Users/pope/.nvm/versions/node/v24.7.0/lib/node_modules/openclaw/skills/skill-creator/scripts/package_skill.py <skill-folder> /Users/pope/.openclaw/workspace/
```

---

## Notes on Claude Skills vs OpenClaw Skills

Claude Code skills (per https://code.claude.com/docs/en/skills):
- `SKILL.md` with YAML frontmatter
- optional `disable-model-invocation`, `allowed-tools`, `context: fork`

OpenClaw loads the same style of `SKILL.md` in its own skills system.
When writing skills, copy the *spirit*:
- least privilege
- explicit invocation control
- supporting files
- scripts over repeated ad-hoc commands

---

## Supporting docs

- Security checklist: `references/security-review.md`
- Output patterns: `references/templates.md`
- Auto scanner: `scripts/security_scan.sh`
