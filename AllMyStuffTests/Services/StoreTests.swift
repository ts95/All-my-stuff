import Testing
@testable import All_my_stuff

@Suite("ItemStore Tests")
struct ItemStoreTests {

    @Test func previewStoreHasSampleData() throws {
        let store = ItemStore.preview()
        #expect(store.items.count == 3)
        #expect(store.items[0].name == "Laptop")
        #expect(store.items[1].name == "Headphones")
        #expect(store.items[2].name == "Phone")
    }

    @Test func previewStoreInsertAddsItem() throws {
        let store = ItemStore.preview()
        let newItem = Item(name: "Tablet")
        try store.insert(newItem)
        #expect(store.items.count == 4)
    }

    @Test func previewStoreDeleteRemovesItem() throws {
        let store = ItemStore.preview()
        let itemToDelete = store.items[0]
        try store.delete(itemToDelete)
        #expect(store.items.count == 2)
        #expect(!store.items.contains { $0.name == "Laptop" })
    }

    @Test func previewStoreQueryFiltersCorrectly() throws {
        let store = ItemStore.preview()
        let results = try store.query { $0.name.contains("Laptop") }
        #expect(results.count == 1)
        #expect(results[0].name == "Laptop")
    }

    @Test func previewStoreQueryReturnsEmpty() throws {
        let store = ItemStore.preview()
        let results = try store.query { $0.name.contains("Nonexistent") }
        #expect(results.isEmpty)
    }

    @Test func testStoreIsEmpty() throws {
        let store = ItemStore.test()
        #expect(store.items.isEmpty)
    }

    @Test func previewStoreGroupedByCategory() throws {
        let store = ItemStore.preview()
        let grouped = store.grouped(by: \Item.categories)
        #expect(grouped.count > 0)
        #expect(grouped[0].group.name != "")
    }

    @Test func previewStoreGroupedByLocation() throws {
        let store = ItemStore.preview()
        let grouped = store.groupedByLocation()
        #expect(grouped.count > 0)
    }
}

@Suite("CategoryStore Tests")
struct CategoryStoreTests {

    @Test func previewStoreHasSampleCategories() throws {
        let store = CategoryStore.preview()
        #expect(store.items.count == 3)
    }

    @Test func testStoreIsEmpty() throws {
        let store = CategoryStore.test()
        #expect(store.items.isEmpty)
    }
}

@Suite("LocationStore Tests")
struct LocationStoreTests {

    @Test func previewStoreHasSampleLocations() throws {
        let store = LocationStore.preview()
        #expect(store.items.count == 3)
    }

    @Test func testStoreIsEmpty() throws {
        let store = LocationStore.test()
        #expect(store.items.isEmpty)
    }
}
