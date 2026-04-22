> Author: Puras Handharmahua · 2026-04-22
> Related: Shared Agentic Submodule Architecture — Cross-Platform Scaling

## Context

Claude Code introduced a native plugin system as an alternative distribution mechanism for agents, skills, hooks, and MCP servers. This document evaluates whether plugins can replace or supplement the current submodule+script approach used by `software-dev-agentic`.

References: https://code.claude.com/docs/en/discover-plugins · https://code.claude.com/docs/en/plugins · https://code.claude.com/docs/en/plugins-reference

---

## How Plugins Actually Work

A plugin is a packaged `.claude/` directory — same agents, skills, hooks — bundled so anyone can install it with one command instead of manually copying files.

When someone runs `/plugin install software-dev-agentic`, Claude Code:
1. Downloads and copies the plugin into `~/.claude/plugins/cache/software-dev-agentic-v1.0.0/`
2. Loads agents, skills, and hooks from that cache into every session

The cache location is **per user, per machine** — not in the project.

**One key difference from standalone `.claude/`:** plugin components are namespaced.

| Standalone | Plugin |
|---|---|
| `.claude/skills/review/` → `/review` | `plugin/skills/review/` → `/software-dev-agentic:review` |
| `.claude/agents/domain-worker.md` → `domain-worker` | `plugin/agents/domain-worker.md` → `software-dev-agentic:domain-worker` (UI display) |

---

## What the Plugin System Provides

A plugin is a directory with `.claude-plugin/plugin.json` plus these folders at the plugin root:

| Directory | Contents |
|---|---|
| `skills/` | `<name>/SKILL.md` — namespaced as `/plugin-name:skill-name` |
| `agents/` | Agent `.md` files |
| `hooks/` | `hooks.json` with lifecycle event handlers |
| `.mcp.json` | MCP server configurations |
| `settings.json` | Plugin-level settings — currently only `agent` and `subagentStatusLine` keys |
| `bin/` | Executables added to the Bash tool's `$PATH` while the plugin is active |
| `scripts/` | Arbitrary scripts, callable from hooks via `${CLAUDE_PLUGIN_ROOT}/scripts/...` |
| `monitors/` | Background monitor configurations |

**Key environment variables available in hooks and MCP/LSP configs:**
- `${CLAUDE_PLUGIN_ROOT}` — absolute path to the plugin's cache dir (changes on update)
- `${CLAUDE_PLUGIN_DATA}` — persistent dir at `~/.claude/plugins/data/{id}/` that survives updates
- `${user_config.KEY}` — values the user provided when enabling the plugin

**Distribution:** Published via a marketplace. Consumers run `/plugin marketplace add git@host/repo.git#v1.0.0` then `/plugin install <name>@<marketplace>`. Scoped at user / project / local. Auto-updates supported.

---

## If software-dev-agentic Were Shipped as a Plugin

### Plugin source structure

```
software-dev-agentic/
├── .claude-plugin/
│   └── plugin.json          ← name, version, userConfig (platform selection)
├── agents/                  ← core agents loaded by Claude Code
│   ├── domain-worker.md
│   ├── data-worker.md
│   └── ...
├── skills/                  ← user-invocable toolkit skills only
│   ├── doctor/
│   ├── release/
│   └── agentic-perf-review/
├── hooks/
│   └── hooks.json           ← SessionStart → runs scripts/setup.sh
├── scripts/
│   └── setup.sh             ← copies lib/ into project's .claude/
└── lib/                     ← raw files, NOT loaded by Claude Code directly
    ├── core/
    │   └── reference/
    └── platforms/
        ├── web/
        │   ├── skills/contract/   ← copied into .claude/skills/ by setup.sh
        │   └── reference/
        ├── ios/
        │   ├── skills/contract/
        │   └── reference/
        └── flutter/
            ├── skills/contract/
            └── reference/
```

### What the installed plugin looks like on disk

After `/plugin install software-dev-agentic`, the full plugin directory is copied as-is into the user's local cache — not into the project:

```
~/.claude/plugins/cache/software-dev-agentic-v1.0.0/   ← per user, per machine
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── domain-worker.md
│   └── ...
├── skills/
│   ├── doctor/SKILL.md
│   └── ...
├── hooks/
│   └── hooks.json
├── scripts/
│   └── setup.sh
└── lib/
    ├── core/reference/
    └── platforms/
        ├── web/skills/contract/domain-create-usecase/SKILL.md
        ├── ios/skills/contract/domain-create-usecase/SKILL.md
        └── flutter/skills/contract/domain-create-usecase/SKILL.md
```

`${CLAUDE_PLUGIN_ROOT}` resolves to `~/.claude/plugins/cache/software-dev-agentic-v1.0.0/`. This path changes every time the plugin updates to a new version.

The SessionStart hook would then produce the flat structure in the project's `.claude/` — identical to what `setup-symlinks.sh` produces today:

```
.claude/
  agents/
    domain-worker.md      → (symlink or copy from ~/.claude/plugins/cache/...)
    pr-review-worker.md   → (ios platform agent)
  skills/
    domain-create-usecase → (ios implementation)
    doctor                → (core toolkit skill)
  reference/
    builder/
    contract/
```

No `lib/` in the downstream project — the hook extracts it into the flat structure, same as the script does today.

### What the SessionStart hook does

On every session start, `setup.sh` runs:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
CLAUDE_DIR="$PROJECT_ROOT/.claude"
PLATFORM="${user_config.platform}"   # ios | web | flutter

