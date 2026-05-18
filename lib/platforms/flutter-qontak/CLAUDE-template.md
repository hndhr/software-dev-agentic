# CLAUDE.md

<!-- BEGIN software-dev-agentic:flutter-qontak -->
Flutter · Modular Clean Architecture · BLoC · get_it/injectable · melos

## Architecture

Module structure: `.claude/reference/project.md`
Layer patterns (entity, BLoC, mapper, etc.): `.claude/reference/../../flutter/reference/`

## Principles

Clean Architecture · DRY · SOLID — apply to all new code.

**Layer dependency rule:** Presentation → Domain ← Data. Domain depends on nothing.

**Module dependency rule:** App → Feature → Core → Dependencies.
Feature modules must NOT depend on each other — use Module API pattern via core.

## Workflow

Use trigger skills as entry points — `/builder-build-feature`, `/auditor-arch-review`, `/detective-debug`, etc.

**Feature work → always start with `/builder-build-feature`, never inline.**
<!-- END software-dev-agentic:flutter-qontak -->
