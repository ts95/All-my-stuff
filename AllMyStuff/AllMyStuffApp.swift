//
//  AllMyStuffApp.swift
//  AllMyStuff

import SwiftUI
import SwiftData

@main
struct AllMyStuffApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.tonisucic.All-my-stuff")
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    init() {
        prepareDependencies(modelContainer: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ItemSplitView()
                .modelContainer(sharedModelContainer)
        }
    }
}
