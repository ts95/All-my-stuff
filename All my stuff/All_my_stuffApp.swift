//
//  All_my_stuffApp.swift
//  All my stuff

import SwiftUI
import SwiftData

@main
struct All_my_stuffApp: App {
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
