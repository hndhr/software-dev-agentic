# Skills

Focused, reusable workflow procedures. Each skill does one thing only.

Copy to `.claude/skills/` in the actual project (or symlink via submodule).

## Skill Types

| Type | Config | Who triggers | Context cost | Use for |
|------|--------|-------------|-------------|---------|
| **A — Internal** | `user-invocable: false` | Workers only | Zero | Standard scaffolding procedures |
| **B — User-triggered** | `disable-model-invocation: true` | User only | Zero | Destructive or side-effect operations |

## Type A — Internal Procedures (called by workers)

### Domain layer
| Skill | What it does |
|-------|-------------|
| `domain-create-entity` | Create a domain entity interface |
| `domain-create-usecase` | Create a use case interface + implementation |
| `domain-create-repository` | Create a domain repository interface |
| `domain-create-service` | Create a pure domain service |
| `domain-update-usecase` | Update an existing use case |

### Data layer
| Skill | What it does |
|-------|-------------|
| `data-create-mapper` | Create a DTO + mapper (interface + Impl) |
| `data-create-datasource` | Create a remote data source interface + Axios impl |
| `data-create-repository-impl` | Create a remote repository implementation |
| `data-update-mapper` | Update an existing mapper after Entity or DTO changes |
| `data-create-db-datasource` | Create a DB record, DB data source interface + ORM stub impl |
| `data-create-db-repository` | Create a DB mapper + DB repository implementation |

### Presentation layer
| Skill | What it does |
|-------|-------------|
| `pres-create-stateholder` | Create a StateHolder hook or pure function |
| `pres-create-screen` | Create a View component + App Router page |
| `pres-update-stateholder` | Update an existing StateHolder |
| `pres-create-component` | Create a reusable UI sub-component |
| `pres-update-screen` | Update an existing View component |
| `pres-create-server-action` | Create a next-safe-action Server Action |
| `pres-wire-di` | Wire use case and deps into DI containers |
| `pres-ssr-check` | Determine Server vs Client Component decision |

### Test layer
| Skill | What it does |
|-------|-------------|
| `test-create-mock` | Scaffold a Mock class with vi.fn() for every interface method |
| `test-create-domain` | Unit tests for use cases and domain services |
| `test-create-data` | Mapper unit tests + repository integration tests |
| `test-create-presentation` | StateHolder hook tests + View component tests |
| `test-update` | Update existing tests after StateHolder code changes |
| `test-fix` | Diagnose and fix failing tests |

## Type B — User-Triggered (explicit invocation only)

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `create-issue` | `/create-issue` | Create GitHub Issue + git branch + backlog entry |
| `pickup-issue` | `/pickup-issue NNN` | Pick up a PM-created GitHub Issue |
| `setup-nextjs-project` | `/setup-nextjs-project` | Wire submodule + symlinks for a new project |
| `release` | `/release` | Cut a new version — bumps VERSION, updates CHANGELOG, tags |
