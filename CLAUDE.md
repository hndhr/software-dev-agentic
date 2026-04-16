# CLAUDE.md

**software-dev-agentic** — Multi-platform Claude Code toolkit for Clean Architecture projects.
Consumed as a git submodule at `.claude/software-dev-agentic/` in downstream projects. No app to run — this repo is agents, skills, hooks, and architecture reference docs.

Platforms: **web** (Next.js 15) · **ios** (Swift/UIKit) · **flutter** (Dart/BLoC)

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
lib/                          # Everything shipped to downstream projects
  core/
    agents/
      builder/     # Feature builders — orchestrators + layer workers + test-worker
      detective/   # Debug orchestrator + debug worker
      tracker/     # Issue lifecycle management
      auditor/     # Architecture review (future: security-review, perf-audit)
      installer/   # Project setup + onboarding (setup-worker)
      perf-worker.md  # Session performance analysis (ungrouped — meta/observability)
    skills/        # Platform-agnostic skills (release, doctor, agentic-perf-review)
    reference/
      clean-arch/  # Universal CLEAN Architecture principles
  platforms/
    web/           # Next.js 15 Clean Architecture
      agents/      # Platform-specific workers only (empty = core workers suffice)
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
    flutter/       # BLoC Clean Architecture (see lib/platforms/flutter/README.md)

agents/          # Internal tooling — NOT shipped downstream
skills/          # Internal tooling — NOT shipped downstream
packages/        # Core package definitions (consumed by setup scripts)
scripts/         # setup-symlinks.sh, setup-packages.sh, sync.sh
docs/            # Internal design docs
evaluation/      # Serialized observations and investigations
```

## Workflow

Before any work, invoke the **issue-worker** agent with a title (new) or number (existing).

```
issue-worker "add X"   → create GH issue + branch + backlog row
issue-worker 42        → pick up existing GH issue + branch + backlog row
```

Then work directly on the relevant files in `lib/core/` or `lib/platforms/<platform>/`.

## Agent Architecture

See `docs/agent-architecture.md` — read it before adding any agent, worker, or skill.

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
