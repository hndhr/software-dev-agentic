# Detective Agent Design

> **Status: Draft / In Progress** — this is a brainstorm document, not final architecture. Decisions here are directional and subject to change.

## What Detective Is

The detective persona is an **expert debugger** — it applies the scientific debugging method (from Andreas Zeller's *Why Programs Fail*) to find root causes without fixing them.

The governing principle: **diagnosis and treatment are separate concerns**. Detective finds the wound, a different agent closes it.

Theoretical foundation — Scientific Debugging:
1. Observe — reproduce the failure, collect the symptom
2. Hypothesize — form a falsifiable claim about the root cause
3. Predict — what observable evidence would confirm or deny it?
4. Experiment — instrument the system to collect that evidence
5. Conclude — accept, reject, or refine the hypothesis

## What Detective Is Not

- A fix agent — never modifies business logic
- A prompt debugger — `prompt-debug-worker` was removed; prompt/agent debugging is a separate domain (see `perf-worker`)

## Current Agent Structure

```
lib/core/agents/detective/
  debug-orchestrator.md     tools: Read, Glob, Grep      — static analysis + hypothesis formation
  debug-worker.md           tools: Read, Glob, Grep      — traces root cause through CLEAN layers
  debug-log-worker.md       tools: Read, Edit, Glob, Grep — only agent that writes to files
```

**Tool boundary rule:** `Edit` lives exclusively in `debug-log-worker`. The orchestrator and worker are read-only by design — they physically cannot instrument code themselves.

`debug-log-worker` operates in two modes:
- `MODE=add` — inserts hypothesis-tagged log statements at specified locations
- `MODE=remove` — strips all debug logs before committing

## Future Direction: Feature-Specific Debugging

### The Problem

Complex cross-platform features (e.g. Live Tracking, Clock In/Out) have:
- Different implementations per platform (Flutter vs iOS vs Android)
- Possible behavioral divergence between platforms for the same feature
- Domain knowledge that doesn't belong in a generic debug-worker

### Rejected Approach: Feature-Specific Workers

Creating `live-tracking-debug-worker`, `clock-debug-worker`, etc. was considered but rejected. It mixes methodology, platform syntax, and domain knowledge into one file — leading to N × P worker proliferation (N features × P platforms).

### Chosen Direction: Platform Workers + Feature Reference Docs

Isolate on two independent axes:

**Platform workers** — own methodology + platform syntax:
```
lib/core/agents/detective/
  flutter-debug-worker.md    ← Dart, BLoC, MQTT, pub cache
  ios-debug-worker.md        ← Swift, UIKit, background task lifecycle
  android-debug-worker.md    ← Kotlin, coroutines, foreground service
```

**Feature reference docs** — own domain knowledge:
```
lib/core/reference/features/
  live-tracking.md           ← cross-platform: Flutter + iOS + Android
  clock-attendance.md        ← cross-platform: iOS + Android

lib/platforms/ios/reference/features/
  face-id-auth.md            ← iOS only

lib/platforms/flutter/reference/features/
  offline-sync.md            ← Flutter only
```

Rules:
- Cross-platform features → `lib/core/reference/features/` (one doc, platform sections inside)
- Platform-only features → `lib/platforms/<platform>/reference/features/`
- Platform workers check core first, then their own platform folder

For cross-platform behavioral divergence, `debug-orchestrator` spawns both platform workers in parallel and compares findings — that's an orchestrator responsibility.

## Feature Reference Doc Structure (Token-Efficient)

Section headings must be greppable by platform name. A platform worker runs one `Grep` to get only its section — never reads the whole file.

```markdown
# <Feature Name>

## Overview
[2-3 lines max — what the feature does, entry points]

## Flutter
[BLoC structure, packages, key classes]

## iOS
[Swift classes, lifecycle hooks, API calls]

## Android
[Kotlin classes, services, API calls]

## Cross-Platform Differences
| Behavior | Flutter | iOS | Android |
|---|---|---|---|
| ...                |         |     |         |

## Known Failure Modes
### Flutter
### iOS
### Android
```

**Access pattern in platform workers:**
```
Grep "## Flutter" lib/core/reference/features/live-tracking.md   → Flutter section only
Grep "## Cross-Platform" lib/core/reference/features/live-tracking.md  → comparison table only
```

Anti-pattern: prose paragraphs mixing platform details — forces a full `Read`.

## Open Questions

- [ ] Should platform workers live inside `detective/` or get their own folder (e.g. `lib/platforms/<platform>/agents/`)?
- [ ] Does `debug-orchestrator` need to be updated to route to platform workers once they exist?
- [ ] What triggers a platform worker vs the generic `debug-worker` — user-provided platform context, or auto-detected from file paths in the symptom?