# Copy platform skills into .claude/skills/
cp -rn "$PLUGIN_ROOT/lib/platforms/$PLATFORM/skills/contract/." "$CLAUDE_DIR/skills/"

# Copy reference docs
cp -rn "$PLUGIN_ROOT/lib/core/reference/." "$CLAUDE_DIR/reference/"
cp -rn "$PLUGIN_ROOT/lib/platforms/$PLATFORM/reference/." "$CLAUDE_DIR/reference/"

# Create dedicated directories
mkdir -p "$CLAUDE_DIR/agents.local/extensions"
mkdir -p "$CLAUDE_DIR/skills.local/extensions"
mkdir -p "$CLAUDE_DIR/agent-memory"
mkdir -p "$CLAUDE_DIR/agentic-state"

# Seed templates (idempotent)
[ -f "$PROJECT_ROOT/CLAUDE.md" ] || cp "$PLUGIN_ROOT/CLAUDE-template.md" "$PROJECT_ROOT/CLAUDE.md"
[ -f "$CLAUDE_DIR/settings.local.json" ] || cp "$PLUGIN_ROOT/settings-template.json" "$CLAUDE_DIR/settings.local.json"
```

Workers still do `Read .claude/skills/domain-create-usecase/SKILL.md` — path unchanged. The plugin just takes over the job of putting the right file there.

---

## Key Problems with This Approach

### 1. Platform skills are a project fact, not a user preference

Plugin `userConfig` (where platform is stored) is scoped to the user's settings:

```
~/.claude/settings.json
  pluginConfigs:
    software-dev-agentic:
      options:
        platform: ios     ← applies to ALL projects on this machine
```

One platform setting across all projects. An engineer working on both talenta-ios and a web project cannot have different platform skills per project — the plugin doesn't know which project it's in.

Installing at project scope (`--scope project`) stores `userConfig` in `.claude/settings.json` instead, which is per-project. But the plugin cache is still at `~/.claude/plugins/cache/` — per user, not shared. Every teammate must still install the plugin independently.

The submodule encodes platform as a project fact committed to git: `setup-symlinks.sh --platform=ios` runs once, the symlinks are committed, and every teammate gets iOS skills on `git pull` — no per-user configuration needed.

### 3. Per-user cache, not per-project

The plugin lives in `~/.claude/plugins/cache/` on each engineer's machine — not in the git repo. Skill files copied into `.claude/skills/` are populated per user.

**If `.claude/skills/` is gitignored:** every teammate must install the plugin before Claude can run workers. One missing install = broken session.

**If `.claude/skills/` is committed:** files are in git, but they're generated output — updates require re-running the hook + recommitting.

The submodule solves this cleanly: it IS committed to the repo, so `git pull` is all teammates need.

### 4. Agent namespacing — open question

Plugin agents are namespaced in the UI as `software-dev-agentic:domain-worker`. Whether orchestrators need to reference workers by the full namespaced name or short name in the `agents` frontmatter field is **not documented** and would need testing. If full names are required, every orchestrator becomes coupled to the plugin name — a breaking coupling.

### 5. Copied files go stale on plugin update

`${CLAUDE_PLUGIN_ROOT}` changes on every plugin version update. If using symlinks instead of copies, they break until next session start. If using copies, they're stale until the next session start re-copies. Either way there's a window of inconsistency.

### 6. `settings.json` seeding is partial

Plugin `settings.json` only supports `agent` and `subagentStatusLine`. The full `settings-template.json` (permissions, env vars, tool allowlists) must be seeded by the hook script instead — outside the plugin spec.

---

## Where Plugins Are Better

| Plugin advantage | Current gap |
|---|---|
| Marketplace discovery (`/plugin install`) | Engineers run `setup-packages.sh` manually |
| Version pinning with auto-update (`#v1.0.0`) | `sync.sh` + manual `git add` of submodule pointer |
| Hot-reload (`/reload-plugins`) | Session restart required to pick up changes |
| User-scope install (cross-project, no per-repo submodule wiring) | Submodule must be added and committed in every repo |
| `userConfig` prompted at enable time | `--platform=` flag must be passed manually to setup script |
| LSP server bundling | Not supported today |

---

## Decision

**A full plugin migration is not recommended yet.**

The installed plugin lives at `~/.claude/plugins/cache/` per user — not in the project repo. This fundamentally conflicts with our need for shared, path-addressable skill files that all teammates get automatically via `git pull`. The agent namespacing behavior is also untested. These are structural unknowns, not configuration details.

**Recommended path: hybrid.**

Keep the submodule as the stable runtime mechanism. Add a thin plugin wrapper that:
1. Exposes a `marketplace.json` so teams can `/plugin marketplace add git@...`
2. Bundles a `SessionStart` hook that calls the existing setup script
3. Uses `userConfig` for platform selection instead of the manual `--platform=` flag

This gives the distribution UX (marketplace, auto-update, version pinning) without replacing the symlink architecture the DI pattern depends on.

---

## Revisit Criteria

Re-evaluate full-plugin (no submodule) approach when:

- Agent namespacing behavior with the `agents` frontmatter field is documented and tested
- Plugin files can be installed project-scoped (into `.claude/` instead of `~/.claude/plugins/cache/`)
- Full `settings.json` support ships (permissions, env vars, hooks config)
- CLAUDE.md template injection is part of the plugin spec
