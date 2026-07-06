# QA Human-in-the-Loop Gates

> Related: gherkin-standard.md, pokayoke-integration.md, qa-testcase-worker.md, qa-automation-worker.md

Defines the mandatory human-approval checkpoints in the QA pipeline, and the rules every QA agent/skill must follow around them. The canonical test-case path is `testcases/`, and the sole visual/diagnostic tool for reviewing UI or Patrol state anywhere in this pipeline is `mcp__patrol__native-tree` — screenshots are never used for review or debugging.

## The 4-Phase Pipeline

```
Phase 1: Test-Case Generation
  qa-generate-testcase -> qa-testcase-worker
  Output: testcases/<feature>/<feature>_test_cases.csv + markdown notes
        |
        v
   +-------------+
   |   GATE 1    |  Test Case Approval
   +-------------+
        | (approve only)
        v
Phase 2: Automation Triage & Mapping
  qa-generate-automation -> qa-automation-worker (triage stage)
  Output: mapping table (Test Case | Priority | Automate? | Screen Folder | Testcase File | Notes)
        |
        v
   +-------------+
   |   GATE 2    |  Mapping Table Confirmation
   +-------------+
        | (confirm only)
        v
Phase 3: Patrol Test Generation
  qa-automation-worker -> qa-create-patrol-testcase / qa-compose-patrol-scenario
  Output: Dart files in integration_test/testcases/ and integration_test/scenarios/
        |
        v
Phase 4: Execution & Self-Healing Debug
  qa-debug-automation -> qa-debug-worker (on failure)
  Output: fixed Dart test files + updated failure-pattern knowledge
```

Sync to pokayoke (`qa-sync-testcase` → `qa-sync-worker`) is a separate, independently-triggered workflow — it consumes Phase 1's CSV output but is not one of Gate 1/2 above. It has its own confirmation points instead (dry-run before apply, per-id confirmation before delete); see `pokayoke-integration.md`.

## Gate 1 — Test Case Approval

**When:** immediately after `qa-testcase-worker` produces or regenerates the CSV and markdown notes (Phase 1).

**What is reviewed:** the CSV at its written path — completeness against acceptance criteria, correctness of steps against actual app behavior, smoke/regression tagging, and scope (no out-of-scope API/backend cases slipped in).

**Prompt to the user** must include the CSV path, summary counts by priority and category, and a CSV preview — never a bare "approve?":

> Please review the test cases in `<csv_path>`. Summary: `<N total, N smoke, N regression, priority breakdown>`. Shall I proceed to automation triage, or would you like changes?

**Allowed responses:** approve (proceed to Phase 2) · request edits (stay in Phase 1) · cancel.

**On edit requests:** regenerate the affected cases and re-present at Gate 1 — never fall through to Phase 2 on anything short of explicit approval.

## Gate 2 — Mapping Table Confirmation

**When:** immediately after the triage stage of `qa-automation-worker` produces the automation mapping table (Phase 2).

**What is reviewed:** which cases will be automated vs. skipped vs. need setup, screen-to-folder correctness, testcase file naming, and any "needs setup" items requiring env vars or fixture data.

**Prompt to the user** must show the full mapping table, not a summary count:

> Please confirm this mapping table. Should I proceed with writing the Patrol test files?
>
> | Test Case | Priority | Automate? | Screen Folder | Testcase File | Notes |
> |---|---|---|---|---|---|

**Allowed responses:** confirm (proceed to Phase 3) · request adjustments (stay in Phase 2) · cancel.

**On adjustment requests:** update the mapping entries and re-present at Gate 2 — no Dart is written before an explicit confirmation.

## Implementation Rules

1. **Never skip a gate.** Gate 1 and Gate 2 are mandatory pause points for every skill/agent that reaches them, with no bypass flag.
2. **Give full context, never a bare "approve?".** Every gate prompt carries the artifact path/content, summary counts, and the specific decisions made so far — enough for an informed answer without opening another file.
3. **No silent progression.** A phase transition happens only on an explicit approval/confirmation ("proceed", "confirm", "yes", or equivalent) — never inferred from silence or an unrelated reply.
4. **Loop on edit requests.** Requested changes are applied and the same gate is re-presented — approval is never forced into a binary approve/reject; the human can iterate at a gate as many times as needed.
5. **Record every gate decision.** Write what was approved (and any modifications requested) to this run's state file at `.claude/agentic-state/runs/qa/<feature>/state.json` — the Run Directory convention used across CipherPol personas — so the decision is traceable after the fact, not just visible in the conversation.

## Non-Goals

This document defines the gates only — it does not define the CSV schema (`gherkin-standard.md`), the Patrol authoring rules applied in Phase 3 (`patrol-standard.md`), or the pokayoke sync algorithm (`pokayoke-integration.md`). Consult those documents for the content each phase actually produces or consumes.
