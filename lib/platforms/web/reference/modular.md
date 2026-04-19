# Web — Modular Architecture


This starter kit scales from a single Next.js app to a Turborepo mono-repo with independently deployable packages.

## When to Modularize

| Signal | Action |
|--------|--------|
| 1-3 developers, <20 screens | Single Next.js app — keep it simple |
| 3-8 developers, 20-50 screens | Extract shared `packages/core` + `packages/ui` |
| 8+ developers, 50+ screens | Full Turborepo with per-feature packages or micro-frontends |

Don't modularize prematurely. Start with a single `src/` structure and extract packages when build times or team conflicts become real problems.

## Module Structure (Turborepo)

```
starterkit/                          # Turborepo root
├── apps/
│   └── web/                         # Next.js app (thin — just wiring and pages)
│       ├── app/                     # Next.js App Router pages/layouts
│       ├── di/                      # Root DI container (imports all feature packages)
│       └── package.json
│
├── packages/
│   ├── core/                        # Shared domain types, utilities
│   │   ├── src/
│   │   │   ├── entities/            # Shared entities (Employee, Department, etc.)
│   │   │   ├── errors/              # DomainError
│   │   │   └── utils/               # nullSafety, dateService, etc.
│   │   └── package.json
│   │
│   ├── networking/                  # HTTP client, interceptors
│   │   ├── src/
│   │   │   ├── AxiosHTTPClient.ts   # createHTTPClient / createUnauthenticatedHTTPClient
│   │   │   ├── TokenProvider.ts     # TokenProvider, TokenRefresher, TokenStorage
│   │   │   ├── TokenRefreshService.ts
│   │   │   └── NetworkError.ts
│   │   └── package.json
│   │
│   ├── ui/                          # Shared UI components (design system)
│   │   ├── src/
│   │   │   ├── LoadingView.tsx
│   │   │   ├── ErrorView.tsx
│   │   │   ├── EmptyStateView.tsx
│   │   │   └── tokens/              # Colors, typography, spacing
│   │   └── package.json
│   │
│   ├── feature-employee/            # Employee feature package
│   │   ├── src/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/    # Interfaces only
│   │   │   │   ├── use-cases/
│   │   │   │   └── services/
│   │   │   ├── data/
│   │   │   │   ├── dtos/
│   │   │   │   ├── mappers/
│   │   │   │   ├── data-sources/
│   │   │   │   └── repositories/    # Implementations
│   │   │   └── presentation/
│   │   │       ├── EmployeeListView.tsx
│   │   │       ├── useEmployeeListViewModel.ts
│   │   │       ├── EmployeeDetailView.tsx
│   │   │       └── useEmployeeDetailViewModel.ts
│   │   └── package.json
│   │
│   ├── feature-leave/               # Leave feature package
│   │   ├── src/
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   └── package.json
│   │
│   └── feature-auth/                # Auth feature package
│       ├── src/
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       └── package.json
│
└── turbo.json
```

## Package Dependencies

```
App (web) → feature-employee, feature-leave, feature-auth, ui
feature-employee → core, networking, ui
feature-leave → core, networking, ui
feature-auth → core, networking, ui
networking → core
ui → (none — just React)
core → (none)
```

**Rule:** Feature packages never depend on each other. Cross-feature communication goes through the App layer or shared interfaces in `core`.

## Package Configuration

```json
// packages/feature-employee/package.json
{
  "name": "@starterkit/feature-employee",
  "version": "0.0.1",
  "main": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "dependencies": {
    "@starterkit/core": "workspace:*",
    "@starterkit/networking": "workspace:*",
    "@starterkit/ui": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.5.0"
  }
}
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": [".next/**", "dist/**"] },
    "test": { "dependsOn": ["^build"] },
    "lint": {}
  }
}
```

## Feature Module Public API

Each feature package exposes a **public interface** — views, hooks, and a factory. Internal implementation details stay unexported.

```typescript
// packages/feature-employee/src/index.ts
// Public API — only export what consumers need

// Views
export { EmployeeListView } from './presentation/EmployeeListView';
export { EmployeeDetailView } from './presentation/EmployeeDetailView';

// Hooks (for when the app needs to compose its own UI)
export { useEmployeeListViewModel } from './presentation/useEmployeeListViewModel';

// Types that consumers need
export type { GetEmployeesUseCase } from './domain/use-cases/GetEmployeesUseCase';
export type { EmployeeRepository } from './domain/repositories/EmployeeRepository';

// Factory for DI wiring at the app level
export { createEmployeeFeatureDI } from './di/EmployeeFeatureDI';
```

