# All My Stuff — Initial Design

**Date:** 2026-06-20  
**Status:** Approved  

## Problem

The owner has many possessions but loses track of:
1. What items they own
2. Where each item is stored
3. What each item is worth

There needs to be a single personal inventory app that works across iPhone, iPad, and Mac.

## Solution

A SwiftUI + SwiftData iOS app called "All My Stuff" that lets the owner:
- Create items with name, photo, description, purchase price, estimated value, and date purchased
- Associate each item with multiple categories and multiple locations (many-to-many)
- Filter and group items by category or location
- Navigate with adaptive split-view layouts
- Sync everything across devices via iCloud CloudKit — same data on iPhone, iPad, and Mac signed into the same Apple ID

## Data Model

### Models

| Model | Fields | Relationships |
|-------|--------|---------------|
| `Item` | name, photo (`Data?`), description, purchasePrice (`PriceState?`), estimatedValue (`PriceState?`), datePurchased (`Date?`) | many-to-many with `Category`, many-to-many with `Location` |
| `Category` | name | many-to-many with `Item` |
| `Location` | name | many-to-many with `Item` |

### PriceState Enum

```swift
enum PriceState: Codable, @unchecked Sendable {
    case unknown
    case confirmed(Double)
    case assumed(Double)
}
```

Financial fields are optional. Nil means no value set; the enum distinguishes between unknown, known, and assumed prices.

### Constraints

- Categories and locations are **optional** per item (items can exist without either)
- Categories and locations are **editable** after creation

## Architecture

### Project Structure

```
All my stuff/
├── Models/
│   ├── Item.swift          // Core inventory item model
│   ├── Category.swift      // Item category
│   ├── Location.swift      // Storage location
│   └── PriceState.swift    // Enum: .confirmed, .assumed, .unknown
├── Views/
│   ├── ContentView.swift           // Split-view coordinator
│   ├── ItemListView.swift          // Main list with search & grouping
│   ├── ItemDetailView.swift        // Detail/edit form
│   ├── CategoryPickerView.swift    // Add/remove categories
│   └── LocationPickerView.swift    // Add/remove locations
├── Services/
│   └── AssetStorage.swift  // Photo/image handling
└── All_my_stuffApp.swift   // ModelContainer + root view
```

### Layout Strategy

- `NavigationSplitView` with `.balanced` style provides:
  - iPhone: single-column navigation stack (list → detail)
  - iPad/Mac: side-by-side master-detail layout
- No device-specific code branches; rely on SwiftUI adaptive containers

## iCloud / CloudKit Sync

SwiftData has built-in CloudKit integration via the `@ModelIsolated` exclusion and `.setCloudKitEnabled(true)` on the model container. All three models (`Item`, `Category`, `Location`) sync automatically across devices signed into the same Apple ID. No manual sync logic is needed — SwiftData handles conflict resolution, delta sync, and offline support out of the box.

**Configuration:**
- Enable the iCloud capability in Xcode (add CloudKit container to entitlements)
- Pass `.setCloudKitEnabled(true)` to `ModelConfiguration` when creating the `ModelContainer`
- All `@Query` properties see synced data automatically; no polling or manual fetch required

**Notes:**
- Photos stored as `Data` attributes sync through CloudKit records (no CloudKit Assets needed — keeping it simple for a personal app)
- No authentication UI is required; iCloud auth is handled by the system settings

## Key Decisions

1. **SwiftData over CoreData** — simpler, less boilerplate for a personal app
2. **Many-to-many relationships** — items can belong to multiple categories and locations without history tracking
3. **No external dependencies** — only Swift standard libraries, SwiftUI, SwiftData, and CloudKit
4. **Photo storage in SwiftData** — images stored as `Data` attributes rather than file references, kept simple for CloudKit sync
5. **iCloud via built-in SwiftData CloudKit support** — automatic cross-device sync with no manual conflict resolution or delta fetch logic required
