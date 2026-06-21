import SwiftData
import Foundation
import SwiftUI

@MainActor
func makePreviewContainer() -> (container: ModelContainer, context: ModelContext) {
    let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
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
    let cat = ItemCategory(name: "Electronics")
    let loc = ItemLocation(name: "Desk")

    laptop.categories = [cat]
    laptop.locations = [loc]
    context.insert(laptop)
    context.insert(headphones)
    context.insert(cat)
    context.insert(loc)

    return container
}

@MainActor
func makeProfilePreview() -> some View {
    let container = seedListPreview()

    let fd = FetchDescriptor<Item>()
    let ctx = ModelContext(container)
    let item = (try? ctx.fetch(fd))?.first

    return NavigationStack {
        if let item {
            ItemProfileView(
                item: item,
                onEdit: {},
                onDelete: {}
            )
        } else {
            Text("No items available")
        }
    }
    .modelContainer(container)
}

@MainActor
func makeContentViewPreview() -> some View {
    ContentView()
        .modelContainer(seedListPreview())
}
