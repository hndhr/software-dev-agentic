---
name: builder-groom-ticket
description: Groom a locally fetched Jira ticket against the codebase — maps acceptance criteria to CLEAN layers, identifies work items and open questions, then updates the ticket via tracker-adjust-ticket. Run before /builder-plan-feature.
user-invocable: true
allowed-tools: Agent, AskUserQuestion, Read
---

## Arguments

`$ARGUMENTS` — optional path to the local ticket `.md` file.

## Step 1 — Resolve Ticket Path

If `$ARGUMENTS` is provided, use it as the ticket path.

If `$ARGUMENTS` is empty, call `AskUserQuestion`:

```
question    : "What is the path to your local ticket file? (e.g. /path/to/TICKET-123.md)"
header      : "Ticket path"
multiSelect : false
options     :
  - label: "Enter path", description: "Provide the absolute path to the ticket .md file"
```

Verify the file exists before continuing. If it does not exist, report the path and stop.

## Step 2 — Load Ticket Content

Read the ticket file at the resolved path. This is the only file read this skill performs directly.

## Step 3 — Spawn groom-orchestrator

Spawn `builder-groom-orchestrator` with the following prompt:

> **ticket-path:** <resolved absolute path>
>
> **ticket-content:**
> <full content of the ticket file>
>
> Groom this ticket against the codebase. Follow your phases in order.
