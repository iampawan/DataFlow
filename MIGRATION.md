# Migration Guide: v1.x to v2.0

This guide helps you upgrade from DataFlow v1.x to v2.0.

## Quick Summary

| Change | v1.x | v2.0 | Action Required |
|--------|------|------|-----------------|
| `actions` parameter | Optional (`Set<Type>?`) | Required (`Set<Type>`) | Remove null checks |
| `errorBuilder` type | `Exception` | `Object` | Update signature |
| `DataAction.error` | `Exception?` | `Object?` | Update type annotations |
| `areAllActionsSuccessful` | `true` when empty | `false` when empty | Check logic |
| Loading for sync actions | Skipped | Always emitted | May see loading flash |

## Step-by-Step Migration

### 1. Update `DataSync.actions` (Required Change)

**Before (v1.x):**
```dart
DataSync<MyStore>(
  actions: null, // or could be nullable
  builder: (context, store, hasData) => ...,
)
```

**After (v2.0):**
```dart
DataSync<MyStore>(
  actions: {}, // Empty set if no actions, or actual actions
  builder: (context, store, hasData) => ...,
)
```

**Search & Replace:** Look for `actions: null` and replace with `actions: {}` or the appropriate action set.

---

### 2. Update `errorBuilder` Signature (If Used)

**Before (v1.x):**
```dart
DataSync<MyStore>(
  actions: {MyAction},
  errorBuilder: (BuildContext context, Exception error) {
    return Text('Error: $error');
  },
  builder: ...,
)
```

**After (v2.0):**
```dart
DataSync<MyStore>(
  actions: {MyAction},
  errorBuilder: (BuildContext context, Object error) {
    return Text('Error: $error');
  },
  builder: ...,
)
```

**Search & Replace:** Find `Exception error` in errorBuilder and change to `Object error`.

---

### 3. Update `DataAction.error` Type References (If Accessing Directly)

**Before (v1.x):**
```dart
class MyMiddleware extends DataMiddleware {
  @override
  void postDataAction(DataAction action) {
    final Exception? error = action.error;
    // ...
  }
}
```

**After (v2.0):**
```dart
class MyMiddleware extends DataMiddleware {
  @override
  void postDataAction(DataAction action) {
    final Object? error = action.error;
    // Can also access stack trace now:
    final StackTrace? stackTrace = action.errorStackTrace;
    // ...
  }
}
```

---

### 4. Check `areAllActionsSuccessful` Usage (Behavioral Change)

**v1.x Behavior:**
```dart
// When no actions have run yet:
dataSyncState.areAllActionsSuccessful // Returns: true (empty.every() == true)
```

**v2.0 Behavior:**
```dart
// When no actions have run yet:
dataSyncState.areAllActionsSuccessful // Returns: false (requires non-empty)
```

**Action:** If your code relies on `areAllActionsSuccessful` returning `true` before any actions run, update your logic:

```dart
// If you need the old behavior:
final allSuccess = dataSyncState.allActionsStatus.isEmpty ||
                   dataSyncState.areAllActionsSuccessful;
```

---

### 5. Loading State for Synchronous Actions (Behavioral Change)

**v1.x:** Synchronous actions went directly from `idle` to `success`, skipping `loading`.

**v2.0:** All actions emit `loading` first, then `success`/`error`.

**Action:** If you have synchronous actions and tests that check for immediate success, they may now briefly show loading state. This is usually desired behavior but may require test updates.

---

## New Features to Adopt (Optional)

### Action Cancellation

```dart
final action = MyLongRunningAction();

// Later, if user navigates away:
action.cancel();

// Check if cancelled:
if (action.isCancelled) {
  // Handle cancellation
}

// In DataSyncState:
if (dataSyncState.isAnyActionCancelled) {
  // Handle cancelled state
}
```

### Await Action Completion

```dart
final action = FetchDataAction();
await action.future; // Wait for action to complete
print('Action finished with status: ${action.status}');
```

### Stack Trace Access

```dart
// On action:
if (action.error != null) {
  print('Error: ${action.error}');
  print('Stack trace: ${action.errorStackTrace}');
}

// On DataSyncState:
final stackTrace = dataSyncState.getStackTrace(MyAction);
final firstStackTrace = dataSyncState.firstActionStackTrace;
```

---

## Automated Migration Script

Run this in your project to find files that need updates:

```bash
# Find files using nullable actions
grep -r "actions: null" --include="*.dart" lib/

# Find errorBuilder with Exception type
grep -r "Exception error" --include="*.dart" lib/

# Find direct error type access
grep -r "action\.error" --include="*.dart" lib/

# Find areAllActionsSuccessful usage
grep -r "areAllActionsSuccessful" --include="*.dart" lib/
```

---

## Testing Your Migration

1. **Run static analysis:**
   ```bash
   flutter analyze
   ```

2. **Run tests:**
   ```bash
   flutter test
   ```

3. **Check for runtime issues:** The changes are mostly compile-time, but watch for:
   - Loading spinners appearing briefly for previously-instant actions
   - Logic depending on `areAllActionsSuccessful` being `true` initially

---

## Rolling Back

If you encounter issues, you can stay on v1.6.0:

```yaml
dependencies:
  dataflow: ^1.6.0  # Stable v1.x
```

---

## Getting Help

- **GitHub Issues:** https://github.com/iampawan/DataFlow/issues
- **Documentation:** https://learn.codepur.dev/dataflow
