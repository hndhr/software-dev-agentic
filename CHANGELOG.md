# Changelog

All notable changes to this starter kit will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.2] — 2026-04-12

### Fixed
- `scripts/setup-symlinks.sh` — hooks were never symlinked into `.claude/hooks/`; script now creates the directory and links each `.sh` file

---

## [3.0.1] — 2026-04-12

### Fixed
- `lib/platforms/ios/skills/test-fix/` — stale reference `testing-patterns.md` → `testing-patterns-advanced.md`
- `lib/platforms/ios/skills/migrate-usecase/` — stale reference `domain-layer.md` → `domain.md`

---

## [3.0.0] — 2026-04-12

### Changed
- **`core/` and `platforms/` moved into `lib/`** — all distributable content now lives under `lib/core/` and `lib/platforms/`. **Breaking**: downstream projects must re-run `setup-symlinks.sh` or `setup-packages.sh` after updating the submodule pointer.
- `scripts/setup-symlinks.sh`, `setup-packages.sh`, `sync.sh` — all path references updated to `lib/core/` and `lib/platforms/`
- All agents and skills with path references updated (`arch-review-orchestrator`, `arch-review-worker`, `setup-worker`, `setup-nextjs-project`, `setup-ios-project`, `arch-check-conventions`, `docs-identify-changes`)
- `CLAUDE.md` structure updated to reflect `lib/` layout

---

## [2.1.0] — 2026-04-12

### Added
- `core/agents/installer/` — installer persona group: `setup-worker` (platform-agnostic project setup + onboarding)
- `platforms/ios/skills/setup-ios-project/` — iOS project setup skill (copies CLAUDE-template, prompts for placeholders, creates agents.local stub)

### Changed
- `platforms/web/skills/setup-nextjs-project/` — now `user-invocable: false`; called by `setup-worker`; orientation content removed (worker handles that); step numbering fixed; agents.local reference updated to `arch-review-worker`
- `packages/core.pkg` — `setup-worker` added to always-installed agents
- `platforms/web/CLAUDE-template.md` — `setup-worker` added to agents list
- `platforms/ios/CLAUDE-template.md` — `setup-worker` added to agents list

### Removed
- `HINTS.md` — replaced by `setup-worker` orientation output and `CLAUDE-template.md` agents list

---

## [2.0.0] — 2026-04-12

### Added
- `core/agents/builder/` — builder persona group: `feature-orchestrator`, `backend-orchestrator`, `pres-orchestrator`, `domain-worker`, `data-worker`, `presentation-worker`, `ui-worker`, `test-worker`
- `core/agents/detective/` — detective persona group: `debug-orchestrator`, `debug-worker`
- `core/agents/tracker/` — tracker persona group: `issue-worker`
- `core/agents/auditor/` — auditor persona group: `arch-review-worker` (platform-agnostic)
- `packages/builder.pkg`, `packages/detective.pkg`, `packages/auditor.pkg` — selective installation via `setup-packages.sh`
- `platforms/web/skills/arch-check-web/` — web-specific CLEAN rules (W1–W6: import direction, hook exposure, ViewModel patterns, directive placement, Server Actions, Atomic Design)
- `platforms/ios/skills/arch-check-ios/` — iOS-specific CLEAN rules (I1–I4: layer imports, legacy folder violations, UseCase bypass, RepositoryImpl placement)
- `agents/arch-review-orchestrator.md` — internal convention review orchestrator (not symlinked to downstream projects)
- `agents/arch-review-worker.md` — internal convention review worker; runs `arch-check-conventions` per file
- `skills/arch-check-conventions/` — full convention checklist: frontmatter, Grep-first, isolation, model selection, platform-agnosticism, Fix F, Fix G, naming
- `skills/arch-generate-report/` — formats raw convention findings into severity-grouped report
- `agents/docs-sync-worker.md` — manual Confluence sync worker; applies targeted section updates after sessions that change structure or conventions
- `skills/docs-identify-changes/` — maps session delta descriptions to stale Confluence doc sections

### Changed
- `core/agents/` restructured from flat to persona subdirectories — **breaking**: downstream projects must re-run `setup-symlinks.sh` or `setup-packages.sh` to pick up the new paths
- `setup-packages.sh` — new Step 2: core agent group selection (builder / detective / auditor) before platform packages
- `setup-symlinks.sh` — `link_agents()` now recurses into persona subdirectories; all agents still land flat in `.claude/agents/`
- `core/agents/auditor/arch-review-worker.md` — rewritten as platform-agnostic; universal CLEAN rules U1–U5 in body; platform rules delegated to `arch-check-web` and `arch-check-ios` skills
- iOS platform skills (20 files) — corrected broken reference filenames (`domain-layer.md` → `domain.md`, `data-layer.md` → `data.md`, `testing-patterns.md` → `testing-patterns-advanced.md`); Grep-first added to all reference reads
- `platforms/ios/agents/test-orchestrator.md` — added `isolation: worktree` and `## Search Rules` section
- `platforms/ios/agents/pr-review-worker.md` — added `## Search Rules` section
- `core/agents/builder/pres-orchestrator.md` — added `isolation: worktree` to Constraints
- `core/agents/detective/debug-orchestrator.md` — added `isolation: worktree` to Constraints

---

## [1.2.1] — 2026-04-11

