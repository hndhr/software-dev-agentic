---
name: detective-report-ts
description: Investigate a Talenta iOS TS (Technical Support) issue report. Classifies the issue, gathers Crashlytics and/or Loki evidence, traces the implicated code, and proposes ranked fixes. Supports Crash, API, and other issue classes (ANR is not applicable on iOS).
user-invocable: true
allowed-tools: Agent, AskUserQuestion
---

## Prerequisites

This skill requires two MCP servers to be installed and active:
- **Firebase MCP** — for Crashlytics access
- **Loki MCP** — for Grafana log access

If either is missing, notify the user and stop.

---

## Platform Facts (injected into every agent spawn — do not modify)

```
PLATFORM: ios
FIREBASE_APP_ID: ios:co.talenta.ios
FIREBASE_DASHBOARD_URL: https://console.firebase.google.com/u/0/project/talenta-production/crashlytics/app/ios:co.talenta.ios/
GRAFANA_URL: <resolved via Loki MCP at runtime>
LOG_CACHE_REMOTE_CONFIG: mekari_log_cache_retention_validator
ENCRYPTED_ID_FORMAT: Talenta encrypted identifiers — user_id, user_email, company_id are passed as encrypted strings to Loki queries
ANR_APPLICABLE: false
```

---

## Arguments

`$ARGUMENTS` — optional TS report text provided at invocation time. If present, treat it as `REPORT`.

---

## Step 1 — Collect the report

If `$ARGUMENTS` is non-empty, use it as `REPORT`.
Otherwise, ask:

> Paste the TS report or describe the issue the user is experiencing.

---

## Step 2 — Resolve the repo

Infer the repo from `cwd`:
- Contains `talenta-ios` → repo confirmed as `talenta-ios`
- Ambiguous → AskUserQuestion: "Which repo are we working in? (`mobile-talenta` / `talenta-ios`)"

---

## Step 3 — Gather properties

Ask one at a time — skip any already present in `REPORT`:

1. "What date range did the issue occur? (e.g. 2026-06-18 to 2026-06-20)"
2. "Which iOS version was the affected user on? (e.g. iOS 17.4)"
3. "Which Talenta app version was installed? (e.g. 24.10.1)"
4. "What is the affected user's `user_id`?"
5. "What is the affected user's email address?"
6. "What is the affected user's `company_id`?"
7. "Do you know which screen or feature the user was on when the issue occurred? (Suggest based on the report — the user can confirm or correct.)"

Collect and store: `DATE_RANGE`, `OS_VERSION`, `APP_VERSION`, `USER_ID`, `USER_EMAIL`, `COMPANY_ID`, `SUSPECT_SCREEN`.

---

## Step 4 — Classify

Spawn `detective-report-ts-orchestrator` in **classify mode**:

```
MODE: classify
REPORT: <full report text>
PLATFORM: ios
DATA_PROPERTIES:
  date_range: <DATE_RANGE or empty>
  os_version: <OS_VERSION or empty>
  app_version: <APP_VERSION or empty>
  user_id: <USER_ID or empty>
  user_email: <USER_EMAIL or empty>
  company_id: <COMPANY_ID or empty>
FIREBASE_APP_ID: ios:co.talenta.ios
FIREBASE_DASHBOARD_URL: https://console.firebase.google.com/u/0/project/talenta-production/crashlytics/app/ios:co.talenta.ios/
GRAFANA_URL: <resolved via Loki MCP>
LOG_CACHE_REMOTE_CONFIG: mekari_log_cache_retention_validator
ENCRYPTED_ID_FORMAT: Talenta encrypted identifiers (user_id, user_email, company_id as encrypted strings)
ANR_APPLICABLE: false
```

Read the returned `Decision: classify` block. Extract `ISSUE_CLASS`, `CONFIDENCE`, and `DATA_SOURCE_PLAN`.

If `CONFIDENCE` < 95, ask:

> The issue looks like **<ISSUE_CLASS>** based on: <RATIONALE>. Does that match what was reported?

Adjust `ISSUE_CLASS` if the user corrects it.

Note: ANR is not a valid class on iOS. If the orchestrator returns `ANR`, reject it and re-classify as `Crash` or `other` before proceeding.

---

## Step 5 — Loki gate (run only if `DATA_SOURCE_PLAN.loki = true`)

Execute these checks in order. Do not proceed to Loki queries if either gate fails.

**Gate Check 1 — Remote config and app restart:**

Ask:

> Is the remote config `mekari_log_cache_retention_validator` enabled for this specific user? And has the user reopened the app at least once after it was enabled?
> (Both must be true before Loki logs are available.)

If NO to either condition:

> The Loki gate is not clear. Ask the user (TS requester) to:
> 1. Enable the remote config `mekari_log_cache_retention_validator` for the affected user.
> 2. Have the user fully close and reopen the Talenta app.
> 3. Reproduce the issue.
> Then come back and re-run this investigation.

