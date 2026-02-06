## 2.0.0-beta.5 (2025-02-06)

### Bug Fixes
- Fixed deprecated `withOpacity` warnings by migrating to `withValues(alpha:)`

---

## 2.0.0-beta.4 (2025-02-06)

### New Features - DataFlow Inspector 🔍

A powerful visual debugging tool for DataFlow applications.

- **Actions Panel** - Real-time view of all dispatched actions with status (loading/success/error/cancelled)
- **Time Travel Debugging** - Step through state snapshots captured after each action completes
- **Insights Panel** - Automatic detection of:
  - Slow actions (>5s)
  - Rapid-fire action calls (potential debounce needed)
  - Repeated failures
  - Excessive widget rebuilds
- **Retry/Replay Actions** - Re-run failed or successful actions directly from inspector
- **Bug Report Capture** - Screenshot + state + action history export
- **State Popup** - Tap any DataSync widget to inspect its state and subscribed actions

### New APIs

- `DataFlowInspector` widget - Wrap your `MaterialApp` to enable visual debugging
- `Retryable<T>` mixin - Add to actions to enable retry/replay from inspector
- `RetryableAction` interface - Non-generic base for runtime type checking

### Inspector Usage

```dart
DataFlowInspector(
  enabled: true, // Disable in production
  child: MaterialApp(...),
)
```

### Retryable Actions

```dart
class LoadDataAction extends DataAction<AppStore> with Retryable<AppStore> {
  @override
  DataAction<AppStore> retry() => LoadDataAction();

  @override
  Future<void> execute() async { ... }
}
```

### Bug Fixes

- Fixed action tracking for concurrent actions of same type
- Fixed duplicate loading entries when `DataFlow.notify()` called multiple times
- Fixed `SelectableText` overlay error in inspector (replaced with `Text`)
- Fixed `ScaffoldMessenger` not found error in bug report dialog

### Documentation

- Added `DATAFLOW.md` - Comprehensive LLM context file for Claude Code, Cursor, etc.
- Complex real-world example app with auth, feed, search, notifications, and settings

---

## 2.0.0-beta.2 (2025-02-06)

### Documentation
- Complete rewrite of README with comprehensive documentation
- Added table of contents for easy navigation
- Added "Why DataFlow?" section with design principles
- Step-by-step Quick Start guide
- Detailed Core Concepts explanations
- Three complete guides: Todo App, Authentication Flow, Pagination
- Advanced Features section: Middleware, Chaining, Cancellation, Reset
- Comparison table with Bloc, Provider, Riverpod, GetX
- Complete API Reference tables
- Best Practices section with code examples
- FAQ section
- Migration guide reference

## 2.0.0-beta.1 (2025-02-06)

### Breaking Changes

See [MIGRATION.md](MIGRATION.md) for detailed upgrade guide.

- **`DataSync.actions` is now required** - Previously nullable, now must be provided
- **`errorBuilder` signature changed** - Now receives `Object` instead of `Exception`
- **`DataAction.error` type changed** - Now `Object?` instead of `Exception?`
- **`areAllActionsSuccessful` behavior changed** - Returns `false` when empty (was `true`)
- **Loading state always emitted** - Even for synchronous actions

### New Features
- **Action Cancellation** - Call `action.cancel()` to cancel running actions
- **New `cancelled` status** - `DataActionStatus.cancelled` for cancelled actions
- **Stack trace support** - `errorStackTrace` on actions, `getStackTrace()` on state
- **`isAnyActionCancelled` getter** - Check if any action was cancelled
- **`firstActionStackTrace` getter** - Get stack trace of first failed action
- **Await action completion** - Use `action.future` to wait for action to complete

### Performance Improvements
- **Cached stream** - Stream is now created once in `initState` instead of every `build()`

### Bug Fixes
- **Catches all error types** - Now catches `Object` (both `Exception` and `Error`)
- **Post actions cleared on error** - `_postDataActions` cleared when action fails

## 1.6.0 (2025-02-06)

### New Features
- Added `DataFlow.reset()` method for full reinitialization (useful for logout scenarios)
- Added `DataFlow.removeMiddleware()` method to remove specific middleware
- Added `DataFlow.clearMiddlewares()` method to clear all middlewares
- Added `DataFlow.isDisposed` getter to check if DataFlow has been disposed
- Added `context.tryDataSync<T>()` method that returns null instead of throwing

### Improvements
- Better error messages when `DataSync.actions` is null
- Better error messages when `context.dataSync()` has no ancestor
- Controller is now recoverable after `dispose()` using `reset()`

## 1.5.1 (2025-02-06)

### Documentation
- Added examples for `resetStatus()`, `resetAllStatuses()`, and `getError()` methods
- Added example for dynamic actions with `didUpdateWidget`
- Updated package version in README

## 1.5.0 (2025-02-06)

### Bug Fixes
- Fixed null error in DataSync when multiple actions are triggered and one fails while another succeeds
- Error handling now properly tracks errors per action type instead of relying on stream snapshot

### New Features
- Added `resetStatus(Type actionType)` method to reset a specific action's status to idle
- Added `resetAllStatuses()` method to reset all action statuses to idle
- Added `getError(Type actionType)` method to get the error for a specific action type
- Added `didUpdateWidget` handler to DataSync - now properly re-subscribes when actions change
- Added `didUpdateWidget` handler to DataSyncNotifier - now properly re-subscribes when actions change

### Internal Improvements
- Errors are now stored in a separate `_allActionsErrors` map for reliable error retrieval
- Added `firstActionError` getter that returns the error from the first failed action

## 1.4.0 (2024-10-14)

- DataSyncWidget improved with more simplicity and better error control
- Bug Fixes

## 1.2.2 (2024-08-14)

### Breaking change (Data Sync builder now gives hasData in place of statues)

- context.dataSync() gives access to action bases status
- context.getStore() gives access to store
- DataFlowException added to handle data flow errors
- Bug Fixes

## 1.1.1 (2024-08-05)

- Added disableErrorBuilder and disableLoadingBuilder props
- actionNotifier now gives an action
- Bug Fixes

## 1.0.3 (2024-07-23)

- Bug Fixes

## 1.0.2 (2024-07-08)

- First Release
