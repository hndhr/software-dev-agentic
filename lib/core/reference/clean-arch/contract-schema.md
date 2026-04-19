# Contract Reference Schema

Each file under `lib/platforms/<platform>/reference/contract/` must contain all required section headings listed below. The **canonical keyword** is the grep-able string that must appear verbatim as a substring of at least one `##` or `###` heading in the file.

Platforms may use different section numbers, add platform-specific sections, and adapt content to their syntax — but every required keyword must be grep-able.

## How to validate

```bash
# Check one file — exits non-zero if any keyword is missing
for keyword in "Entities" "Repository" "Use Cases" "Domain Errors"; do
  grep -q "$keyword" lib/platforms/web/reference/contract/domain.md \
    || echo "MISSING: $keyword"
done
```

`arch-check-conventions` enforces this automatically for all three platforms.

---

## domain.md

| Canonical keyword | Concept |
|---|---|
| `Entities` | Domain entity definitions |
| `Repository` | Repository interface/protocol |
| `Use Cases` | UseCase definitions and patterns |
| `Domain Errors` | Domain-level error type |

---

## data.md

| Canonical keyword | Concept |
|---|---|
| `DTOs` | Data Transfer Objects / response models |
| `Mappers` | DTO → Entity mapping |
| `Data Sources` | DataSource abstraction and implementation |
| `Repository Impl` | Repository implementation (bridges DataSource → Domain) |

---

## presentation.md

| Canonical keyword | Concept |
|---|---|
| `State` | State container (ViewModel, BLoC state, ViewDataState) |
| `Shared Component Paths` | Canonical file paths for reusable UI components on this platform |

---

## navigation.md

| Canonical keyword | Concept | Notes |
|---|---|---|
| `Route Constants` | Named route definitions | Web and Flutter |
| `Navigator` OR `Coordinator` | Navigation pattern entry point | iOS (Coordinator pattern has no route constants) |

At least one of the three keywords must be present.

---

## di.md

| Canonical keyword | Concept |
|---|---|
| `DI Principles` | Core DI rules that apply regardless of framework |

---

## testing.md

| Canonical keyword | Concept |
|---|---|
| `Test Pyramid` | Layer distribution — unit heavy, integration light, e2e minimal |
| `Repository Tests` | How to test repository implementations |
| `Mapper Tests` | How to test DTO → Entity mappers |

---

## error-handling.md

| Canonical keyword | Concept |
|---|---|
| `Error Flow` | Layer-by-layer error propagation diagram |
| `Error Types` | Platform error type definitions (DomainError, BaseErrorModel, Failure) |
| `Error Mapping` | How errors are converted between layers |
| `Error UI` | How errors are surfaced to users in the UI layer |

---

## utilities.md

| Canonical keyword | Concept |
|---|---|
| `StorageService` | Key-value storage abstraction |
| `DateService` | Date formatting and parsing |
| `Logger` | Structured logging |
| `Null Safety` | Null/optional fallback utilities |

---

## Adding a new platform

When adding a 4th platform:
1. Create `lib/platforms/<platform>/reference/contract/` with all 8 files
2. Each file must contain the required keywords above
3. Run `arch-check-conventions` on the new platform's contract directory to verify compliance before merging
