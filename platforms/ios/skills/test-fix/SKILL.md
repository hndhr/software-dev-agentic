---
name: test-fix
description: |
  Diagnose and fix failing ViewModel tests. Never modifies production code — test/mock files only.
user-invocable: false
---

Fix failing tests following patterns in `.claude/reference/testing-patterns.md`.

## Critical Constraint

**Never modify production ViewModel code** to make tests pass. Fix only test files and mock files. If a failure reveals a genuine ViewModel bug, report it to the user.

## Steps

1. **Read** `.claude/reference/testing-patterns.md` (failure diagnosis section)
2. **Get failure output** — ask user to paste `xcodebuild` output if not provided:
   ```bash
   xcodebuild test -project Talenta.xcodeproj -scheme Talenta \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,arch=x86_64' \
     CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "(error:|FAILED|XCTAssert)"
   ```
3. **Diagnose** each failure using the 4 failure types
4. **Fix** in two phases if needed

## Two-Phase Compilation Fix

**Phase 3A — Isolate compilation errors:**
Comment out failing tests one by one until the file compiles:
```swift
// func testFailing() { ... } // ← commented out temporarily
```

**Phase 3B — Fix each commented-out test:**
- Missing mock method → add to mock
- Wrong param type → update call site
- Removed State field → update assertion
- Changed Action case → update switch

## 4 Failure Types & Fixes

| Failure | Symptom | Fix |
|---------|---------|-----|
| Call count mismatch | `callCount == 0` when expecting 1 | Guard not passing → add missing mock setup |
| State mismatch | wrong value in `capturedStates.last?.field` | Check `.createMock()` default; check state update path |
| Wrong mock value | result goes to wrong branch | Extend `mockResult` array, fix call order |
| Array index OOB | mock returns `.failure(.unknown)` unexpectedly | Add more entries to `mockResult` |

## Edge Cases

- **Test reveals ViewModel bug**: Report the bug to the user, don't work around it in tests
- **Ambiguous failure**: Multiple plausible causes → fix the most likely, note alternatives
- **Race condition**: Non-deterministic failure → check `testScheduler` usage, ensure `.start()` called after subscriptions

## Output

List each fixed test with the failure type, root cause, and fix applied. Flag any failures that indicate real ViewModel bugs.
