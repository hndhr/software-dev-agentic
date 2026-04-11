# CLAUDE.md

**[AppName]** — [One-line description]. Swift/UIKit, Clean Architecture + MVVM-Coordinator, RxSwift. Min iOS [version].

## Architecture

New code: `[App]/Shared/` or `[App]/Module/` — never legacy `Models/`, `Controllers/`, `ViewModels/`
Details: `.claude/reference/` · Tests: `[App]Tests/Module/[Feature]/` · Mocks: `[App]Tests/Mock/Module/[Module]/`

## Principles

Clean Architecture · DRY · SOLID — apply to all new code.

## Key Rules

- **Mappers**: `Data/Mapper/` · **UseCase params**: `UseCase.Params` nested struct · **Protocol**: conform to `UseCaseProtocol`
- **Call chain**: ViewModels → UseCases → Repositories (never skip)
- **DI**: lazy properties in per-module DIContainer (`.claude/reference/di.md`)
- **Optional unwrapping**: `.orEmpty()` / `.orZero()` / `.orFalse()` — never `?? ""` / `?? 0`
- **Closures**: always `weak self` · **No comments** unless requested

## Naming

`[HttpMethod][Feature]UseCase` · `[Feature]Repository/RepositoryImpl` · `[Feature]Model/Response/ModelMapper` · Mock: `[OriginalClassName]Mock` with `calledCount`, `reset()`

## Build

```bash
xcodebuild -project [App].xcodeproj -scheme [App] -configuration Debug -destination 'platform=iOS Simulator,name=[Device],arch=x86_64' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "^/.*\.(swift|m|h):[0-9]+:[0-9]+: (error|warning):"
```

<!-- BEGIN software-dev-agentic:ios -->
## Workflow
Before any work, invoke the **issue-worker** agent with a title (new) or number (existing).

```
issue-worker "add X"   → create GH issue + branch + backlog row
issue-worker 42        → pick up existing GH issue + branch + backlog row
```

Agents: `feature-orchestrator` · `backend-orchestrator` · `pres-orchestrator` · `debug-worker` · `test-worker` · `arch-review-worker` · `.claude/skills/`

Issue rule: On `fix/`|`feat/` branch → add feedback to current issue. On `main` → create new issue.

## Code Principles
CLEAN · DRY · SOLID (SRP, OCP, LSP, ISP, DIP). Wire deps via per-module DIContainer (Needle).
<!-- END software-dev-agentic:ios -->
