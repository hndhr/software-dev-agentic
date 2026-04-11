# CLAUDE.md

**software-dev-agentic** — Multi-platform Claude Code toolkit for Clean Architecture projects.
Consumed as a git submodule at `.claude/software-dev-agentic/` in downstream projects. No app to run — this repo is agents, skills, hooks, and architecture reference docs.

Platforms: **web** (Next.js 15) · **ios** (Swift/UIKit) · **flutter** (stub)

## Dev Commands

```bash
# Wire into a downstream project — interactive package selection (recommended)
.claude/software-dev-agentic/scripts/setup-packages.sh --platform=web
.claude/software-dev-agentic/scripts/setup-packages.sh --platform=ios

# Or link everything without prompts
.claude/software-dev-agentic/scripts/setup-symlinks.sh --platform=web

# Cut a release
/release
```

No build, lint, or test commands — all files are Markdown and Bash.

## Structure

```
core/
  agents/        # Platform-agnostic orchestrators and utility workers
  skills/        # Platform-agnostic skills (release, doctor, agentic-perf-review)
  reference/
    clean-arch/  # Universal CLEAN Architecture principles

platforms/
  web/           # Next.js 15 Clean Architecture
    agents/      # Web worker implementations (domain, data, presentation, test)
    skills/      # Web-specific skills
    reference/   # Web-specific architecture docs
    hooks/       # Web-specific Claude Code hooks
    packages/    # Optional package definitions
    CLAUDE-template.md
    settings-template.json
  ios/           # Swift/UIKit Clean Architecture
    agents/      # iOS worker + orchestrator implementations
    skills/      # iOS-specific skills
    reference/   # iOS-specific architecture docs
    CLAUDE-template.md
  flutter/       # BLoC Clean Architecture (stub — see platforms/flutter/README.md)

packages/        # Core package definitions (always installed)
scripts/         # setup-symlinks.sh, setup-packages.sh, sync.sh
docs/            # Internal design docs (not consumed by agents)
```

## Workflow

Before any work, invoke the **issue-worker** agent with a title (new) or number (existing).

```
issue-worker "add X"   → create GH issue + branch + backlog row
issue-worker 42        → pick up existing GH issue + branch + backlog row
```

Then work directly on the relevant files in `core/` or `platforms/<platform>/`.

## Agent Conventions

Every agent file must have this frontmatter:

```yaml
---
name: agent-name
description: one-line description used for routing
model: sonnet          # or opus for complex orchestration
tools: Read, Glob, Grep, ...
permissionMode: plan   # for read-only workers; omit for write workers
---
```

**Orchestrators** — coordinate workers, never write files directly. List sub-agents in `agents:` frontmatter.

**Workers** — domain specialists, execute skills, write files. End with an extension point:

```markdown
## Extension Point
After completing, check for `.claude/agents.local/extensions/<name>.md` — if it exists, read and follow its additional instructions.
```

## Skill Conventions

Every skill must have this frontmatter:

```yaml
---
name: skill-name
description: one-line description
user-invocable: false    # omit or set true if user can invoke directly
tools: Read, Write, Edit, Glob
---
```

Skills called only by workers: `user-invocable: false`.
User-facing skills (slash commands): no `user-invocable` field or `true`.

## Release

Use `/release` — it bumps `VERSION`, prepends `CHANGELOG.md`, commits, and tags.
Then push: `git push && git push --tags`.
