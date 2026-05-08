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

Copilot supports custom agents via `.github/agents/*.agent.md` with frontmatter (`tools:`, `agents:`). Structurally similar to our agent files but uses a different convention.

**Work needed:**
- Define a mapping from our agent frontmatter → Copilot agent frontmatter
- Either generate `.github/agents/` files from our agent files, or maintain a separate Copilot-specific agent set in `lib/ai-platforms/copilot/agents/`
- Hooks are JSON-based (`.github/hooks/*.json`) — shell scripts would need a converter

---

## Phase 3 — Hooks (Future, Copilot only)

Copilot hooks (preview) support the same lifecycle events as Claude Code hooks. A converter from our shell-based hooks to Copilot's JSON format could be built once the Copilot hooks API stabilizes.

Gemini CLI has no hook system — skip.

---

## Capability Gap Summary

| Capability | Claude Code | Copilot | Gemini |
|---|---|---|---|
| Project conventions | `CLAUDE.md` | `copilot-instructions.md` | `GEMINI.md` |
| Skill invocation (`/name`) | Yes — Markdown skill files | No direct equivalent | Partial — `.agents/skills/` |
| Agent spawning | Yes — orchestrator/worker pattern | Yes (preview) | No |
| Hooks | Yes — shell scripts | Yes (preview) — JSON format | No |
| Full agentic behavior parity | — | Partial | Minimal |

Phase 1 closes the conventions gap for all platforms. Phases 2–3 close the skills and hooks gap progressively, prioritizing Gemini (closer format) over Copilot (needs conversion work).

---

## References

- [GitHub Copilot custom instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [GitHub Copilot custom agents](https://docs.github.com/en/copilot/concepts/agents)
- [GitHub Copilot hooks (preview)](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-hooks)
- [Gemini CLI — GEMINI.md](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html)
- [Gemini CLI — Agent Skills](https://codelabs.developers.google.com/gemini-cli/how-to-create-agent-skills-for-gemini-cli)
- [Gemini CLI — Custom Commands](https://google-gemini.github.io/gemini-cli/docs/cli/custom-commands.html)