```typescript
// packages/feature-employee/src/di/EmployeeFeatureDI.ts
// Internal DI — not part of the public API pattern, but exported for app-level wiring

import { HTTPClient } from '@starterkit/networking';
import { EmployeeRemoteDataSourceImpl } from '../data/data-sources/EmployeeRemoteDataSourceImpl';
import { EmployeeRepositoryImpl } from '../data/repositories/EmployeeRepositoryImpl';
import { GetEmployeesUseCaseImpl } from '../domain/use-cases/GetEmployeesUseCase';

export function createEmployeeFeatureDI(httpClient: HTTPClient) {
  const remoteDataSource = new EmployeeRemoteDataSourceImpl(httpClient);
  const repository = new EmployeeRepositoryImpl(remoteDataSource);

  return {
    get getEmployeesUseCase() { return new GetEmployeesUseCaseImpl(repository); },
    get getEmployeeUseCase() { return new GetEmployeeUseCaseImpl(repository); },
    get deleteEmployeeUseCase() { return new DeleteEmployeeUseCaseImpl(repository); },
  };
}
```

## App-Level Composition

The main app wires feature packages together:

```typescript
// apps/web/di/container.server.ts
import 'server-only';
import { createHTTPClient, createUnauthenticatedHTTPClient } from '@starterkit/networking';
import { TokenRefreshService } from '@starterkit/networking';
import { ServerTokenStorage } from '@starterkit/core';
import { createEmployeeServerDI } from '@starterkit/feature-employee';
import { createLeaveServerDI } from '@starterkit/feature-leave';

const tokenStorage = new ServerTokenStorage();
const unauthClient = createUnauthenticatedHTTPClient(process.env.API_BASE_URL!);
const tokenRefresher = new TokenRefreshService(unauthClient, tokenStorage);
const httpClient = createHTTPClient(process.env.API_BASE_URL!, tokenStorage, tokenRefresher);

export const { getEmployeesUseCase, getEmployeeUseCase } = createEmployeeServerDI(httpClient);
export const { getLeaveEntitlementUseCase } = createLeaveServerDI(httpClient);
```

```typescript
// apps/web/di/container.client.ts
import 'client-only';
import { createHTTPClient, createUnauthenticatedHTTPClient } from '@starterkit/networking';
import { TokenRefreshService } from '@starterkit/networking';
import { LocalStorageTokenProvider } from '@starterkit/core';
import { createEmployeeClientDI } from '@starterkit/feature-employee';
import { createLeaveClientDI } from '@starterkit/feature-leave';

export function createClientContainer() {
  const tokenStorage = new LocalStorageTokenProvider();
  const unauthClient = createUnauthenticatedHTTPClient(process.env.NEXT_PUBLIC_API_BASE_URL!);
  const tokenRefresher = new TokenRefreshService(unauthClient, tokenStorage);
  const httpClient = createHTTPClient(process.env.NEXT_PUBLIC_API_BASE_URL!, tokenStorage, tokenRefresher);

  return {
    ...createEmployeeClientDI(httpClient),
    ...createLeaveClientDI(httpClient),
  };
}
```

## Cross-Feature Communication

Features don't depend on each other. When they need to communicate:

**Option 1: Shared interfaces in `core` (preferred)**
```typescript
// packages/core/src/protocols/EmployeeProvider.ts
export interface EmployeeProvider {
  getEmployee(id: string): Promise<Employee>;
}

// feature-leave can depend on EmployeeProvider without depending on feature-employee
// App layer wires the real implementation
```

**Option 2: URL / search params**
```typescript
// feature-leave navigates to employee picker without knowing about feature-employee internals
router.push(`${ROUTES.employeeDetail(id)}?returnTo=${ROUTES.leaveRequest}`);
```

**Option 3: Shared Zustand store in `core`**
```typescript
// packages/core/src/stores/selectionStore.ts
export const useEmployeeSelectionStore = create<...>(...);
// Both features import this store — no direct dependency on each other
```

## Benefits at Scale

| Benefit | How |
|---------|-----|
| **Parallel builds** | Turborepo builds feature packages in parallel |
| **Isolated testing** | `turbo test --filter=@starterkit/feature-employee` |
| **Team ownership** | Team A owns feature-employee, Team B owns feature-leave |
| **Enforced boundaries** | TypeScript `exports` in `package.json` prevent accidental coupling |
| **Incremental adoption** | Start single `src/`, extract packages one feature at a time |

---
