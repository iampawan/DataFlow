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
