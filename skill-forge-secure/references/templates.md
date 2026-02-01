# Templates & Output Patterns

## SKILL.md frontmatter template

```yaml
---
name: <skill-name>
description: <what it does + when to use>
disable-model-invocation: true  # recommended for side-effect workflows
# allowed-tools: Read, Grep  # optional, least-privilege
# context: fork              # optional (Claude Code)
---
```

## Minimal SKILL.md body pattern

- One-paragraph intent
- Inputs required
- Step-by-step workflow
- Safety notes (what not to do)
- References section

## Script pattern

- Support `--help`
- Support `--dry-run`
- Avoid printing secrets
- Exit non-zero on failure
