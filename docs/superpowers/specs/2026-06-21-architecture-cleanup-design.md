# Architecture Cleanup

**Date:** 2026-06-21  
**Status:** Approved

## Context

The app uses MV with `@Observable` stores and `swift-dependencies` DI. The architecture is sound for the app's complexity, but several issues have accumulated: layer violations, dead code, unsafe concurrency annotations, unimplemented UI states, and legacy tests that bypass the store abstraction.

## Changes

### 1. Store Concurrency Hardening

**Files:** `ItemStore.swift`, `CategoryStore.swift`, `LocationStore.swift`, `DependencyRegistration.swift`

- Replace `@unchecked Sendable` on all three stores with `@MainActor` isolation
- All store access is already on the main thread; this makes the conformance sound instead of suppressed
- Replace `AppContainer.shared!` force-unwrap in `liveValue` with `preconditionFailure` for a clear crash message if accessed before initialization

### 2. Move `ImageProcessingOverlay` to Views

**Files:** `Services/AssetStorage.swift` → `Services/ImageHelper.swift`, new `Views/ImageProcessingOverlay.swift`

- Rename `AssetStorage` to `ImageHelper` (it's a utility, not a storage)
- Extract `ImageProcessingOverlay` (a SwiftUI `View`) from `ImageHelper.swift` into `Views/ImageProcessingOverlay.swift`
- Update all imports and references

### 3. Extract Grouping Logic from `ItemStore`

**Files:** `Services/ItemStore.swift`, `Views/ItemListView.swift`

- Remove `grouped(by:)` and `groupedByLocation()` from `ItemStore`
- Add equivalent computed properties on `ItemListView` that compute grouped data from `itemStore.items`
- Keeps presentation concerns in the view layer

### 4. Implement Loading States and Error UI

**Files:** `Views/ItemListView.swift`, `Views/ItemFormSheet.swift`

- `ItemListView`: Add `.overlay` with `ProgressView` while `isLoading` is true; add `.alert` for `error` state
- `ItemFormSheet`: Add `.overlay` with `ProgressView` during save operations; add `.alert` for save errors
- Error state clears on retry or dismiss

### 5. Remove Redundant `.modelContainer()` Wiring

**Files:** `AllMyStuffApp.swift`

- Remove `.modelContainer(sharedModelContainer)` modifier from `ItemSplitView`
- All data access goes through stores via `@Dependency`; the environment container is unused dead code

### 6. Improve Price Binding Sync

**Files:** `Views/ItemFormSheet.swift`

- Add `.onDisappear` handler to sync `purchasePriceText` and `estimatedValueText` to the model
- Existing `.onSubmit` sync remains; `.onDisappear` catches cases where user edits but doesn't submit

### 7. Migrate Legacy Tests to Store Abstraction

**Files:** Tests (existing test files that currently use raw SwiftData)

- Rewrite tests to exercise stores via `test()` or in-memory mode instead of direct `ModelContext`
- Validates the store layer actually works as an abstraction
