# All My Stuff

A personal inventory app for tracking what you own, where it's stored, and what it's worth — synced across all your Apple devices via iCloud.

## Why

I have lots of stuff — sometimes I forget what I have, where things are, or what my items are worth. This app keeps it all in one place on iPhone, iPad, and Mac.

## Core Concepts

- **Items** — things you own (name, photo, description, purchase price, estimated value, date purchased)
- **Categories** — group items by type (electronics, jewelry, collectibles, etc.)
- **Locations** — track where items are stored; an item can be associated with multiple locations

Each financial field (`purchasePrice`, `estimatedValue`) supports three states: confirmed, assumed, or unknown.

## Tech Stack

- **SwiftUI** with `NavigationSplitView` for adaptive iOS/iPadOS/Mac layouts
- **SwiftData** for local persistence with many-to-many relationships between items, categories, and locations
- **iCloud CloudKit** sync via SwiftData's built-in support — same data across all devices signed into the same Apple ID
- No external dependencies

## About This Project

This app is an experiment in vibe coding — how well does a small agentic model running on a powerful consumer GPU hold up when building a real application?

The entire codebase is being developed conversationally with **Qwen 3.6-27B** (dense), quantized to Q4\_K\_M (4-bit K-quantization, medium quality) in GGUF format, running on an RTX 4090 via Ollama. No larger models were used — if this app works well, it's a testament to what smaller local models can achieve in agentic coding workflows.

Development is powered by **OpenCode** with the **superpowers** plugin, leveraging a suite of Swift-development skills for SwiftUI patterns, navigation, layout components, SwiftData, concurrency, testing, and architecture.

## Project Structure

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
