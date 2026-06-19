# CLAUDE.md

**CipherPol** — Multi-platform Claude Code toolkit for Clean Architecture projects.
Distributed as Claude Code plugins via the marketplace. No app to run — this repo is agents, skills, hooks, and architecture reference docs.

Platforms: **web** (Next.js 15) · **ios** (Swift/UIKit) · **flutter** (Dart/BLoC)

## Dev Commands

```bash
# Build a Claude Code plugin for a platform
software-dev-agentic/scripts/build-plugin.sh --platform=flutter-mobile-talenta
software-dev-agentic/scripts/build-plugin.sh --platform=all

# Install a plugin into a downstream project
software-dev-agentic/scripts/install-plugin.sh --platform=flutter-mobile-talenta

# Test a built plugin locally
claude --plugin-dir software-dev-agentic/dist/plugins/cipherpol-aegis

# Cut a release
/release
```

No build, lint, or test commands — all files are Markdown and Bash.

## Structure

`cipherpol-aegis/` — agentic personas and skills · `cipherpol-8-kms/` — KMS knowledge server · `.claude/` — internal tooling (agents, skills, reference) · `docs/` — design docs, observations, perf reports · `scripts/` — setup and sync scripts

See `docs/principles/agentic/agentic-design-principles.md` and `docs/principles/repo-structure.md` for the full structure and decision rules.

## Workflow

Before any work, invoke the **developer-issue-worker** agent with a title (new) or number (existing).

```
developer-issue "add X"   → create GH issue + branch + backlog row
developer-issue 42        → pick up existing GH issue + branch + backlog row
```

Then work directly on the relevant files in `cipherpol-aegis/lib/`.

## Agent Architecture

See `docs/principles/agentic/agentic-design-principles.md` and `docs/principles/agentic/agentic-conventions.md` — read them before adding any agent, worker, or skill.

@docs/principles/glossary.md

## Conventions

**Agents** — `name`, `description`, `model`, `tools` required in frontmatter. Orchestrators list sub-agents in `agents:` and never write files directly.

**Skills** — `name`, `description`, `user-invocable: false` required. Single task only, under 30 lines. User-facing skills omit `user-invocable` or set it to `true`.

## Release

Use `/release` — it bumps `VERSION`, prepends `CHANGELOG.md`, commits, and tags.
Then push: `git push && git push --tags`.
