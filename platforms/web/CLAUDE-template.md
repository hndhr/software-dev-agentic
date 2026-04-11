# CLAUDE.md

**[AppName]** — [One-line description of what the app does].
Stack: Next.js 15 App Router + React 19 · [Database, e.g. PostgreSQL · Supabase] · [ORM, e.g. Drizzle · Prisma] · [Auth, e.g. Supabase Auth · NextAuth · Clerk] · [UI, e.g. Tailwind + shadcn/ui] · [Tests, e.g. Vitest]

## Dev Commands
```bash
npm run dev | build | lint | test
[ORM push command, e.g. npx drizzle-kit push OR npx prisma db push]
[ORM studio command if available, e.g. npx drizzle-kit studio]  # DB browser (optional)
```

## Structure
Feature slices: `src/features/{auth,[feature-a],[feature-b],...}` · `src/shared/{domain,presentation,core,di}` · `src/lib/` · `src/app/`
Arch docs: `.claude/reference/` · DI/arch rules: `.claude/docs/`

<!-- BEGIN software-dev-agentic -->
## Workflow
Before any work, invoke the **issue-worker** agent with a title (new) or number (existing).

```
issue-worker "add X"   → create GH issue + branch + backlog row
issue-worker 42        → pick up existing GH issue + branch + backlog row
```

Agents: `feature-orchestrator` · `backend-orchestrator` · `debug-worker` · `test-worker` · `arch-review-worker` · `/simplify` · `.claude/skills/`

Issue rule: On `fix/`|`feat/` branch → add feedback to current issue. On `main` → create new issue.

## Code Principles
CLEAN · DRY · SOLID (SRP, OCP, LSP, ISP, DIP). Wire deps via `src/shared/di/`.
<!-- END software-dev-agentic -->
