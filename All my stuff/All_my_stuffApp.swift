//
//  All_my_stuffApp.swift
//  All my stuff

import SwiftUI
import SwiftData

@main
struct All_my_stuffApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