### Fixed
- `perf-worker` — reports now write to `web-agentic/perf-report/` (submodule) instead of downstream project's `journey/`; worker commits and pushes from inside `.claude/web-agentic/`
- `perf-worker` — report filename now follows `[project]-[YYYY-MM-DD]-[short-session-description].md` pattern for cross-project readability in git log

---

## [1.2.0] — 2026-04-11

### Added
- `agents/perf-worker.md` — agentic performance analyst; reads extracted session JSON, scores 7 dimensions (orchestration, worker invocation, skill execution, token efficiency, routing accuracy, workflow compliance, one-shot rate) with numeric scores, writes report to `journey/` and commits it
- `skills/agentic-perf-review/SKILL.md` — user-invocable `/agentic-perf-review <issue> [session_id]` slash command; extracts session data then spawns perf-worker for isolated analysis
- `scripts/extract-session.sh` — parses a Claude Code session JSONL into structured JSON (token totals, tool call frequencies, agent spawns, skill calls, duplicate reads, read:grep ratio); auto-detects current session or accepts explicit session ID
- `journey/` — serialized log of agentic design observations and improvements; entry 01 documents token optimization investigation against Core Design Principles

---

## [1.1.0] — 2026-04-10

### Added
- `/doctor` skill — flutter-doctor-style setup audit: checks submodule staleness, agent/skill symlinks (including broken links), CLAUDE.md managed markers, settings.local.json placeholder, and GitHub CLI auth
- `setup-packages.sh` — interactive package installer; presents a menu of packages, always installs core, lets user select orchestrator bundles (feature, backend, debug, arch-review)
- `packages/` directory with `.pkg` manifests defining agent + skill dependencies per package; orchestrator packages automatically include all dependent workers and skills

### Changed
- `CLAUDE-template.md` — added `<!-- BEGIN web-agentic -->` / `<!-- END web-agentic -->` managed section markers
- `setup-symlinks.sh` — copies `CLAUDE-template.md` → `CLAUDE.md` on first run if no CLAUDE.md exists
- `sync.sh` — replaces only the managed section in downstream `CLAUDE.md` on each sync, leaving platform-specific content untouched
- `CLAUDE.md` workflow instructions — replaced `@issue-worker` with plain `issue-worker` to avoid spurious Skill tool lookup errors

---

## [1.0.0] — 2026-04-10

### Changed
- **Agent architecture**: Refactored from 5 flat agents to 2 orchestrators + 6 workers following Core Design Principles
  - `feature-scaffolder` → `feature-orchestrator` (coordinates domain/data/presentation workers)
  - `backend-scaffolder` → `backend-orchestrator` (coordinates domain/data workers for full-stack)
  - `arch-reviewer` → `arch-review-worker`
  - `test-writer` → `test-worker`
  - `debug-agent` → `debug-worker`
  - NEW: `domain-worker`, `data-worker`, `presentation-worker` (split from feature-scaffolder)
- **Skill classification**: All skills now typed as Type A (`user-invocable: false`) or Type B (`disable-model-invocation: true`) — no Type C
- **Skill naming**: Layer-prefixed convention (`domain-*`, `data-*`, `pres-*`, `test-*`)
- **Skill content**: Bodies slimmed to ~30 lines; code templates extracted to `template.md` files
- **Natural language routing**: Skills are agent-only (Type A) — users describe intent, Claude routes to the right agent
- **Extension hooks**: Every agent ends with an extension point for `.claude/agents.local/extensions/`

### Added
- `domain-create-entity`, `domain-create-usecase`, `domain-create-repository`, `domain-create-service` skills
- `data-create-mapper`, `data-create-datasource`, `data-create-repository-impl`, `data-create-db-datasource`, `data-create-db-repository` skills
- `pres-create-viewmodel`, `pres-create-view`, `pres-create-server-action`, `pres-wire-di`, `pres-ssr-check` skills
- `test-create-mock`, `test-create-domain`, `test-create-data`, `test-create-presentation` skills

### Removed
- Old flat agent files: `feature-scaffolder`, `backend-scaffolder`, `arch-reviewer`, `test-writer`, `debug-agent`
- Old skill directories: `new-entity`, `new-usecase`, `new-feature`, `new-viewmodel`, `new-server-action`, `new-db-repository`, `scaffold-repository`, `scaffold-service`, `create-mock`, `write-tests`, `integration-test`, `ssr-check`, `wire-di`

---

## [0.1.0] — 2026-04-10

### Added
- Initial release of the Next.js Clean Architecture starter kit
- Architecture reference docs (`reference/`) covering domain, data, presentation, DI, testing, SSR, server actions, database, API routes, error handling, navigation, utilities, and modular structure
- Agent definitions: `feature-scaffolder`, `arch-reviewer`, `test-writer`, `debug-agent`, `backend-scaffolder`
- Skills: `new-feature`, `new-entity`, `new-usecase`, `new-viewmodel`, `write-tests`, `ssr-check`, `wire-di`, `create-mock`, `scaffold-service`, `scaffold-repository`, `integration-test`, `create-issue`, `pickup-issue`, `new-server-action`, `new-db-repository`, `setup-nextjs-project`
- Hooks: `block-impl-import-in-presentation.sh`, `lint-on-edit.sh`, `check-use-server.sh`
- `CLAUDE-template.md` for project-level Claude instructions
- `settings-template.json` with hooks pre-wired
- `README.md` with AI Project Setup flow
- `HINTS.md` quick reference guide
