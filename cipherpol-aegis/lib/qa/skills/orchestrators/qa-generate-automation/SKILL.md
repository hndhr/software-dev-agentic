---
name: qa-generate-automation
description: Generate Patrol Dart automation (testcases + scenarios) from an approved test case CSV. Writes files under integration_test/testcases/ and integration_test/scenarios/ in the downstream project.
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, AskUserQuestion, Agent
---

## Arguments

`$ARGUMENTS` — optional path to a test case CSV.

## Steps

### 0 — Locate input CSV

If `$ARGUMENTS` points to an existing `.csv` file, use it directly.

Otherwise:

```bash
find "$(git rev-parse --show-toplevel)/testcases" -name "*_test_cases.csv" 2>/dev/null
```

- **None found** — tell the user to run `/qa-generate-testcase` first and stop.
- **Multiple found** — call `AskUserQuestion` (one option per CSV, label = filename) to pick the input.
- **One found** — use it directly.

### 1 — Confirm scope

Call `AskUserQuestion`:

```
question    : "Which test cases should be automated?"
header      : "Scope"
multiSelect : false
options     :
  - label: "Smoke tests only", description: "Only rows tagged \"smoke\" in the tags column"
  - label: "All test cases",   description: "Every row in the CSV"
```

### 2 — Check device availability

```bash
patrol devices
```

If no device or emulator is listed, tell the user to start an emulator/simulator and stop.

### 3 — Spawn qa-automation-worker

Spawn `qa-automation-worker` via the Agent tool with the CSV path only — never inline CSV content:

> **csv_path:** <absolute path to selected CSV>
>
> **scope:** <smoke-only | all>
>
> **device:** <device id from step 2>
>
> Triage each row, present Gate 2 (Mapping Table Confirmation), then write Patrol Dart testcases and scenarios per `patrol-standard.md`. Validate every file via `patrol develop` before reporting done.

### 4 — Relay Gate 2 and final report

Relay the worker's Gate 2 mapping table verbatim and wait for explicit confirmation before it writes any Dart — loop back to the worker on adjustment requests. Never let it proceed past the gate silently.

Once the worker finishes, relay its final file list (testcases + scenarios written, validation results). If any test fails later, suggest `/qa-debug-automation`.