**HOLD — do not proceed to any MCP queries.** Return control to the user.

**Gate Check 2 — Collect encrypted identifiers:**

Ask:

> Please provide the encrypted identifiers for this user to query Loki:
> - Encrypted `user_id`
> - Encrypted `user_email`
> - Encrypted `company_id`

Store as: `ENC_USER_ID`, `ENC_USER_EMAIL`, `ENC_COMPANY_ID`.

**If `ISSUE_CLASS = API` — pull generic error context first:**

Before spawning Loki agents, spawn `detective-debug-worker` with:

```
TASK: Locate the generic error message shown to the user and trace it to its API call origin.
REPORT: <REPORT>
SUSPECT_SCREEN: <SUSPECT_SCREEN if available>
PLATFORM: ios
MODE: static-only (do not instrument)
```

Store the returned code trace as `GENERIC_ERROR_CONTEXT`.

**Spawn Loki agents:**

Spawn `loki-log-query` with:

```
ENCRYPTED_USER_ID: <ENC_USER_ID>
ENCRYPTED_USER_EMAIL: <ENC_USER_EMAIL>
ENCRYPTED_COMPANY_ID: <ENC_COMPANY_ID>
DATE_RANGE: <DATE_RANGE>
SUSPECT_SCREEN: <SUSPECT_SCREEN if available>
GENERIC_ERROR_CONTEXT: <GENERIC_ERROR_CONTEXT if class=API, else omit>
```

If the issue involves GPS or live-tracking signals, also spawn `loki-live-tracking-query` with the same identifiers and date range.

Pipe results into `log-analyzer`:

```
LOKI_LOGS: <raw output from loki-log-query>
LIVE_TRACKING_LOGS: <raw output from loki-live-tracking-query, or omit>
ISSUE_CLASS: <ISSUE_CLASS>
REPORT: <REPORT>
```

Store the `log-analyzer` output as `LOKI_TIMELINE`.

---

## Step 6 — Crashlytics (run only if `DATA_SOURCE_PLAN.firebase = true`)

Spawn `detective-report-ts-crashlytics-worker` with:

```
FIREBASE_APP_ID: ios:co.talenta.ios
FIREBASE_DASHBOARD_URL: https://console.firebase.google.com/u/0/project/talenta-production/crashlytics/app/ios:co.talenta.ios/
ISSUE_CLASS: <ISSUE_CLASS>
DATE_RANGE: <DATE_RANGE>
OS_VERSION: <OS_VERSION>
APP_VERSION: <APP_VERSION>
USER_ID: <USER_ID>
USER_EMAIL: <USER_EMAIL>
COMPANY_ID: <COMPANY_ID>
SUSPECT_SCREEN: <SUSPECT_SCREEN if available>
```

Store the returned `## Crashlytics Findings` block as `CRASHLYTICS_FINDINGS`.

---

## Step 7 — Code trace

Spawn `detective-debug-worker` with all gathered evidence inlined:

```
TASK: Trace the root cause through CLEAN Architecture layers.
REPORT: <REPORT>
PLATFORM: ios
ISSUE_CLASS: <ISSUE_CLASS>
LOKI_TIMELINE: <LOKI_TIMELINE or "not gathered">
CRASHLYTICS_FINDINGS: <CRASHLYTICS_FINDINGS or "not gathered">
SUSPECT_SCREEN: <SUSPECT_SCREEN if available>
MODE: static-only (do not instrument)
```

Store the returned findings as `CODE_TRACE`.

---

## Step 8 — Consolidate

Spawn `detective-report-ts-orchestrator` in **consolidate mode**:

```
MODE: consolidate
REPORT: <REPORT>
ISSUE_CLASS: <ISSUE_CLASS>
LOKI_TIMELINE: <LOKI_TIMELINE or "not gathered">
CRASHLYTICS_FINDINGS: <CRASHLYTICS_FINDINGS or "not gathered">
CODE_TRACE: <CODE_TRACE>
```

Present the returned `Decision: consolidate` block to the user in a readable format:
- Full story
- Root causes (ranked)
- Fix options

---

## Step 9 — Choose a fix

Ask:

> Which fix would you like to apply?
> (List the options from the consolidate block, e.g. "Option A — <title>" / "Option B — <title>")

Wait for the user's choice.

---

## Step 10 — Apply fix

Spawn `detective-report-ts-fix-worker` with:

```
CHOSEN_FIX: <full text of the selected fix option>
ROOT_CAUSE: <corresponding root cause from the consolidate block>
CODE_TRACE_PATHS: <file paths from CODE_TRACE>
PLATFORM: ios
FEATURE_CONTEXT: <SUSPECT_SCREEN, ISSUE_CLASS, any relevant stack frames>
```

Present the `## Output` paths to the user when the worker completes.
