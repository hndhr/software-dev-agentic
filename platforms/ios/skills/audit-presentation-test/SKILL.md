---
name: audit-presentation-test
description: |
  Generate comprehensive unit tests for a StateHolder *(iOS: ViewModel)* from scratch using ViewModelTestGen, or regenerate tests after major StateHolder changes. Use when asked to create, audit, or bootstrap StateHolder test coverage.
disable-model-invocation: true
---

## Architecture Rule

**New code → V2 patterns always. Existing code → keep its current pattern. Never migrate unless explicitly asked.**

# Audit and Generate StateHolder *(iOS: ViewModel)* Test

Automatically generate comprehensive unit tests for ViewModels using the ViewModelTestGen tool.

## When to Use

- Creating tests for a new ViewModel inheriting from `BaseViewModelV2`
- Regenerating tests after major ViewModel changes
- Quickly bootstrapping test coverage for existing ViewModels

## Tool Location

- **Tool**: `scripts/ViewModelTestGen/`
- **Shell Wrapper**: `scripts/viewmodel-testgen.sh`
- **Config Output**: `scripts/viewmodel-testgen-config/`

## Automated Workflow

This skill will automatically:

1. Auto-detect ViewModel file from context or user request
2. Create test target file if missing
3. Execute audit with intelligent call-depth (default: 5)
4. Monitor audit progress in background (30+ min duration)
5. Review generated audit config
6. Handle any errors automatically
7. Execute generate command
8. Analyze generated test file
9. Provide comprehensive final report with TODOs

## Prerequisites

### 1. Test Target File

The tool requires an existing test file to function. If missing, it will be auto-created:

```swift
// TalentaTests/Module/[Module]/Presentation/[ViewModel]Test.swift
import XCTest
@testable import Talenta

final class [ViewModel]Test: XCTestCase {
}
```

**Location**: Match the ViewModel's module structure:
- ViewModel: `Talenta/Module/[Module]/Presentation/ViewModel/[ViewModel].swift`
- Test: `TalentaTests/Module/[Module]/Presentation/[ViewModel]Test.swift`

### 2. Mock Implementations

Ensure all dependency mocks exist in `TalentaTests/Mock/` following the Mock Guidelines with:
- `reset()` method
- Call tracking properties (`callCount`, parameters)
- Array-based results (`mockResult: [Result<...>]`)
- Proper parameter tracking

### 3. Entity Mock Extensions

Create `.createMock()` extensions for all entities used in the ViewModel.

## Execution Steps

### Phase 1: Audit (30+ minutes)

```bash
./scripts/viewmodel-testgen.sh audit \
  --input [ViewModel_File_Path] \
  --call-depth 5
```

The audit runs in background and generates a config file with:
- Detected events and branches
- Required dependencies and mocks
- Generated test cases with setup hints
- Expected states and actions

### Phase 2: Generate (1-2 seconds)

```bash
./scripts/viewmodel-testgen.sh generate \
  --input [ViewModel_File_Path]
```

This overwrites the test file with:
- Complete test class structure
- Mock setup code
- Test methods for all events and branches
- TODO markers for manual completion

### Phase 3: Complete TODOs

The generated test file contains TODO markers for:

1. **Mock Default Behaviors**: Configure default mock return values in `setupMocks()`
2. **Mock Setup Hints**: Adjust mock results for specific test scenarios
3. **State Assertions**: Add `XCTAssert` calls for state changes
4. **Action Assertions**: Verify emitted actions

## Parameters

### Audit Options

- `--input <file>`: ViewModel file to audit (required)
- `--call-depth <n>`: Method traversal depth (default: 3, recommended: 5)
- `--output-dir <dir>`: Config output directory (default: `scripts/viewmodel-testgen-config`)

### Generate Options

- `--input <file>`: ViewModel file (auto-finds audit config)
- `--config <file>`: Explicit audit config path
- `--output <file>`: Custom output location (default: overwrites test file)

## Common Issues

### Audit Takes Too Long
- Reduce call depth: `--call-depth 2`
- Audit single ViewModel instead of bulk scan
- Check for circular method calls

### Test File Not Found
- Create empty test file first (auto-created by this skill)
- Ensure correct naming: `[ViewModel]Test.swift`

### Mock Not Found
- Create mocks following Mock Guidelines
- Add to `TalentaTests/Mock/Module/[Module]/`

### Compilation Errors
- Missing imports: Add required imports manually
- Wrong mock type: Update audit config
- Entity mock missing: Create `.createMock()` extension

### Low Coverage
- Increase call depth: `--call-depth 6`
- Add manual tests for paths not detected
- Verify mock setups exercise all branches

## Next Steps After Generation

1. Complete all TODO markers in the test file
2. Verify test compilation (build test target)
3. Run tests and verify they pass
4. Check coverage (target: 90%)
5. Commit both files:
   - Test file: `TalentaTests/Module/[Module]/Presentation/[ViewModel]Test.swift`
   - Audit config: `scripts/viewmodel-testgen-config/[ViewModel].audit.json`

## Advanced Usage

### Custom Call Depth for Complex ViewModels

```bash
./scripts/viewmodel-testgen.sh audit \
  --input Talenta/Module/TalentaTM/Presentation/ViewModel/ComplexViewModel.swift \
  --call-depth 8
```

### Preview Without Overwriting

```bash
./scripts/viewmodel-testgen.sh generate \
  --input [ViewModel_File_Path] \
  --output /tmp/preview.swift
```

### Incremental Updates After ViewModel Changes

```bash
# Re-audit
./scripts/viewmodel-testgen.sh audit --input [ViewModel_File_Path]

# Regenerate
./scripts/viewmodel-testgen.sh generate --input [ViewModel_File_Path]
```

## Related Guidelines

- ViewModel structure and patterns
- ViewModel testing patterns
- Mock creation guidelines
- RxSwift testing best practices
