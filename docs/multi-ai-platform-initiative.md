# Multi-AI Platform Initiative

**Status:** Planning
**Scope:** Extend software-dev-agentic to support GitHub Copilot and Gemini alongside Claude Code.

---

## Context

Teams using this toolkit are not exclusively on Claude Code. Peers use GitHub Copilot and Gemini CLI. The goal is to let any engineer — regardless of AI tool — benefit from the same project conventions, architecture rules, and layer contracts defined in `lib/`.

Claude Code setup stays unchanged. Other AI support is purely additive.

---

## Phase 1 — Context Files (Current Initiative)

Generate the AI-native instruction file for each platform from the same platform reference docs already in `lib/platforms/<platform>/reference/`.

| AI | Config file | Location |
|---|---|---|
| GitHub Copilot | `copilot-instructions.md` | `.github/copilot-instructions.md` |
| Gemini CLI | `GEMINI.md` | Project root |

### What gets included

- Project architecture overview (Clean Architecture layers)
- Layer rules and creation order
- Naming conventions
- Key reference doc paths
- Do-not-cross boundaries (e.g. no Codable in domain entities)

### Scripts

- `scripts/setup-ai.sh --ai=copilot|gemini --platform=<platform>` — generates the config file
- `scripts/clean-ai.sh --ai=copilot|gemini` — removes the config file
- Both wired into `sda.sh` as `Add AI` and `Remove AI` menu options

### Templates

Templates live in `lib/ai-platforms/<ai>/template.md`. Content is assembled from platform reference docs at generation time, not hardcoded.

---

## Phase 2 — Native Skills (Future)

Both platforms have a skill/command system. Bridging our skills to their format would let peers invoke the same build procedures.

### Gemini CLI

Gemini CLI supports `.agents/skills/<skill-name>/SKILL.md` — structurally similar to our skill directories. Our existing `SKILL.md` files are compatible enough to symlink or copy.

**Work needed:**
- `scripts/setup-ai.sh` extended to also link `lib/platforms/<platform>/skills/` into `.agents/skills/`
- Validate that Gemini's skill discovery picks them up correctly
- Test a subset (e.g. `domain-create-entity`, `data-create-mapper`) before full rollout

### GitHub Copilot

Copilot has no skill invocation primitive — there is no equivalent to `/skill-name`. Custom instruction files (`AGENTS.md`, `.github/instructions/`) are declarative only and cannot be invoked as commands. Phase 2 does not apply to Copilot.

---

## Phase 3 — Hooks (Future, Copilot only)

Copilot hooks (preview) support the same lifecycle events as Claude Code hooks. A converter from our shell-based hooks to Copilot's JSON format could be built once the Copilot hooks API stabilizes.

Gemini CLI has no hook system — skip.

---

## Principles × Platform Equivalence

### 1. Project Conventions

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Project-level instructions | `CLAUDE.md` | `GEMINI.md` | `.github/copilot-instructions.md` |
| Path-specific instructions | Per-directory `CLAUDE.md` | Per-directory `GEMINI.md` | `.github/instructions/*.instructions.md` with glob patterns |
| Reference doc imports | `@` in CLAUDE.md | `@path` native syntax | Path hints only — not imported |
| Extension/override | `agents.local/`, `skills.local/`, `reference.local/` | No equivalent | No equivalent |

### 2. Skills (Procedures)

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| User-invocable procedure | Type T / Type U skill (`/name`) | `.agents/skills/<name>/SKILL.md` — similar format, invoked via chat | No equivalent — instructions only |
| Agent-invocable procedure | Type A skill (worker calls by name) | No equivalent | No equivalent |
| Destructive-only procedure | Type B skill (`disable-model-invocation`) | No equivalent | No equivalent |
| Skill preloading | `skills:` frontmatter field — injected at agent startup | No equivalent | No equivalent |

### 3. Agents (Brain / Decision-Maker)

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Spawning a sub-agent | `Agent` tool — isolated context window | No equivalent | No equivalent |
| Orchestrator/worker pattern | Yes — `agents:` field + delegation chain | No equivalent | No equivalent |
| Planner agent | Yes — read-only, produces `plan.md` | No equivalent | No equivalent |
| Layer isolation (bounded authority) | Enforced by worker role + reference docs | No equivalent | No equivalent |
| Agent descriptions (routing) | `description:` frontmatter — natural language routing | No equivalent | No equivalent |
| Platform-agnostic workers + platform skills | DI at skill level | No equivalent | No equivalent |

### 4. Context Management

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Isolated context per agent | Yes — each spawned agent is a separate context window | No — single conversation context | No — single conversation context |
| Context relay (trigger skill → agent) | Yes — `context.md` + `state.json` inlined into spawn prompt | No equivalent | No equivalent |
| Grep-first reference loading | Yes — agents Grep by section offset, not full-file reads | No equivalent | No equivalent |
| Resume routing (existing run detection) | Yes — trigger skill checks runs directory | No equivalent | No equivalent |

### 5. Hooks (Automated Enforcement)

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Pre-tool hook | Yes — shell scripts in `settings.json` | No equivalent | Preview — JSON format (`.github/hooks/*.json`) |
| Post-tool hook | Yes | No equivalent | Preview |
| Stop hook | Yes | No equivalent | Preview |
| Notification hook | Yes | No equivalent | Preview |

### 6. Architecture Reference

| Principle | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Layered reference docs | `lib/core/reference/` + `lib/platforms/<platform>/reference/` | No equivalent | No equivalent |
| Override at project level | `reference.local/` shadows platform/core | No equivalent | No equivalent |
| Lean — pointer not embed | `CLAUDE.md` references paths, never inlines | `GEMINI.md` with `@import` (live) | Path hints only |

### Summary

| Capability | Claude Code | Gemini CLI | GitHub Copilot |
|---|---|---|---|
| Project conventions | Full | Full | Full |
| Path-specific instructions | Full | Full | Full |
| User-invocable skills | Full | Partial | None |
| Agent-invocable skills | Full | None | None |
| Agent spawning / isolation | Full | None | None |
| Orchestrator/worker pattern | Full | None | None |
| Hooks | Full | None | Preview only |
| Context relay + resume | Full | None | None |
| Architecture reference system | Full | None | None |

Phase 1 closes the conventions gap for all platforms. Phase 2 closes the skills gap for Gemini only — Copilot has no skill invocation primitive. Phase 3 (hooks) is Copilot-only and blocked on API stability. Everything beyond conventions — orchestration, context isolation, reference system — is Claude Code only.

---

## References

- [GitHub Copilot custom instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [GitHub Copilot custom agents](https://docs.github.com/en/copilot/concepts/agents)
- [GitHub Copilot hooks (preview)](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-hooks)
- [Gemini CLI — GEMINI.md](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html)
- [Gemini CLI — Agent Skills](https://codelabs.developers.google.com/gemini-cli/how-to-create-agent-skills-for-gemini-cli)
- [Gemini CLI — Custom Commands](https://google-gemini.github.io/gemini-cli/docs/cli/custom-commands.html)
