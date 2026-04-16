# Agent Architecture

Understanding the three-layer model is critical before adding any agent or skill.

```
Core Orchestrators  (lib/core/agents/builder/)
      │  coordinate
      ▼
Core Workers        (lib/core/agents/builder/)
      │  call
      ▼
Platform Skills     (lib/platforms/<platform>/skills/)
```

## Layer 1 — Core Orchestrators

`feature-orchestrator`, `pres-orchestrator`, `backend-orchestrator`, etc.
Platform-agnostic. Coordinate workers in the right sequence. Never write files.
Live in `lib/core/agents/builder/`.

## Layer 2 — Workers

Two kinds — both execute skills, both write files:

**Core workers** (`lib/core/agents/builder/`) — platform-agnostic.
`domain-worker`, `data-worker`, `presentation-worker`, `ui-worker`, `test-worker`.
Work on **any** platform by calling the platform's skills.
Add here when the behaviour is identical across all platforms.

**Platform workers** (`lib/platforms/<platform>/agents/`) — platform-specific.
Exist only when the workflow diverges enough from core to need its own agent.
Examples: iOS `test-orchestrator` (knows `xcodebuild`, iOS paths), iOS `pr-review-worker` (knows Swift/UIKit conventions).
**Do not add a platform worker unless core worker + skills cannot handle it.**

## Layer 3 — Skills

`lib/platforms/<platform>/skills/` — platform-specific execution instructions.
Each skill is a `SKILL.md` in its own folder containing the code template + step-by-step instructions for generating platform-specific artifacts.
Called by **either** core workers **or** platform workers — skills don't care who calls them.

## Decision Rules

| Situation | Where it goes |
|-----------|--------------|
| New CLEAN-layer step, same on all platforms | Core worker |
| New orchestration flow, same on all platforms | Core orchestrator |
| New code generation pattern for one platform | Platform skill |
| Workflow too platform-specific for core worker | Platform worker |
| Architecture reference knowledge | `lib/platforms/<platform>/reference/` |

## Example: Flutter domain entity creation

```
feature-orchestrator  (core)
  └─ domain-worker    (core)      ← platform-agnostic, knows the rules
        └─ domain-create-entity   ← flutter skill, knows the syntax
             (lib/platforms/flutter/skills/domain-create-entity/SKILL.md)
```

The worker knows the rules (no framework imports, single responsibility).
The skill knows the syntax (Dart, `@freezed`, file naming conventions).
