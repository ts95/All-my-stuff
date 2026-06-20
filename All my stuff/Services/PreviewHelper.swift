import SwiftData
import Foundation
import SwiftUI

@MainActor
func makePreviewContainer() -> (container: ModelContainer, context: ModelContext) {
    let schema = Schema([Item.self, Category.self, Location.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)
    return (container, context)
}

@MainActor
func mockItem(name: String, datePurchased: Date?) -> Item {
    let item = Item(name: name, datePurchased: datePurchased)
    item.notes = "Mock \(name)"
    return item
}

@MainActor
func seedListPreview() -> ModelContainer {
    let (container, context) = makePreviewContainer()

    let laptop = mockItem(name: "Laptop", datePurchased: Date())
    let headphones = mockItem(name: "Headphones", datePurchased: nil)
    let cat = Category(name: "Electronics")
    let loc = Location(name: "Desk")

    context.insert(laptop)
    context.insert(headphones)
    context.insert(cat)
    context.insert(loc)
    laptop.categories.append(cat)
    laptop.locations.append(loc)

    return container
}

@MainActor
func makeItemDetailPreview() -> some View {
    let (container, context) = makePreviewContainer()

    let item = Item(name: "Laptop", datePurchased: Date())
    item.notes = "2024 MacBook Pro"
    let cat = Category(name: "Electronics")
    let loc = Location(name: "Desk")

    context.insert(item)
    context.insert(cat)
    context.insert(loc)
    item.categories.append(cat)
    item.locations.append(loc)

    return NavigationStack {
        ItemDetailView(item: item)
    }
    .modelContainer(container)
}

@MainActor
func makeContentViewPreview() -> some View {
    ContentView()
        .modelContainer(seedListPreview())
}
