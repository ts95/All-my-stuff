# All My Stuff

A personal inventory app for tracking what you own, where it's stored, and what it's worth — synced across all your Apple devices via iCloud.

## Why

I have lots of stuff — sometimes I forget what I have, where things are, or what my items are worth. This app keeps it all in one place on iPhone, iPad, and Mac.

## Core Concepts

- **Items** — things you own (name, photo, notes, purchase price, estimated value, date purchased)
- **Categories** — group items by type (electronics, jewelry, collectibles, etc.)
- **Locations** — track where items are stored; an item can be associated with multiple locations

Each financial field (`purchasePrice`, `estimatedValue`) is an optional `Double?` — `nil` means unset.

## Tech Stack

- **SwiftUI** with `NavigationSplitView` for adaptive iOS/iPadOS/Mac layouts
- **SwiftData** for local persistence with many-to-many relationships between items, categories, and locations
- **iCloud CloudKit** sync via SwiftData's built-in support — same data across all devices signed into the same Apple ID
- **swift-dependencies** for dependency injection — `@Observable` stores with `.liveValue`, `.previewValue`, `.testValue`
- **Swift Testing** framework (`@Test`, `#expect`) for unit and integration tests

## Architecture

Model-View pattern with `@Observable` stores injected via `@Dependency(\.)`. Views never import SwiftData directly — all data access goes through stores (`ItemStore`, `CategoryStore`, `LocationStore`) that conform to `EntityStoreProtocol`. The stores wrap `ModelContext` in live mode, hold in-memory sample data in preview mode, and provide empty state for tests.

## About This Project

This app is an experiment in vibe coding — how well does a small agentic model running on a powerful consumer GPU hold up when building a real application?

The entire codebase is being developed conversationally with **Qwen 3.6-27B** (dense), quantized to Q4_K_M (4-bit K-quantization, medium quality) in GGUF format, running on an RTX 4090 via Ollama. No larger models were used — if this app works well, it's a testament to what smaller local models can achieve in agentic coding workflows.

Development is powered by **OpenCode** with the **superpowers** plugin, alongside a separate set of Swift dev skills for SwiftUI patterns, navigation, layout components, SwiftData, concurrency, testing, and architecture.

## Project Structure

```
AllMyStuff/
├── Models/
│   ├── Item.swift            // Core inventory item model
│   ├── ItemCategory.swift    // Item category
│   └── ItemLocation.swift    // Storage location
├── Views/
│   ├── ItemSplitView.swift         // Split-view coordinator with sheet management
│   ├── ItemListView.swift          // Main list with search, filter by category/location
│   ├── ItemProfileView.swift       // Read-only detail/profile view for a single item
│   ├── ItemFormSheet.swift         // Sheet for creating/editing items
│   ├── CategoryPickerView.swift    // Embedded section for managing item categories
│   └── LocationPickerView.swift    // Embedded section for managing item locations
├── Services/
│   ├── AssetStorage.swift          // Photo/image handling
│   ├── EntityStoreProtocol.swift   // Generic CRUD protocol for all stores
│   ├── ItemStore.swift             // @Observable store for Item CRUD + grouping
│   ├── CategoryStore.swift         // @Observable store for ItemCategory CRUD
│   ├── LocationStore.swift         // @Observable store for ItemLocation CRUD
│   └── DependencyRegistration.swift // DependencyKey conformance + prepareDependencies
├── AllMyStuffTests/
│   ├── Models/DataModelTests.swift           // SwiftData model tests
│   ├── Services/StoreTests.swift             // Store CRUD + query tests
│   ├── Integration/ItemCRUDTests.swift       // Direct SwiftData CRUD integration
│   ├── Integration/ItemFormSheetTests.swift  // Form sheet model integration
│   ├── Integration/ItemProfileTests.swift    // Profile view integration
│   └── Views/ProfileViewSmokeTests.swift     // UI smoke tests
├── AllMyStuffUITests/                    // XCUITest launch tests
└── AllMyStuffApp.swift                   // ModelContainer + root view
```