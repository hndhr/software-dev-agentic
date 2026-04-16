# CLAUDE.md

<!-- BEGIN software-dev-agentic:flutter -->
Flutter · Clean Architecture + BLoC · get_it/injectable

## Architecture

Module structure and path conventions: `.claude/reference/`

## Principles

Clean Architecture · DRY · SOLID — apply to all new code.

**Layer dependency rule:** Presentation → Domain ← Data. Domain depends on nothing.

## Workflow

Agents: `feature-orchestrator` · `pres-orchestrator` · `domain-worker` · `data-worker` · `presentation-worker` · `ui-worker` · `test-worker` · `.claude/skills/`

**Feature work (create or update, any scope) → always delegate to `feature-orchestrator`, never inline.**

**If the delegation guard hook blocks an edit → always stop and ask the user: inline or `feature-orchestrator`? Never resolve it autonomously.**
<!-- END software-dev-agentic:flutter -->
