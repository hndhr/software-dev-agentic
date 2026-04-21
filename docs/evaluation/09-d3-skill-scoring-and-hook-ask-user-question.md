# D3 Skill Scoring Context-Blindness and Hook Free-Text Fallback

> Date: 2026-04-17
> Type: Improvement
> Related: [perf-worker.md](../lib/core/agents/perf-worker.md), [require-feature-orchestrator.sh](../lib/core/hooks/require-feature-orchestrator.sh)
> Sessions analysed: talenta TLMN-5139 (2026-04-17, session 429d1835), talenta TLMN-5110 (2026-04-17, session 4d801fd7)
> Perf reports: [talenta-2026-04-17-429d1835-remove-live-attendance-ip-flag](../perf-report/talenta-2026-04-17-429d1835-remove-live-attendance-ip-flag.md), [talenta-2026-04-17-4d801fd7-remove-revamp-dashboard-flag](../perf-report/talenta-2026-04-17-4d801fd7-remove-revamp-dashboard-flag.md)

## Trigger

Two talenta flag-removal sessions on 2026-04-17 were reviewed. Post-review discussion revealed two separate issues:

1. **D3 over-penalised removal work** — both sessions scored Fair or Poor on D3 (Skill Execution) despite doing primarily flag-guard deletion, where no skills apply. The perf-worker was penalising zero skill calls without checking whether the work actually warranted skill invocation.

2. **Hook presented free-text instead of structured choices** — in TLMN-5139, the delegation guard hook fired and Claude asked the user how to proceed — but as a free-text question rather than a structured `AskUserQuestion` with selectable options. The hook's prose instructions were ambiguous about the exact tool call shape needed.

---

## Root Cause Analysis

### D3 Context-Blindness

The D3 rubric in `perf-worker.md` had two paths:

- Deduct `-2` if `write_paths` contains an artifact file with no corresponding skill call.
- Score N/A (8/10) if "no skills were called and inline handling was appropriate."

The second path depended on the perf-worker judging "appropriate" from context — but there was no structured guidance for making that call. With no explicit work-nature classification, the worker defaulted to penalising any session with zero skill calls that touched artifact files, even if those writes were just removing conditional guards from existing files.

The flaw: `write_paths` containing `DashboardViewModel.swift` looks identical whether the write added a field or deleted 3 lines of flag guard. The worker needs to classify work nature *before* applying the skill alignment check.

### Hook Free-Text Fallback

The hook's block message instructed Claude to "Use AskUserQuestion with exactly these three options" — but only listed the options as prose. The `AskUserQuestion` tool requires a structured `questions` array with `question`, `header`, `multiSelect`, and `options` (each with `label` + `description`). Without this explicit structure in the hook output, Claude reconstructed the call from the prose description, omitting the `options` parameter and defaulting to a free-text question prompt instead.

---

## Changes Made

### Updated: `lib/core/agents/perf-worker.md` — D3 work-nature classification

Added a **Work-nature classification** table before the skill-to-artifact alignment check:

| Work nature | Signal | Skill required? |
|---|---|---|
| New artifact creation | New file in `write_paths` | Yes |
| File restoration | Description mentions "restore"; path deleted earlier in session | Yes |
| Artifact update (adding/changing fields) | Existing file, description mentions "update"/"add field" | Yes |
| Flag/dead-code removal | Description mentions "remove"/"delete"/"flag"; no new files | No — N/A (8/10) |
| File deletion only | No new `write_paths`, only Bash `rm` calls | No — N/A (8/10) |

Mixed sessions (removal + restoration) apply skill requirements only to the creation/restoration portion.

### Updated: `lib/core/hooks/require-feature-orchestrator.sh` — explicit AskUserQuestion structure

Replaced the prose option list with the exact `AskUserQuestion` parameter structure Claude must use:

```
questions: [
  {
    question: "How should this feature edit be handled?",
    header: "Delegation",
    multiSelect: false,
    options: [
      { label: "Plan first (feature-planner)", description: "..." },
      { label: "Delegate now (feature-orchestrator)", description: "..." },
      { label: "Proceed inline (bypass)", description: "..." }
    ]
  }
]
```

This eliminates the ambiguity that caused Claude to reconstruct the call shape from prose and fall back to free-text.

---

## Downstream Impact

`perf-worker.md` is internal to this repo — no downstream sync needed. The D3 improvement takes effect on the next perf-review session.

`require-feature-orchestrator.sh` is a core hook symlinked into downstream projects. Projects already set up will pick up the change automatically on their next session start.

---

## Open Questions

1. **Other hooks with AskUserQuestion instructions** — if any other hooks use the same prose-style AskUserQuestion guidance, they will have the same free-text fallback problem. Worth auditing all hooks in `lib/core/hooks/` for this pattern.

2. **D3 scoring for partial removal + creation sessions** — the new classification handles the clear cases but "mixed" sessions still require the perf-worker to infer which writes were creation vs removal from descriptions alone. If agent spawn descriptions are terse, this inference may still be unreliable. A future improvement could require `write_paths` to be tagged with an operation type (create/update/delete) in the extracted JSON.
